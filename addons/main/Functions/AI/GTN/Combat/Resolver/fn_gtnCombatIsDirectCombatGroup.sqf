/*
 * Function: FLO_fnc_gtnCombatIsDirectCombatGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether a group type should participate directly in virtual combat
 *   zones instead of contributing only as abstract support.
 *
 * Arguments:
 *   0: Group type <STRING>
 *
 * Return Value:
 *   Direct combat participant <BOOL>
 */

params ["_groupType"];

_groupType in [
    "infantry",
    "motorized",
    "mechanized",
    "armor",
    "mobile_aa"
]
