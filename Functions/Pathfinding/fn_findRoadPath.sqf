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
    ["_trails",false,[true]]
];

if (count _startPos > 2) then { _startPos resize 2; };
if (count _endPos > 2) then { _endPos resize 2; };

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
    FLO_PF_RequestCellSize = 60;
};

private _cellSize = FLO_PF_RequestCellSize;
private _cellKey = {
    params ["_pos", "_size"];
    format ["%1_%2", round ((_pos select 0) / _size), round ((_pos select 1) / _size)]
};

private _sKey = [_startPos, _cellSize] call _cellKey;
private _eKey = [_endPos, _cellSize] call _cellKey;
private _routeKey = format ["%1>%2|%3", _sKey, _eKey, _trails];
private _reverseRouteKey = format ["%1>%2|%3", _eKey, _sKey, _trails];

if (_routeKey in FLO_PF_RequestCache) then {
    private _cached = FLO_PF_RequestCache get _routeKey;
    _cached params ["_status", "_path", "_expiresAt"];
    if (diag_tickTime < _expiresAt) exitWith {
        [_status, +_path, _args] call _code;
    };
    FLO_PF_RequestCache deleteAt _routeKey;
};

if (_reverseRouteKey in FLO_PF_RequestCache) then {
    private _cachedReverse = FLO_PF_RequestCache get _reverseRouteKey;
    _cachedReverse params ["_status", "_path", "_expiresAt"];
    if (diag_tickTime < _expiresAt) exitWith {
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
    private _waiters = FLO_PF_RequestPending get _routeKey;
    _waiters pushBack [_code, _args];
    FLO_PF_RequestPending set [_routeKey, _waiters];
};

if (_reverseRouteKey in FLO_PF_RequestPending) exitWith {
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

FLO_PF_RequestPending set [_routeKey, [[_code, _args]]];

private _dispatch = {
    params ["_status", "_posArray", "_cbArgs"];
    _cbArgs params ["_key"];

    private _waiters = FLO_PF_RequestPending get _key;
    FLO_PF_RequestPending deleteAt _key;
    if (isNil "_waiters") exitWith {};

    private _resolved = if (_status && {_posArray isEqualType []}) then { +_posArray } else { [] };
    private _ttl = if (_status && {count _resolved > 0}) then { FLO_PF_RequestTTL_Success } else { FLO_PF_RequestTTL_Fail };
    FLO_PF_RequestCache set [_key, [_status, _resolved, diag_tickTime + _ttl]];

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
_search set ["CallbackArgs", [_routeKey]];

private _dist = _startPos distance2D _endPos;
private _budget = 800 + round (_dist * 0.35);
if (_trails) then { _budget = round (_budget * 1.25); };
if (_budget < 800) then { _budget = 800; };
if (_budget > 12000) then { _budget = 12000; };
_search set ["BudgetInitial", _budget];
_search set ["BudgetRemaining", _budget];

FLO_PF_Scheduler call ["AddItem", _search];
