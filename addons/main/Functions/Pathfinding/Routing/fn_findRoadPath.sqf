/*
 * Function: FLO_fnc_findRoadPath
 * Author: Frontline Operations Development Group
 * Description:
 * Resolves a waypoint array between two positions using cached water-aware
 * routing. Straight land routes resolve directly; only water crossings receive
 * coarse detour pivots.
 *
 * Arguments:
 * 0: Start Position <ARRAY>
 * 1: End Position <ARRAY>
 * 2: Callback <CODE> - Receives [_resolved, _posArray, _args]
 * 3: (Optional) Additional arguments to pass to callback <ARRAY> (Default: [])
 * 4: (Optional) Include Trails <BOOL> (Default: false)
 * 5: (Optional) Source Tag <STRING> (Default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_startPos, _endPos, _callback, [], false] call FLO_fnc_findRoadPath;
 */

params [
    ["_startPos", [0,0], [[]], [2,3]],
    ["_endPos", [0,0], [[]], [2,3]],
    ["_code", {}, [{}]],
    ["_args", [], [[]]],
    ["_trails", false, [true]],
    ["_sourceTag", "", [""]]
];

if (count _startPos > 2) then { _startPos resize 2; };
if (count _endPos > 2) then { _endPos resize 2; };

if (_sourceTag == "") then {
    _sourceTag = "UNSPECIFIED";
};

private _attemptsBySource = FLO_PF_SourceStats get "attempts";
_attemptsBySource set [_sourceTag, (_attemptsBySource getOrDefault [_sourceTag, 0]) + 1];

private _now = diag_tickTime;
if (_now >= FLO_PF_RequestNextPruneAt) then {
    {
        private _cacheEntry = FLO_PF_RequestCache get _x;
        if ((_cacheEntry select 1) <= _now) then {
            FLO_PF_RequestCache deleteAt _x;
        };
    } forEach (keys FLO_PF_RequestCache);

    private _cacheKeys = keys FLO_PF_RequestCache;
    private _cacheCount = count _cacheKeys;
    if (_cacheCount > FLO_PF_RequestCacheMax) then {
        private _expiryList = [];
        {
            _expiryList pushBack [((FLO_PF_RequestCache get _x) select 1), _x];
        } forEach _cacheKeys;
        _expiryList sort true;

        private _dropCount = _cacheCount - FLO_PF_RequestCacheMax;
        for "_i" from 0 to (_dropCount - 1) do {
            FLO_PF_RequestCache deleteAt ((_expiryList select _i) select 1);
        };
    };

    FLO_PF_RequestNextPruneAt = _now + FLO_PF_RequestPruneInterval;
};

private _dist = _startPos distance2D _endPos;
private _routingModeKey = "GROUND";
if (_trails) then {
    _routingModeKey = "TRAILS";
} else {
    if (_sourceTag == "LOGI_REINF") then {
        _routingModeKey = "LOGI_REINF";
    };
};

private _cellSize = FLO_PF_RequestCellSize;
if (_dist > 6000) then {
    _cellSize = _cellSize * 4;
} else {
    if (_dist > 3000) then {
        _cellSize = _cellSize * 3;
    } else {
        if (_dist > 1200) then {
            _cellSize = _cellSize * 2;
        };
    };
};

if (_sourceTag == "LOGI_REINF") then {
    // Strategic reinforcement transit does not need near-unique cache keys.
    // Coarser buckets increase cache/pending reuse across repeated supply hops.
    if (_dist > 5000) then {
        if (_cellSize < 720) then { _cellSize = 720; };
    } else {
        if (_dist > 2500) then {
            if (_cellSize < 540) then { _cellSize = 540; };
        } else {
            if (_cellSize < 360) then { _cellSize = 360; };
        };
    };
};

private _cellKey = {
    params ["_pos", "_size"];
    format ["%1_%2", round ((_pos select 0) / _size), round ((_pos select 1) / _size)]
};

private _sKey = format ["%1@%2", [_startPos, _cellSize] call _cellKey, _cellSize];
private _eKey = format ["%1@%2", [_endPos, _cellSize] call _cellKey, _cellSize];
private _routeKey = format ["%1>%2|%3", _sKey, _eKey, _routingModeKey];
private _reverseRouteKey = format ["%1>%2|%3", _eKey, _sKey, _routingModeKey];

if (_routeKey in FLO_PF_RequestCache) then {
    private _cached = FLO_PF_RequestCache get _routeKey;
    _cached params ["_path", "_expiresAt"];
    if (_now < _expiresAt) exitWith {
        private _cacheHitsBySource = FLO_PF_SourceStats get "cacheHit";
        _cacheHitsBySource set [_sourceTag, (_cacheHitsBySource getOrDefault [_sourceTag, 0]) + 1];
        FLO_PF_Perf set ["cacheHits", (FLO_PF_Perf get "cacheHits") + 1];
        [true, +_path, _args] call _code;
    };
    FLO_PF_RequestCache deleteAt _routeKey;
};

if (_reverseRouteKey in FLO_PF_RequestCache) then {
    private _cachedReverse = FLO_PF_RequestCache get _reverseRouteKey;
    _cachedReverse params ["_path", "_expiresAt"];
    if (_now < _expiresAt) exitWith {
        private _cacheHitsBySource = FLO_PF_SourceStats get "cacheHit";
        _cacheHitsBySource set [_sourceTag, (_cacheHitsBySource getOrDefault [_sourceTag, 0]) + 1];
        FLO_PF_Perf set ["cacheHits", (FLO_PF_Perf get "cacheHits") + 1];
        private _reversedPath = +_path;
        reverse _reversedPath;
        [true, _reversedPath, _args] call _code;
    };
    FLO_PF_RequestCache deleteAt _reverseRouteKey;
};

private _newSearchBySource = FLO_PF_SourceStats get "newSearch";
_newSearchBySource set [_sourceTag, (_newSearchBySource getOrDefault [_sourceTag, 0]) + 1];
private _sampleStep = FLO_PF_WaterSampleStep;
if (_trails) then {
    _sampleStep = FLO_PF_WaterSampleStepTrails;
} else {
    if (_sourceTag == "LOGI_REINF") then {
        _sampleStep = FLO_PF_WaterSampleStepLogi;
    };
};

private _tResolve = diag_tickTime;
private _routeResult = [_startPos, _endPos, _sampleStep, 0] call FLO_fnc_buildWaterAwarePath;
_routeResult params ["_resolvedPath", "_sampleChecks", "_usedFallback"];
if (_resolvedPath isEqualTo []) then {
    _resolvedPath = [+_endPos];
    _usedFallback = true;
};
private _resolvedMs = (diag_tickTime - _tResolve) * 1000;

FLO_PF_RequestCache set [_routeKey, [+_resolvedPath, diag_tickTime + FLO_PF_RequestTTL]];

private _metrics = FLO_PF_Scheduler call ["GetMetrics"];
_metrics set ["submitted", (_metrics get "submitted") + 1];
_metrics set ["nodeSteps", (_metrics get "nodeSteps") + _sampleChecks];
if (_usedFallback) then {
    _metrics set ["completedPartial", (_metrics get "completedPartial") + 1];
} else {
    _metrics set ["completedSuccess", (_metrics get "completedSuccess") + 1];
};
_metrics set ["resolvedCount", (_metrics get "resolvedCount") + 1];
_metrics set ["resolvedNodeStepsLast", _sampleChecks];
_metrics set ["resolvedNodeStepsTotal", (_metrics get "resolvedNodeStepsTotal") + _sampleChecks];
_metrics set ["resolvedMsLast", _resolvedMs];
_metrics set ["resolvedMsTotal", (_metrics get "resolvedMsTotal") + _resolvedMs];
_metrics set ["emittedWaypointsLast", count _resolvedPath];
_metrics set ["emittedWaypointsTotal", (_metrics get "emittedWaypointsTotal") + (count _resolvedPath)];
if (_sampleChecks > (_metrics get "resolvedNodeStepsPeak")) then {
    _metrics set ["resolvedNodeStepsPeak", _sampleChecks];
};
if (_resolvedMs > (_metrics get "resolvedMsPeak")) then {
    _metrics set ["resolvedMsPeak", _resolvedMs];
};
if ((count _resolvedPath) > (_metrics get "emittedWaypointsPeak")) then {
    _metrics set ["emittedWaypointsPeak", count _resolvedPath];
};

private _completedSuccessBySource = FLO_PF_SourceStats get "completedSuccess";
private _completedPartialBySource = FLO_PF_SourceStats get "completedPartial";
private _resolvedCountBySource = FLO_PF_SourceStats get "resolvedCount";
private _resolvedNodeStepsLastBySource = FLO_PF_SourceStats get "resolvedNodeStepsLast";
private _resolvedNodeStepsTotalBySource = FLO_PF_SourceStats get "resolvedNodeStepsTotal";
private _resolvedNodeStepsPeakBySource = FLO_PF_SourceStats get "resolvedNodeStepsPeak";
private _resolvedMsLastBySource = FLO_PF_SourceStats get "resolvedMsLast";
private _resolvedMsTotalBySource = FLO_PF_SourceStats get "resolvedMsTotal";
private _resolvedMsPeakBySource = FLO_PF_SourceStats get "resolvedMsPeak";
private _emittedLastBySource = FLO_PF_SourceStats get "emittedWaypointsLast";
private _emittedTotalBySource = FLO_PF_SourceStats get "emittedWaypointsTotal";
private _emittedPeakBySource = FLO_PF_SourceStats get "emittedWaypointsPeak";

if (_usedFallback) then {
    _completedPartialBySource set [_sourceTag, (_completedPartialBySource getOrDefault [_sourceTag, 0]) + 1];
} else {
    _completedSuccessBySource set [_sourceTag, (_completedSuccessBySource getOrDefault [_sourceTag, 0]) + 1];
};
_resolvedCountBySource set [_sourceTag, (_resolvedCountBySource getOrDefault [_sourceTag, 0]) + 1];
_resolvedNodeStepsLastBySource set [_sourceTag, _sampleChecks];
_resolvedNodeStepsTotalBySource set [_sourceTag, (_resolvedNodeStepsTotalBySource getOrDefault [_sourceTag, 0]) + _sampleChecks];
if (_sampleChecks > (_resolvedNodeStepsPeakBySource getOrDefault [_sourceTag, 0])) then {
    _resolvedNodeStepsPeakBySource set [_sourceTag, _sampleChecks];
};
_resolvedMsLastBySource set [_sourceTag, _resolvedMs];
_resolvedMsTotalBySource set [_sourceTag, (_resolvedMsTotalBySource getOrDefault [_sourceTag, 0]) + _resolvedMs];
if (_resolvedMs > (_resolvedMsPeakBySource getOrDefault [_sourceTag, 0])) then {
    _resolvedMsPeakBySource set [_sourceTag, _resolvedMs];
};
_emittedLastBySource set [_sourceTag, count _resolvedPath];
_emittedTotalBySource set [_sourceTag, (_emittedTotalBySource getOrDefault [_sourceTag, 0]) + (count _resolvedPath)];
if ((count _resolvedPath) > (_emittedPeakBySource getOrDefault [_sourceTag, 0])) then {
    _emittedPeakBySource set [_sourceTag, count _resolvedPath];
};

private _perf = FLO_PF_Perf;
if (_resolvedMs >= (_perf get "slowSearchThresholdMs") && {diag_tickTime >= (_perf get "nextSlowSearchLogAt")}) then {
    _perf set ["nextSlowSearchLogAt", diag_tickTime + (_perf get "logCooldownSec")];
    diag_log format [
        "[FLO][PERF] Water route source=%1 status=%2 distance=%3 m waypoints=%4 samples=%5 resolved in %6 ms",
        _sourceTag,
        ["SUCCESS", "PARTIAL"] select (_usedFallback),
        _dist,
        count _resolvedPath,
        _sampleChecks,
        _resolvedMs
    ];
};

[!_usedFallback, +_resolvedPath, _args] call _code;
