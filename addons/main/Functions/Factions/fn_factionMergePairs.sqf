/*
 * Function: FLO_fnc_factionMergePairs
 * Author: Frontline Operations Development Group
 * Description:
 *   Merges ordered [key, value] arrays while preserving base order and appending
 *   new override keys.
 *
 * Arguments:
 * 0: Base pairs <ARRAY>
 * 1: Override pairs <ARRAY>
 *
 * Returns:
 * Merged pairs <ARRAY>
 */
params ["_basePairs", "_overridePairs"];

private _overrideMap = createHashMap;
private _overrideOrder = [];
{
    if (_x isEqualType [] && {count _x >= 2}) then {
        private _key = _x select 0;
        _overrideMap set [_key, _x select 1];
        _overrideOrder pushBackUnique _key;
    };
} forEach _overridePairs;

private _seen = createHashMap;
private _result = [];
{
    if (_x isEqualType [] && {count _x >= 2}) then {
        private _key = _x select 0;
        private _value = if (_key in _overrideMap) then { _overrideMap get _key } else { _x select 1 };
        _result pushBack [_key, _value];
        _seen set [_key, true];
    };
} forEach _basePairs;

{
    if !(_x in _seen) then {
        _result pushBack [_x, _overrideMap get _x];
    };
} forEach _overrideOrder;

_result
