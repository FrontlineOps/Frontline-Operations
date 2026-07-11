/*
 * Function: FLO_fnc_civilianDetainActions
 * Description:
 *   Adds detainee interaction actions that route back to the server command
 *   handler.
 */

params [["_unit", objNull, [objNull]]];
if (isNull _unit) exitWith {};

[_unit, false, true] remoteExec ["FLO_fnc_civilianConfigureActionsLocal", 0, _unit];
