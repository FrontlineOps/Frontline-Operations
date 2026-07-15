/*
 * Function: FLO_fnc_transportReturnCarrierToReserve
 * Author: Frontline Operations Development Group
 * Description:
 *   Sends a released dedicated reserve carrier back to its staging position so
 *   completed inserts do not leave active transports idle at the unload zone.
 *
 * Arguments:
 *   0: Carrier Group ID <STRING>
 *   1: Carrier Group Data <HASHMAP>
 *
 * Return Value:
 *   BOOL - True when a return route was assigned
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]]
];

if (_groupId == "") exitWith { false };
if !(_groupData get "transportRole") exitWith { false };

private _reservePos = _groupData get "spawnPosition";
private _completionRadius = [35, 75] select ((_groupData get "groupType") == "helicopter");
private _waypoints = [
    [_reservePos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", _completionRadius]
];

if !([_groupId, _waypoints, true, "TRANSPORT_RTB"] call FLO_fnc_updateVirtualGroupWaypoints) exitWith {
    ["TRANSPORT", 2, format ["Could not route released transport %1 back to reserve", _groupId]] call FLO_fnc_log;
    false
};
[_groupId, createHashMapFromArray [["executionState", "RTB"]]] call FLO_fnc_virtualizationPatchGroup;

["TRANSPORT", 3, format [
    "Sent released transport %1 back to reserve at %2",
    _groupId,
    _reservePos
]] call FLO_fnc_log;

true
