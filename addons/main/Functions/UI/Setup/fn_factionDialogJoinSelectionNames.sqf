/*
 * Function: FLO_fnc_factionDialogJoinSelectionNames
 * Author: Frontline Operations Development Group
 * Description:
 *   Joins selected faction display names into the merged faction label.
 *
 * Arguments:
 * 0: Selections <ARRAY>
 *
 * Returns:
 * Joined label <STRING>
 */
params ["_selections"];

(_selections apply { _x select 0 }) joinString " + "
