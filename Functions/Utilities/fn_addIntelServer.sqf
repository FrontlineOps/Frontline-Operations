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

 FLO_Intel_System call ["addIntel", [0, "intel_item"]];
 ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", _gridPos], "info"] call FLO_fnc_sendNotification;