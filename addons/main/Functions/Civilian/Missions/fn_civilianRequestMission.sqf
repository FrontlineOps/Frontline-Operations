/*
 * Function: FLO_fnc_civilianRequestMission
 * Author: Frontline Operations Development Group
 * Description:
 *   Handles the civilian "Offer Help" interaction through the rewritten
 *   server-authoritative civilian mission manager.
 *
 * Arguments:
 * 0: Civilian unit <OBJECT>
 * 1: Caller <OBJECT>
 *
 * Return Value:
 * BOOL - True when a mission starts
 */

params [
    ["_civilian", objNull, [objNull]],
    ["_caller", objNull, [objNull]]
];

if (!isServer) exitWith {
    [_civilian, _caller] remoteExecCall ["FLO_fnc_civilianRequestMission", 2, false];
    false
};

if (isNull _civilian || {isNull _caller} || {!alive _civilian} || {!alive _caller}) exitWith { false };

private _result = ["REQUEST_MISSION", [_civilian, _caller]] call FLO_fnc_civilianMissionManager;
if ((keys _result) isEqualTo []) exitWith { false };

private _line = _result get "line";
if (_line != "") then {
    ["Civilian", _line] remoteExec ["BIS_fnc_showSubtitle", owner _caller, false];
};

(_result get "status") == "STARTED"
