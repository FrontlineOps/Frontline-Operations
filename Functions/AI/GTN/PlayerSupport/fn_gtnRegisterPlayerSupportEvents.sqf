/*
 * Function: FLO_fnc_gtnRegisterPlayerSupportEvents
 * Author: Frontline Operations Development Group
 * Description:
 *   Registers server-side CBA event handlers for player support requests.
 *
 * Return Value:
 *   BOOL
 */

if (!isServer) exitWith { false };

if (!isNil "FLO_GTN_PlayerSupportEventsRegistered" && {FLO_GTN_PlayerSupportEventsRegistered}) exitWith { true };

["FLO_GTN_PlayerSupportRequest", {
    _this call FLO_fnc_gtnSubmitPlayerSupportRequestServer;
}] call CBA_fnc_addEventHandler;

FLO_GTN_PlayerSupportEventsRegistered = true;
["GTN Player Support", 3, "Registered player support CBA server events"] call FLO_fnc_log;

true
