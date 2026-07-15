/*
 * Function: FLO_fnc_factionGetVariableArray
 * Author: Frontline Operations Development Group
 * Description:
 *   Reads one required array-valued custom faction input.
 *
 * Arguments:
 * 0: Variable name <STRING>
 *
 * Returns:
 * Values <ARRAY>
 */
params [["_varName", ""]];

if (_varName == "") then {
    throw "Custom faction array input has an empty variable name";
};
if (isNil _varName) then {
    throw format ["Custom faction definition is missing required array %1", _varName];
};

private _value = missionNamespace getVariable _varName;
if !(_value isEqualType []) then {
    throw format ["Custom faction input %1 must be an array, got %2", _varName, typeName _value];
};

+_value
