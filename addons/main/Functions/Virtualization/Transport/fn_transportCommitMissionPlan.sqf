/*
 * Function: FLO_fnc_transportCommitMissionPlan
 * Author: Frontline Operations Development Group
 * Description:
 *   Commits a selected transport mission plan by claiming the carrier,
 *   attaching the passenger, assigning the carrier insert waypoint, and applying
 *   canonical mission lock/execution/post-dismount state.
 *
 * Arguments:
 *   0: Passenger group ID <STRING>
 *   1: Passenger group data <HASHMAP>
 *   2: Carrier group ID <STRING>
 *   3: Carrier group data <HASHMAP>
 *   4: Mission plan <HASHMAP>
 *   5: Final destination position <ARRAY>
 *   6: Request distance <NUMBER>
 *
 * Return Value:
 *   BOOL - True when the plan was committed
 */

params [
    ["_infantryGroupId", "", [""]],
    ["_infData", createHashMap, [createHashMap]],
    ["_transportId", "", [""]],
    ["_transportData", createHashMap, [createHashMap]],
    ["_missionPlan", createHashMap, [createHashMap]],
    ["_destinationPos", [0, 0, 0], [[]]],
    ["_distance", 0, [0]]
];

private _insertMode = _missionPlan get "mode";
private _insertPos = _missionPlan get "insertPos";
private _completionRadius = _missionPlan get "completionRadius";
private _orderTag = _missionPlan get "orderTag";

[_transportId, _infantryGroupId] call FLO_fnc_transportPoolClaim;

if !([_infantryGroupId, _transportId] call FLO_fnc_transportAttach) exitWith {
    [_transportId] call FLO_fnc_transportPoolRelease;
    ["TRANSPORT", 2, format [
        "Request failed: could not attach %1 to %2",
        _infantryGroupId,
        _transportId
    ]] call FLO_fnc_log;
    false
};

private _waypoints = [
    [_insertPos, "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", _completionRadius]
];
[_transportId, _waypoints, false, true, _orderTag] call FLO_fnc_updateVirtualGroupWaypoints;

_transportData set ["dismountAtWaypoint", 0];
_transportData set ["transportInsertMode", _insertMode];
_transportData set ["transportInsertPos", _insertPos];
_transportData set ["transportLandCommandIssued", false];
_transportData set ["transportUnloadCommandIssued", false];
_transportData set ["transportUnloadIssuedAt", -1];
[_transportData, "TRANSPORT", _insertMode] call FLO_fnc_virtualizationSetMissionLock;
[_transportData, "TRANSPORT"] call FLO_fnc_virtualizationSetExecutionState;
[_infData, "TRANSPORT", _insertMode] call FLO_fnc_virtualizationSetMissionLock;
_infData set ["postDismountWaypoint", [_destinationPos, _orderTag]];

["TRANSPORT", 3, format [
    "Request: Transport %1 (%2) assigned to carry %3 via %4 to destination (%5m)",
    _transportId,
    _transportData get "groupType",
    _infantryGroupId,
    _insertMode,
    round _distance
]] call FLO_fnc_log;

true
