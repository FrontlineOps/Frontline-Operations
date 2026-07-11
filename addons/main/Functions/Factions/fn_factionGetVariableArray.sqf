/*
 * Function: FLO_fnc_factionGetVariableArray
 * Author: Frontline Operations Development Group
 * Description:
 *   Reads a mission namespace faction variable as an array while preserving
 *   legacy single-string values as one-item arrays.
 *
 * Arguments:
 * 0: Variable name <STRING>
 *
 * Returns:
 * Values <ARRAY>
 */
params [["_varName", ""]];

if (_varName == "") exitWith { [] };
if (isNil _varName) exitWith { [] };

private _value = missionNamespace getVariable [_varName, []];
if (_value isEqualType "") exitWith { [_value] };
if (!(_value isEqualType [])) exitWith { [] };

_value
