/*
 * Function: FLO_fnc_findRoadPath
 * Author: Frontline Operations Development Group
 * Description:
 * Resolves a waypoint array between two positions using the shared road graph.
 * The scheduler owns execution; this wrapper owns request coalescing and cache reuse.
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

private _cellKey = {
    params ["_pos", "_size"];
    format ["%1_%2", round ((_pos select 0) / _size), round ((_pos select 1) / _size)]
};

private _sKey = format ["%1@%2", [_startPos, _cellSize] call _cellKey, _cellSize];
private _eKey = format ["%1@%2", [_endPos, _cellSize] call _cellKey, _cellSize];
private _routeKey = format ["%1>%2|%3", _sKey, _eKey, _trails];
private _reverseRouteKey = format ["%1>%2|%3", _eKey, _sKey, _trails];

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

if (_routeKey in FLO_PF_RequestPending) exitWith {
    private _pendingJoinBySource = FLO_PF_SourceStats get "pendingJoin";
    _pendingJoinBySource set [_sourceTag, (_pendingJoinBySource getOrDefault [_sourceTag, 0]) + 1];
    private _waiters = FLO_PF_RequestPending get _routeKey;
    _waiters pushBack [_code, _args];
    FLO_PF_RequestPending set [_routeKey, _waiters];
};

if (_reverseRouteKey in FLO_PF_RequestPending) exitWith {
    private _pendingJoinBySource = FLO_PF_SourceStats get "pendingJoin";
    _pendingJoinBySource set [_sourceTag, (_pendingJoinBySource getOrDefault [_sourceTag, 0]) + 1];
    private _waiters = FLO_PF_RequestPending get _reverseRouteKey;
    private _reverseWaiter = {
        params ["_resolved", "_posArray", "_waiterArgs"];
        _waiterArgs params ["_codeFn", "_codeArgs"];

        private _reversedPath = +_posArray;
        reverse _reversedPath;
        [_resolved, _reversedPath, _codeArgs] call _codeFn;
    };
    _waiters pushBack [_reverseWaiter, [_code, _args]];
    FLO_PF_RequestPending set [_reverseRouteKey, _waiters];
};

FLO_PF_RequestPending set [_routeKey, [[_code, _args]]];

private _dispatch = {
    params ["_resolved", "_posArray", "_cbArgs"];
    _cbArgs params ["_key"];

    FLO_PF_RequestCache set [_key, [+_posArray, diag_tickTime + FLO_PF_RequestTTL]];

    private _waiters = FLO_PF_RequestPending get _key;
    FLO_PF_RequestPending deleteAt _key;

    {
        _x params ["_cb", "_userArgs"];
        [_resolved, +_posArray, _userArgs] call _cb;
    } forEach _waiters;
};

private _search = createHashMapObject [XPS_PF_typ_RoadGraphSearch, [FLO_PF_RoadGraph, _startPos, _endPos]];
private _doctrine = FLO_PF_RoadDoctrine_V;
private _doctrineName = "VEHICLE";
if (_trails) then {
    _doctrine = FLO_PF_RoadDoctrine_M;
    _doctrineName = "MIXED";
} else {
    if (_sourceTag == "LOGI_REINF") then {
        _doctrine = FLO_PF_RoadDoctrine_V_Logi;
        _doctrineName = "LOGI_REINF";
    };
};
_search set ["Doctrine", _doctrine];
_search set ["Callback", _dispatch];
_search set ["CallbackArgs", [_routeKey]];
_search set ["SubmittedAt", _now];
_search set ["SourceTag", _sourceTag];
_search set ["RouteKey", _routeKey];
_search set ["RequestDistance", _dist];
_search set ["NodeSteps", 0];
_search set ["DoctrineName", _doctrineName];
_search set ["RequestStartPos", +_startPos];
_search set ["RequestEndPos", +_endPos];
_search set ["RunawayLogNextNodeSteps", FLO_PF_Perf get "runawayNodeStepsThreshold"];

private _startNode = _search get "StartNode";
private _endNode = _search get "EndNode";
private _startNodePos = +(_startNode get "PosASL");
private _endNodePos = +(_endNode get "PosASL");

_search set ["StartNodeIndex", _startNode get "Index"];
_search set ["EndNodeIndex", _endNode get "Index"];
_search set ["StartNodeType", _startNode get "Type"];
_search set ["EndNodeType", _endNode get "Type"];
_search set ["StartNodePos", _startNodePos];
_search set ["EndNodePos", _endNodePos];
_search set ["StartSnapDistance", _startPos distance2D _startNodePos];
_search set ["EndSnapDistance", _endPos distance2D _endNodePos];

FLO_PF_Scheduler call ["AddItem", _search];

private _newSearchBySource = FLO_PF_SourceStats get "newSearch";
_newSearchBySource set [_sourceTag, (_newSearchBySource getOrDefault [_sourceTag, 0]) + 1];

private _inFlightBySource = FLO_PF_SourceStats get "inFlight";
private _newInFlight = (_inFlightBySource getOrDefault [_sourceTag, 0]) + 1;
_inFlightBySource set [_sourceTag, _newInFlight];

private _inFlightPeakBySource = FLO_PF_SourceStats get "inFlightPeak";
if (_newInFlight > (_inFlightPeakBySource getOrDefault [_sourceTag, 0])) then {
    _inFlightPeakBySource set [_sourceTag, _newInFlight];
};
