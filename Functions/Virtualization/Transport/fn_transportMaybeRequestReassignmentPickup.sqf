/*
 * Function: FLO_fnc_transportMaybeRequestReassignmentPickup
 * Author: Frontline Operations Development Group
 * Description:
 *   Allows foot infantry groups to request a pickup when a new commander order
 *   sends them on a long foot movement.
 *
 * Arguments:
 *   0: Infantry Group ID <STRING>
 *   1: Group Data <HASHMAP>
 *   2: Destination Position <ARRAY>
 *   3: Order Tag <STRING>
 *
 * Return Value:
 *   BOOL - True when transport was assigned
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_targetPos", [], [[]]],
    ["_orderTag", "", [""]]
];

if (_groupId == "") exitWith { false };
if !(_targetPos isEqualType [] && {count _targetPos >= 2}) exitWith { false };
if ((_groupData get "groupType") != "infantry") exitWith { false };
if ((_groupData get "attachedTo") != "" || {(_groupData get "mountedIn") != ""}) exitWith { false };

private _distance = (_groupData get "position") distance2D _targetPos;
if (_distance < FLO_Transport_ReassignmentPickupMinDistance) exitWith { false };

private _transportId = [_groupId, _targetPos] call FLO_fnc_transportRequest;
if (_transportId == "") exitWith { false };

["TRANSPORT", 3, format [
    "Assigned reassignment pickup for %1 via %2 (%3, %4m)",
    _groupId,
    _transportId,
    _orderTag,
    round _distance
]] call FLO_fnc_log;

true
