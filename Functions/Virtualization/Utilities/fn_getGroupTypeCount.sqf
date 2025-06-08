/*
 * Function: FLO_fnc_getGroupTypeCount
 * Author: Frontline Operations Development Group
 * Description:
 * Returns the unit/vehicle count for a given group type from OPFOR_Group_Counts.
 * Falls back to 1 and logs an error if the group type is not found.
 *
 * Arguments:
 * 0: Group Type <STRING>
 *
 * Return Value:
 * Count <NUMBER>
 *
 * Example:
 * ["helicopter"] call FLO_fnc_getGroupTypeCount;
 */

params ["_groupType"];
private _groupCounts = OPFOR_Group_Counts;
private _entry = _groupCounts select { _x select 0 isEqualTo _groupType };
if (count _entry > 0) then {
    (_entry select 0) select 1
} else {
    diag_log format ["[VIRTUALIZATION] ERROR: No unit count defined for group type %1, using default of 1", _groupType];
    1
}; 