/*
 * Function: FLO_fnc_gtnCombatIsSupportProvider
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether a group type contributes abstract support to virtual combat
 *   resolution instead of entering direct engagement zones.
 *
 * Arguments:
 *   0: Group type <STRING>
 *
 * Return Value:
 *   Support provider <BOOL>
 */

params ["_groupType"];

_groupType in [
    "artillery",
    "air",
    "helicopter",
    "jet"
]
