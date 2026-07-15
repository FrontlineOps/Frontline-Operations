/*
 * Function: FLO_fnc_findRoadPath
 * Description:
 *   Resolves a water-safe land path synchronously and returns [success, path].
 *   Returned paths exclude the supplied start and include the exact endpoint.
 */

params [
    ["_startPos", [0, 0], [[]], [2, 3]],
    ["_endPos", [0, 0], [[]], [2, 3]],
    ["_trails", false, [true]],
    ["_sourceTag", "", [""]]
];

_startPos = +_startPos;
_endPos = +_endPos;
if (count _startPos > 2) then { _startPos set [2, 0]; } else { _startPos pushBack 0; };
if (count _endPos > 2) then { _endPos set [2, 0]; } else { _endPos pushBack 0; };
if (_sourceTag == "") then { _sourceTag = "UNSPECIFIED"; };

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

private _routingModeKey = ["GROUND", "TRAILS"] select _trails;
if (!_trails && {_sourceTag == "LOGI_REINF"}) then {
    _routingModeKey = "LOGI_REINF";
};

private _routeKey = format ["%1>%2|%3", str _startPos, str _endPos, _routingModeKey];
private _reverseRouteKey = format ["%1>%2|%3", str _endPos, str _startPos, _routingModeKey];

private _cachedPath = [];
if (_routeKey in FLO_PF_RequestCache) then {
    private _cached = FLO_PF_RequestCache get _routeKey;
    _cached params ["_fullPath", "_expiresAt"];
    if (_now < _expiresAt
        && {count _fullPath >= 2}
        && {(_fullPath select 0) isEqualTo _startPos}
        && {(_fullPath select -1) isEqualTo _endPos}) then {
        _cachedPath = (+_fullPath) select [1];
    } else {
        FLO_PF_RequestCache deleteAt _routeKey;
    };
};

if (_cachedPath isNotEqualTo []) exitWith {
    private _cacheHitsBySource = FLO_PF_SourceStats get "cacheHit";
    _cacheHitsBySource set [_sourceTag, (_cacheHitsBySource getOrDefault [_sourceTag, 0]) + 1];
    FLO_PF_Perf set ["cacheHits", (FLO_PF_Perf get "cacheHits") + 1];
    [true, +_cachedPath]
};

if (_reverseRouteKey in FLO_PF_RequestCache) then {
    private _cachedReverse = FLO_PF_RequestCache get _reverseRouteKey;
    _cachedReverse params ["_fullReversePath", "_expiresAt"];
    if (_now < _expiresAt
        && {count _fullReversePath >= 2}
        && {(_fullReversePath select 0) isEqualTo _endPos}
        && {(_fullReversePath select -1) isEqualTo _startPos}) then {
        private _reversedFullPath = +_fullReversePath;
        reverse _reversedFullPath;
        _cachedPath = _reversedFullPath select [1];
    } else {
        FLO_PF_RequestCache deleteAt _reverseRouteKey;
    };
};

if (_cachedPath isNotEqualTo []) exitWith {
    private _cacheHitsBySource = FLO_PF_SourceStats get "cacheHit";
    _cacheHitsBySource set [_sourceTag, (_cacheHitsBySource getOrDefault [_sourceTag, 0]) + 1];
    FLO_PF_Perf set ["cacheHits", (FLO_PF_Perf get "cacheHits") + 1];
    [true, +_cachedPath]
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
private _resolvedPath = [];
private _sampleChecks = 0;
private _resolved = !(surfaceIsWater _startPos) && {!(surfaceIsWater _endPos)};

if (_resolved) then {
    private _routeResult = [_startPos, _endPos, _sampleStep, 0] call FLO_fnc_buildWaterAwarePath;
    _resolvedPath = _routeResult select 0;
    _sampleChecks = _routeResult select 1;
    _resolved = _resolvedPath isNotEqualTo [] && {!(_routeResult select 2)};
};

if (_resolved) then {
    private _validation = [_startPos, _resolvedPath, FLO_PF_WaterValidationStep] call FLO_fnc_validateWaterAwarePath;
    _sampleChecks = _sampleChecks + (_validation select 1);
    _resolved = _validation select 0;
};

if (!_resolved && {_sampleStep > FLO_PF_WaterValidationStep} && {!(surfaceIsWater _startPos)} && {!(surfaceIsWater _endPos)}) then {
    private _fineResult = [_startPos, _endPos, FLO_PF_WaterValidationStep, 0] call FLO_fnc_buildWaterAwarePath;
    _resolvedPath = _fineResult select 0;
    _sampleChecks = _sampleChecks + (_fineResult select 1);
    _resolved = _resolvedPath isNotEqualTo [] && {!(_fineResult select 2)};

    if (_resolved) then {
        private _fineValidation = [_startPos, _resolvedPath, FLO_PF_WaterValidationStep] call FLO_fnc_validateWaterAwarePath;
        _sampleChecks = _sampleChecks + (_fineValidation select 1);
        _resolved = _fineValidation select 0;
    };
};

if (!_resolved) then {
    _resolvedPath = [];
} else {
    private _fullPath = [+_startPos];
    _fullPath append _resolvedPath;
    FLO_PF_RequestCache set [_routeKey, [_fullPath, diag_tickTime + FLO_PF_RequestTTL]];
};

private _resolvedMs = (diag_tickTime - _tResolve) * 1000;
private _metrics = FLO_PF_Metrics;
_metrics set ["submitted", (_metrics get "submitted") + 1];
_metrics set ["nodeSteps", (_metrics get "nodeSteps") + _sampleChecks];
if (_resolved) then {
    _metrics set ["completedSuccess", (_metrics get "completedSuccess") + 1];
} else {
    _metrics set ["completedPartial", (_metrics get "completedPartial") + 1];
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

if (_resolved) then {
    _completedSuccessBySource set [_sourceTag, (_completedSuccessBySource getOrDefault [_sourceTag, 0]) + 1];
} else {
    _completedPartialBySource set [_sourceTag, (_completedPartialBySource getOrDefault [_sourceTag, 0]) + 1];
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
    ["PERF", 4, format [
        "Water route source=%1 status=%2 distance=%3m waypoints=%4 samples=%5 elapsedMs=%6",
        _sourceTag,
        ["NO_LAND_ROUTE", "SUCCESS"] select _resolved,
        _startPos distance2D _endPos,
        count _resolvedPath,
        _sampleChecks,
        _resolvedMs
    ]] call FLO_fnc_log;
};

[_resolved, +_resolvedPath]
