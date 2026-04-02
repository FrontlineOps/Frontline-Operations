/*
 * Function: FLO_fnc_civilianDetainActions
 * Description:
 *   Adds detainee interaction actions that route back to the server command
 *   handler.
 */

params [["_unit", objNull, [objNull]]];
if (isNull _unit) exitWith {};

private _jipId = format ["FLO_CIV_ACT_%1", netId _unit];
[_unit, false, true] remoteExec ["FLO_fnc_civilianConfigureActionsLocal", 0, _jipId];
