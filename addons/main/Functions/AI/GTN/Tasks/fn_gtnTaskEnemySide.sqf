/*
 * Function: FLO_fnc_gtnTaskEnemySide
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the opposing side for player task selection.
 *
 * Arguments:
 *   0: Side <SIDE>
 *
 * Return Value:
 *   Enemy side <SIDE>
 */

params [["_side", sideUnknown]];

if !(_side in [east, west]) exitWith { sideUnknown };

([_side] call FLO_fnc_gtnSideContext) get "enemySide"
