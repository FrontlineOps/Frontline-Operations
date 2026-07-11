/*
 * Function: FLO_fnc_gtnTaskSideKey
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the GTN task state key for a playable side.
 *
 * Arguments:
 *   0: Side <SIDE|STRING>
 *
 * Return Value:
 *   Side key <STRING>
 */

params ["_side"];

private _normalizedSide = [_side] call FLO_fnc_gtnTaskNormalizeSide;
if !(_normalizedSide in [east, west]) exitWith { "" };

([_normalizedSide] call FLO_fnc_gtnSideContext) get "sideKey"
