/*
 * Function: FLO_fnc_factionBuildVehiclePoolFromVariables
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a de-duplicated vehicle class pool from required custom faction
 *   array inputs.
 *
 * Arguments:
 * 0: Variable names <ARRAY>
 *
 * Returns:
 * Vehicle classes <ARRAY>
 */
params [["_varNames", []]];

private _merged = [];
{
    _merged append ([_x] call FLO_fnc_factionGetVariableArray);
} forEach _varNames;

[_merged] call FLO_fnc_factionExtractVehicleClasses
