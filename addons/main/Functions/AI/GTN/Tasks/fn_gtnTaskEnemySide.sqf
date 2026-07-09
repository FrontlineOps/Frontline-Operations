/*
 * Function: FLO_fnc_gtnTaskEnemySide
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the opposing side for player task selection.
 *
 * Arguments:
 *   0: Side <SIDE|STRING>
 *
 * Return Value:
 *   Enemy side <SIDE>
 */

params ["_side"];

private _normalizedSide = [_side] call FLO_fnc_gtnTaskNormalizeSide;
if !(_normalizedSide in [east, west]) exitWith { sideUnknown };

([_normalizedSide] call FLO_fnc_gtnSideContext) get "enemySide"
