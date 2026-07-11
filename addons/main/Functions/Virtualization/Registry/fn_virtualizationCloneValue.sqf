/*
 * Function: FLO_fnc_virtualizationCloneValue
 * Description:
 *   Recursively clones arrays and HashMaps used in registry snapshots.
 */

params ["_value"];

if (_value isEqualType []) exitWith {
    _value apply { [_x] call FLO_fnc_virtualizationCloneValue }
};

if (_value isEqualType createHashMap) exitWith {
    private _copy = createHashMap;
    {
        _copy set [_x, [_y] call FLO_fnc_virtualizationCloneValue];
    } forEach _value;
    _copy
};

_value
