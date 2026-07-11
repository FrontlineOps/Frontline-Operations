/*
 * Function: FLO_fnc_gtnCommanderDebugSideLabel
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the debug label for a side.
 *
 * Arguments:
 * 0: Side <SIDE>
 *
 * Returns:
 * Label <STRING>
 */
params ["_side"];

if (_side isEqualTo east) exitWith { "EAST" };
if (_side isEqualTo west) exitWith { "WEST" };
"UNKNOWN"
