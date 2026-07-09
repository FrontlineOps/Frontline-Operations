/*
 * Function: FLO_fnc_factionIsUnsignedInt
 * Author: Frontline Operations Development Group
 * Description:
 *   Checks whether text is a non-empty unsigned integer.
 *
 * Arguments:
 * 0: Text <STRING>
 *
 * Returns:
 * Is unsigned integer <BOOL>
 */
params ["_value"];

if (_value == "") exitWith { false };
((toArray _value) findIf {_x < 48 || {_x > 57}}) < 0
