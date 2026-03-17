/*
 * Function: FLO_fnc_findRoadPathSync
 * Author: Frontline Operations Development Group
 * Description:
 *   Compatibility wrapper for legacy sync call sites.
 *   It never blocks the scheduler thread; instead it returns a fast
 *   fallback path immediately and hydrates a short-lived cache
 *   asynchronously via FLO_fnc_findRoadPath.
 *
 * Arguments:
 *   0: Start position <ARRAY>
 *   1: End position <ARRAY>
 *   2: Include Trails <BOOL> (optional, default false)
 *
 * Returns:
 *   Array of positions representing the path
 *
 * Example:
 *   private _path = [_start,_end] call FLO_fnc_findRoadPathSync;
 */

params [
    ["_startPos", [0,0,0], [[]]],
    ["_endPos", [0,0,0], [[]]],
    ["_trails", false, [true]]
];

if (count _startPos > 2) then { _startPos resize 2; };
if (count _endPos > 2) then { _endPos resize 2; };

private _fallbackPos = [_endPos select 0, _endPos select 1, 0];
private _sKey = format ["%1_%2", round (_startPos select 0), round (_startPos select 1)];
private _eKey = format ["%1_%2", round (_endPos select 0), round (_endPos select 1)];
private _routeKey = format ["%1>%2|%3", _sKey, _eKey, _trails];

if (isNil "FLO_PF_SyncCache") then {
    FLO_PF_SyncCache = createHashMap;
};
if (isNil "FLO_PF_SyncPending") then {
    FLO_PF_SyncPending = createHashMap;
};
if (isNil "FLO_PF_SyncRetryAt") then {
    FLO_PF_SyncRetryAt = createHashMap;
};

if (_routeKey in FLO_PF_SyncCache) then {
    private _cachedEntry = FLO_PF_SyncCache get _routeKey;
    _cachedEntry params ["_cachedPath", "_expiresAt"];
    if (diag_tickTime < _expiresAt) exitWith { +_cachedPath };
    FLO_PF_SyncCache deleteAt _routeKey;
};

private _retryAt = 0;
if (_routeKey in FLO_PF_SyncRetryAt) then {
    _retryAt = FLO_PF_SyncRetryAt get _routeKey;
};

if !(_routeKey in FLO_PF_SyncPending) then {
    if (diag_tickTime >= _retryAt) then {
        FLO_PF_SyncPending set [_routeKey, true];

        private _cb = {
            params ["_status", "_posArray", "_args"];
            _args params ["_key", "_fallback"];

            FLO_PF_SyncPending deleteAt _key;

            if (_status && {_posArray isEqualType []} && {count _posArray > 0}) then {
                FLO_PF_SyncCache set [_key, [+_posArray, diag_tickTime + 300]];
                FLO_PF_SyncRetryAt deleteAt _key;
            } else {
                FLO_PF_SyncCache set [_key, [[_fallback], diag_tickTime + 10]];
                FLO_PF_SyncRetryAt set [_key, diag_tickTime + 30];
            };
        };

        [_startPos, _endPos, _cb, [_routeKey, _fallbackPos], _trails, "SYNC_COMPAT"] call FLO_fnc_findRoadPath;
    };
};

[ _fallbackPos ]
