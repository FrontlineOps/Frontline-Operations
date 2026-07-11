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

if (isNil "FLO_GTN_CommanderRadioDedup") then {
    FLO_GTN_CommanderRadioDedup = createHashMap;
};

private _dedupeKey = format ["%1|%2|%3", _side, toUpper _sender, _text];
private _now = diag_tickTime;
private _lastSentAt = if (_dedupeKey in FLO_GTN_CommanderRadioDedup) then { FLO_GTN_CommanderRadioDedup get _dedupeKey } else { -999 };
if ((_now - _lastSentAt) < 1) exitWith { false };
FLO_GTN_CommanderRadioDedup set [_dedupeKey, _now];

private _targetOwners = [_side] call FLO_fnc_gtnGetSideClientOwners;
if (_targetOwners isEqualTo []) exitWith { false };

[_side, _sender, _text] remoteExecCall ["FLO_fnc_gtnCommanderRadioMessage", _targetOwners, false];

["commanderRadioMessages", 1] call FLO_fnc_netDebugRecord;
["commanderRadioTargets", count _targetOwners] call FLO_fnc_netDebugRecord;

true
