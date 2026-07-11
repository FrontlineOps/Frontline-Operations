/*
 * Function: FLO_fnc_gtnNormalizeIntelSignatureValue
 * Author: Frontline Operations Development Group
 * Description:
 *   Normalizes marker record values for deterministic intel publish signatures.
 *
 * Arguments:
 * 0: Value <ANY>
 *
 * Returns:
 * Normalized text <STRING>
 */
params ["_value"];

if (_value isEqualType 0) exitWith {
    str (round (_value * 10) / 10)
};

if (_value isEqualType []) exitWith {
    "[" + ((_value apply { [_x] call FLO_fnc_gtnNormalizeIntelSignatureValue }) joinString ",") + "]"
};

str _value
