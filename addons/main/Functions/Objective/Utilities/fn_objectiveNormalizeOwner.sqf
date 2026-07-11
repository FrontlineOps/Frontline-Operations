/*
 * Function: FLO_fnc_objectiveNormalizeOwner
 * Author: Frontline Operations Development Group
 * Description:
 *   Normalizes legacy string owner values to side values.
 *
 * Arguments:
 * 0: Owner <SIDE|STRING>
 *
 * Returns:
 * Owner <SIDE|STRING>
 */
params ["_owner"];

if (_owner isEqualType "") then {
    private _ownerKey = toUpper _owner;
    if (_ownerKey isEqualTo "EAST") then { _owner = east; };
    if (_ownerKey isEqualTo "WEST") then { _owner = west; };
};

_owner
