/*
 * Function: FLO_fnc_gtnTaskNormalizeSide
 * Author: Frontline Operations Development Group
 * Description:
 *   Normalizes legacy side strings used by player task state.
 *
 * Arguments:
 *   0: Side value <SIDE|STRING>
 *
 * Return Value:
 *   SIDE or original value when not recognized
 */

params ["_value"];

if (_value isEqualType "") exitWith {
    private _key = toUpper _value;
    if (_key isEqualTo "WEST") exitWith { west };
    if (_key isEqualTo "EAST") exitWith { east };
    _value
};

_value
