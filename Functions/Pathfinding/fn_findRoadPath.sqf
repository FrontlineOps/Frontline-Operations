/*
 * Function: FLO_fnc_findRoadpath
 * Author: Frontline Operations Development Group
 * Description:
 * Returns a series of waypoints roughly 1km apart along a set of roads given a start and end position
 *
 * Arguments:
 * 0: Start Postion <ARRAY>
 * 1: End Position <ARRAY> 
 * 2: Callback <CODE> - The code to execute once a path has been found - Arguments passed to callback are as follows:
   [StartPos, EndPos, IntermediatePositionsArray]     
 * 3: (Optional) Additional arguments to pass to callback <ARRAY> (Default: []) 
 * 4: (Optional) Include Trails <BOOL> (Default: False) - for Man units only - vehicles cannot traverse TRAILS
 * 5: (Optional) Source Tag <STRING> (Default: "") - pathfinding telemetry source

 *
 * Return Value:
 *  Nothing
 *
 * Example:
 * private _callback = compileFinal {
        params ["_status", "_posArray", "_args" ];

        // Use _args to pass things like group or unit

        {
            // create intermediate waypoints here
            // last pos will be passed in _endPos
        } foreach _posArray;
    };
 * [_startPos, _endPos, _callback, [], false] call FLO_fnc_findRoadPath;
 */

params [
    ["_startPos",[0,0],[[]],[2,3]],
    ["_endPos",[0,0],[[]],[2,3]],
    ["_code",{},[{}]],
    ["_args",[],[[]]],
    ["_trails",false,[true]],
    ["_sourceTag","",[""]]
];

if (count _startPos > 2) then { _startPos resize 2; };
if (count _endPos > 2) then { _endPos resize 2; };

if (_sourceTag == "") then {
    _sourceTag = "UNSPECIFIED";
};

if (isNil "FLO_PF_SourceStats") then {
    FLO_PF_SourceStats = createHashMapFromArray [
        ["attempts", createHashMap],
        ["newSearch", createHashMap],
        ["cacheHit", createHashMap],
        ["pendingJoin", createHashMap],
        ["rejected", createHashMap]
    ];
};

private _attemptsBySource = FLO_PF_SourceStats get "attempts";
_attemptsBySource set [_sourceTag, (_attemptsBySource getOrDefault [_sourceTag, 0]) + 1];

if (isNil "FLO_PF_RequestCache") then {
    FLO_PF_RequestCache = createHashMap;
};
if (isNil "FLO_PF_RequestPending") then {
    FLO_PF_RequestPending = createHashMap;
};
if (isNil "FLO_PF_RequestTTL_Success") then {
    FLO_PF_RequestTTL_Success = 300;
};
if (isNil "FLO_PF_RequestTTL_Fail") then {
    FLO_PF_RequestTTL_Fail = 90;
};
if (isNil "FLO_PF_RequestCellSize") then {
    FLO_PF_RequestCellSize = 90;
};
if (isNil "FLO_PF_RequestCacheMax") then {
    FLO_PF_RequestCacheMax = 3000;
};
if (isNil "FLO_PF_RequestPendingMax") then {
    FLO_PF_RequestPendingMax = 1800;
};
if (isNil "FLO_PF_RequestPruneInterval") then {
    FLO_PF_RequestPruneInterval = 15;
};
if (isNil "FLO_PF_RequestNextPruneAt") then {
    FLO_PF_RequestNextPruneAt = 0;
};
if (isNil "FLO_PF_QueueSoftCap") then {
    FLO_PF_QueueSoftCap = 1500;
};

private _now = diag_tickTime;
private _queueDepth = 0;
if (!isNil "FLO_PF_Scheduler") then {
    _queueDepth = (FLO_PF_Scheduler get "_queueObject") call ["Count"];
};
if (_now >= FLO_PF_RequestNextPruneAt) then {
    {
        private _cacheEntry = FLO_PF_RequestCache get _x;
        if ((_cacheEntry select 2) <= _now) then {
            FLO_PF_RequestCache deleteAt _x;
        };
    } forEach (keys FLO_PF_RequestCache);

    private _cacheKeys = keys FLO_PF_RequestCache;
    private _cacheCount = count _cacheKeys;
    if (_cacheCount > FLO_PF_RequestCacheMax) then {
        private _expiryList = [];
        {
            _expiryList pushBack [((FLO_PF_RequestCache get _x) select 2), _x];
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
if (_queueDepth > 1200) then {
    _cellSize = _cellSize * 2;
} else {
    if (_queueDepth > 700) then {
        _cellSize = _cellSize + FLO_PF_RequestCellSize;
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
    _cached params ["_status", "_path", "_expiresAt"];
    if (diag_tickTime < _expiresAt) exitWith {
        private _cacheHitsBySource = FLO_PF_SourceStats get "cacheHit";
        _cacheHitsBySource set [_sourceTag, (_cacheHitsBySource getOrDefault [_sourceTag, 0]) + 1];
        [_status, +_path, _args] call _code;
    };
    FLO_PF_RequestCache deleteAt _routeKey;
};

if (_reverseRouteKey in FLO_PF_RequestCache) then {
    private _cachedReverse = FLO_PF_RequestCache get _reverseRouteKey;
    _cachedReverse params ["_status", "_path", "_expiresAt"];
    if (diag_tickTime < _expiresAt) exitWith {
        private _cacheHitsBySource = FLO_PF_SourceStats get "cacheHit";
        _cacheHitsBySource set [_sourceTag, (_cacheHitsBySource getOrDefault [_sourceTag, 0]) + 1];
        if (_status && {count _path > 0}) then {
            private _reversedPath = +_path;
            reverse _reversedPath;
            [_status, _reversedPath, _args] call _code;
        } else {
            [_status, [], _args] call _code;
        };
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
        params ["_status", "_posArray", "_waiterArgs"];
        _waiterArgs params ["_codeFn", "_codeArgs"];
        if (_status && {count _posArray > 0}) then {
            private _reversedPath = +_posArray;
            reverse _reversedPath;
            [_status, _reversedPath, _codeArgs] call _codeFn;
        } else {
            [_status, [], _codeArgs] call _codeFn;
        };
    };
    _waiters pushBack [_reverseWaiter, [_code, _args]];
    FLO_PF_RequestPending set [_reverseRouteKey, _waiters];
};

if (_queueDepth >= FLO_PF_QueueSoftCap) exitWith {
    private _rejectedBySource = FLO_PF_SourceStats get "rejected";
    _rejectedBySource set [_sourceTag, (_rejectedBySource getOrDefault [_sourceTag, 0]) + 1];
    FLO_PF_RequestCache set [_routeKey, [false, [], _now + 20]];
    ["PATHFINDING", 3, format ["Queue soft cap hit (%1), rejecting route %2", _queueDepth, _routeKey]] call FLO_fnc_log;
    [false, [], _args] call _code;
};

if ((count (keys FLO_PF_RequestPending)) >= FLO_PF_RequestPendingMax) exitWith {
    private _rejectedBySource = FLO_PF_SourceStats get "rejected";
    _rejectedBySource set [_sourceTag, (_rejectedBySource getOrDefault [_sourceTag, 0]) + 1];
    ["PATHFINDING", 2, format ["Path request backlog overflow (%1), rejecting route %2", count (keys FLO_PF_RequestPending), _routeKey]] call FLO_fnc_log;
    FLO_PF_RequestCache set [_routeKey, [false, [], _now + 20]];
    [false, [], _args] call _code;
};

FLO_PF_RequestPending set [_routeKey, [[_code, _args]]];

private _dispatch = {
    params ["_status", "_posArray", "_cbArgs"];
    _cbArgs params ["_key", "_source"];

    private _resolved = if (_status && {_posArray isEqualType []}) then { +_posArray } else { [] };
    private _ttl = if (_status && {count _resolved > 0}) then { FLO_PF_RequestTTL_Success } else { FLO_PF_RequestTTL_Fail };
    FLO_PF_RequestCache set [_key, [_status, _resolved, diag_tickTime + _ttl]];

    private _waiters = FLO_PF_RequestPending get _key;
    FLO_PF_RequestPending deleteAt _key;
    if (isNil "_waiters") exitWith {};

    {
        _x params ["_cb", "_userArgs"];
        [_status, +_resolved, _userArgs] call _cb;
    } forEach _waiters;
};

private _search = createHashMapObject [XPS_PF_typ_RoadGraphSearch, [FLO_PF_RoadGraph, _startPos, _endPos]];
private _doctrine = FLO_PF_RoadDoctrine_V;
if (_trails) then { _doctrine = FLO_PF_RoadDoctrine_M; };
_search set ["Doctrine", _doctrine];
_search set ["Callback", _dispatch];
_search set ["CallbackArgs", [_routeKey, _sourceTag]];

private _budget = 350 + round (_dist * 0.2);
if (_dist > 4000) then {
    _budget = _budget + round ((_dist - 4000) * 0.15);
};
if (_trails) then { _budget = round (_budget * 1.2); };
if (_budget < 350) then { _budget = 350; };
if (_budget > 9000) then { _budget = 9000; };
_search set ["BudgetInitial", _budget];
_search set ["BudgetRemaining", _budget];

FLO_PF_Scheduler call ["AddItem", _search];
private _newSearchBySource = FLO_PF_SourceStats get "newSearch";
_newSearchBySource set [_sourceTag, (_newSearchBySource getOrDefault [_sourceTag, 0]) + 1];
