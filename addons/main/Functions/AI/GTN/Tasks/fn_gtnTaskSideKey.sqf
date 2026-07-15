/*
 * Function: FLO_fnc_gtnTaskSideKey
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the GTN task state key for a playable side.
 *
 * Arguments:
 *   0: Side <SIDE>
 *
 * Return Value:
 *   Side key <STRING>
 */

params [["_side", sideUnknown]];

if !(_side in [east, west]) exitWith { "" };

([_side] call FLO_fnc_gtnSideContext) get "sideKey"
