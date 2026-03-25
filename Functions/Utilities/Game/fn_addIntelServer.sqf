/**
 * Function: FLO_fnc_addIntelServer
 * 
 * Description:
 * Sends request to server to add an Intel item
 *
 * Parameters:
 * _gridPos - position in grid format
 *
 * Returns:
 * nothing
 *
 * Example:
 * [] call FLO_fnc_addIntelServer;
 */
params ["_gridPos"];

if !(isServer) exitwith {};

[["STR_FLO_INTEL_MIL", _gridPos], "info"] call FLO_fnc_sendNotification;
["INTEL", 3, format ["Legacy addIntelServer invoked for grid %1 - converted to notification only", _gridPos]] call FLO_fnc_log;
