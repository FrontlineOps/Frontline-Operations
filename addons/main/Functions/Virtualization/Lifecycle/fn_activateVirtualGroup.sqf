/*
 * Function: FLO_fnc_activateVirtualGroup
 * Author: Frontline Operations Development Group
 * Description:
 * Activates a virtual group by spawning it in the game world.
 *
 * Arguments:
 * 0: Group ID <STRING> - Unique identifier for the virtual group
 * 1: Group Data <HASHMAP> - HashMap containing group data
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * ["vgroup_1", _groupData] call FLO_fnc_activateVirtualGroup;
 */

params ["_groupId", "_groupData"];

// Ensure we're running on the server
if (!isServer) exitWith {false};

// Check if this group is attached to a transport
private _attachedTo = [_groupData] call FLO_fnc_virtualizationGetTransportAttachment;
if (_attachedTo != "") then {
    ["VIRTUALIZATION", 2, format["WARNING: Activating group %1 which claims to be attached to %2. This implies logic failure upstream.", _groupId, _attachedTo]] call FLO_fnc_log;
};

["VIRTUALIZATION", 3, format["Activating virtual group %1", _groupId]] call FLO_fnc_log;

// Extract data from group
private _position = _groupData get "position";
private _requestedPosition = +_position;
private _groupType = _groupData get "groupType";
private _side = _groupData get "side";
private _unitCount = _groupData get "unitCount";
private _allWaypoints = _groupData get "waypoints";
private _currentWpIdx = _groupData get "currentWaypointIndex";
private _realGroup = grpNull;
private _spawnKind = ([_groupType] call FLO_fnc_virtualizationGetArchetype) get "spawnKind";
private _isCivilianGroup = _spawnKind in ["CIVILIAN", "CIVILIAN_VEHICLE"];
private _spawnPools = createHashMap;
if (!_isCivilianGroup) then {
    _spawnPools = [_side] call FLO_fnc_virtualizationGetSpawnPools;
};

if (_unitCount <= 0) exitWith {
    ["VIRTUALIZATION", 1, format [
        "Refusing to activate zero-strength virtual group %1 (%2) - removing stale record",
        _groupId,
        _groupType
    ]] call FLO_fnc_log;
    [_groupId] call FLO_fnc_virtualizationRemoveGroup;
    false
};

private _generatedPatrol = (_groupData get "patrolConfig") isNotEqualTo [];
private _waypoints = [];

// Check if this is a transport with attached groups
private _isTransport = [_groupData] call FLO_fnc_virtualizationIsTransportCarrier;

// Resolve a safe spawn position without changing authoritative virtual state.
// The position is committed only after every spawn step succeeds.
_position = [_position] call FLO_fnc_getSafeUnvirtualizePos;
private _remainingRouteResult = [_groupId, _position, _allWaypoints, _currentWpIdx, _generatedPatrol] call FLO_fnc_virtualizationGetRemainingWaypoints;
_remainingRouteResult params ["_routeAllowed", "_remainingWaypoints", "_routeFailureReason"];
if (!_routeAllowed) exitWith {
    if (_routeFailureReason == "START_IN_WATER") then {
        private _alreadyBlocked = _groupData get "landRouteStartBlocked";
        private _retrySeconds = ["landRouteBlockedRetrySeconds"] call FLO_fnc_virtualizationGetConfigValue;
        _groupData set ["landRouteStartBlocked", true];
        _groupData set ["landRouteRetryAt", diag_tickTime + _retrySeconds];
        if (!_alreadyBlocked) then {
            ["VIRTUALIZATION", 2, format [
                "Activation LAND route deferred group=%1 reason=%2 retrySeconds=%3",
                _groupId,
                _routeFailureReason,
                _retrySeconds
            ]] call FLO_fnc_log;
        };
    } else {
        ["VIRTUALIZATION", 2, format [
            "Activation LAND route rejected group=%1 reason=%2 retrySeconds=%3",
            _groupId,
            _routeFailureReason,
            ["activationRetryCooldown"] call FLO_fnc_virtualizationGetConfigValue
        ]] call FLO_fnc_log;
    };
    false
};
_waypoints = _remainingWaypoints;
private _newDismountIndex = -1;
if ((_groupData get "dismountAtWaypoint") >= 0) then {
    private _insertPos = _groupData get "transportInsertPos";
    if (count _insertPos < 2) then { _insertPos = _groupData get "reinforcementTargetPos"; };
    _newDismountIndex = _waypoints findIf { ((_x select 0) distance2D _insertPos) < 1 };
    if (_newDismountIndex < 0) then {
        ["VIRTUALIZATION", 1, format [
            "Activation route lost transport insert endpoint group=%1 insert=%2 waypoints=%3",
            _groupId,
            _insertPos,
            count _waypoints
        ]] call FLO_fnc_log;
        throw format ["Activation route for %1 lost its transport insert endpoint", _groupId];
    };
};

_realGroup = [_groupId, _groupData, _position, _spawnPools] call FLO_fnc_virtualizationSpawnRealGroup;
if (isNull _realGroup) exitWith {
    ["VIRTUALIZATION", 2, format [
        "Failed to spawn real group for %1 (%2) at %3",
        _groupId,
        _groupType,
        _position
    ]] call FLO_fnc_log;
    false
};

private _routeCandidate = [_groupData] call FLO_fnc_virtualizationCloneValue;
_routeCandidate set ["position", +_position];
_routeCandidate set ["waypoints", _waypoints];
_routeCandidate set ["currentWaypointIndex", 0];
if (_newDismountIndex >= 0) then {
    _routeCandidate set ["dismountAtWaypoint", _newDismountIndex];
};
[_routeCandidate, _realGroup] call FLO_fnc_virtualizationSetRealGroup;
[_routeCandidate, [_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles] call FLO_fnc_virtualizationSetRealVehicles;
_routeCandidate set ["isActive", true];
if !([_groupId, _routeCandidate] call FLO_fnc_virtualizationApplyRealRoute) exitWith {
    [_groupData, _realGroup, false] call FLO_fnc_virtualizationDeleteRealGroupAssets;
    ["VIRTUALIZATION", 2, format ["Activation route publication rejected for %1", _groupId]] call FLO_fnc_log;
    false
};

if !([_groupId, _position] call FLO_fnc_virtualizationUpdateGroupPosition) exitWith {
    [_groupData, _realGroup, false] call FLO_fnc_virtualizationDeleteRealGroupAssets;
    ["VIRTUALIZATION", 1, format [
        "Failed to commit activation position for %1 (%2)",
        _groupId,
        _groupType
    ]] call FLO_fnc_log;
    false
};

[_groupType, _realGroup] call FLO_fnc_virtualizationDistributeIntelItems;

// Commit the remaining route only after activation succeeded.
_groupData set ["waypoints", _waypoints];
_groupData set ["currentWaypointIndex", 0];
_groupData set ["landRouteStartBlocked", false];
_groupData set ["landRouteRetryAt", -1];
if (_newDismountIndex >= 0) then {
    _groupData set ["dismountAtWaypoint", _newDismountIndex];
};

// Set the real group in the group data
[_groupData, _realGroup] call FLO_fnc_virtualizationSetRealGroup;
[ _groupData, [_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles ] call FLO_fnc_virtualizationSetRealVehicles;
_groupData set ["activeInitialUnitCount", count units _realGroup];
_groupData set ["isActive", true];
_groupData set ["lastStateChangeTime", diag_tickTime];
_groupData set ["nextProcessAt", 0];
_realGroup setVariable ["FLO_virtualGroupId", _groupId];

if (_isTransport) then {
    [_groupId, _groupData, _realGroup, _position, _spawnPools] call FLO_fnc_virtualizationLoadTransportPassengers;
};

[_groupId, _groupData, _requestedPosition, _position, _realGroup] call FLO_fnc_virtualizationWarnSuspiciousActivation;

[_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationParkIdleHelicopter;

[_groupData, _groupId] call FLO_fnc_virtualizationValidateGroup;
call FLO_fnc_virtualizationTouchRegistry;

// Fire activation event for GTN/AI Commander integration
[
    "FLO_Virtualization_GroupActivated",
    [_groupId, [_groupId] call FLO_fnc_virtualizationSnapshotGroup, _realGroup]
] call CBA_fnc_localEvent;

["VIRTUALIZATION", 3, format["Activated virtual group: %1 with %2 units", _groupId, count units _realGroup]] call FLO_fnc_log;

// Return success
true
