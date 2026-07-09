/*
 * Function: FLO_fnc_gtnCommanderDebugSideColor
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the debug marker color for a side.
 *
 * Arguments:
 * 0: Side <SIDE>
 *
 * Returns:
 * Marker color <STRING>
 */
params ["_side"];

if (_side isEqualTo east) exitWith { "ColorEAST" };
if (_side isEqualTo west) exitWith { "ColorWEST" };
"ColorWhite"
