/*
 * Function: FLO_fnc_gtnBroadcastCommanderRadioMessage
 * Author: Frontline Operations Development Group
 * Description:
 *   Broadcasts a side-filtered commander radio line to clients. Local client
 *   filtering is still handled by FLO_fnc_gtnCommanderRadioMessage.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Sender label <STRING>
 *   2: Text <STRING>
 *
 * Return Value:
 *   BOOL
 */

if (!isServer) exitWith { false };

params [
    ["_side", sideUnknown],
    ["_sender", "HQ", [""]],
    ["_text", "", [""]]
];

if !(_side in [east, west]) exitWith { false };
if (_text == "") exitWith { false };

[_side, _sender, _text] remoteExecCall ["FLO_fnc_gtnCommanderRadioMessage", 0, false];

true
