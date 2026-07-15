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
 *   1: Carrier group ID <STRING>
 *   2: Mission plan <HASHMAP>
 *   3: Final destination position <ARRAY>
 *   4: Request distance <NUMBER>
 *
 * Return Value:
 *   BOOL - True when the plan was committed
 */

params [
    ["_infantryGroupId", "", [""]],
    ["_transportId", "", [""]],
    ["_missionPlan", createHashMap, [createHashMap]],
    ["_destinationPos", [0, 0, 0], [[]]],
    ["_distance", 0, [0]]
];

[_infantryGroupId] call FLO_fnc_transportGetTrackedGroup;
private _transportData = [_transportId] call FLO_fnc_transportGetTrackedGroup;

private _insertMode = _missionPlan get "mode";
private _insertPos = _missionPlan get "insertPos";
private _completionRadius = _missionPlan get "completionRadius";
private _orderTag = _missionPlan get "orderTag";
private _waypoints = [
    [_insertPos, "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", _completionRadius]
];
private _carrierArchetype = [(_transportData get "groupType")] call FLO_fnc_virtualizationGetArchetype;
private _routePreflightAllowed = true;
private _routePreflightReason = "";
if ((_carrierArchetype get "movementDomain") == "LAND") then {
    private _preflight = [
        _transportData get "position",
        _waypoints,
        true,
        _orderTag,
        false
    ] call FLO_fnc_virtualizationResolveLandWaypoints;
    _routePreflightAllowed = _preflight select 0;
    _routePreflightReason = _preflight select 2;
};

if (!_routePreflightAllowed) exitWith {
    ["TRANSPORT", 2, format [
        "Request failed: no land route for carrier %1 to insert %2 (%3)",
        _transportId,
        _infantryGroupId,
        _routePreflightReason
    ]] call FLO_fnc_log;
    false
};

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

if !([_transportId, _waypoints, true, _orderTag] call FLO_fnc_updateVirtualGroupWaypoints) then {
    ["TRANSPORT", 1, format ["Preflighted carrier route failed during commit carrier=%1 passenger=%2", _transportId, _infantryGroupId]] call FLO_fnc_log;
    throw format ["FLO_fnc_transportCommitMissionPlan: preflighted route failed for %1", _transportId];
};

private _dismountWaypointIndex = count (_transportData get "waypoints") - 1;

private _carrierChanges = createHashMapFromArray [
    ["dismountAtWaypoint", _dismountWaypointIndex],
    ["transportInsertMode", _insertMode],
    ["transportInsertPos", _insertPos],
    ["transportLandCommandIssued", false],
    ["transportUnloadCommandIssued", false],
    ["transportUnloadIssuedAt", -1],
    ["missionLock", "TRANSPORT"],
    ["missionType", _insertMode],
    ["executionState", "TRANSPORT"]
];
[_transportId, _carrierChanges] call FLO_fnc_virtualizationPatchGroup;

private _passengerChanges = createHashMapFromArray [
    ["missionLock", "TRANSPORT"],
    ["missionType", _insertMode],
    ["postDismountWaypoint", [_destinationPos, _orderTag]]
];
[_infantryGroupId, _passengerChanges] call FLO_fnc_virtualizationPatchGroup;

["TRANSPORT", 3, format [
    "Request: Transport %1 (%2) assigned to carry %3 via %4 to destination (%5m)",
    _transportId,
    _transportData get "groupType",
    _infantryGroupId,
    _insertMode,
    round _distance
]] call FLO_fnc_log;

true
