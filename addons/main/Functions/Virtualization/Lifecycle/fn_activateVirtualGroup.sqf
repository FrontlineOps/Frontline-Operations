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

// Only use remaining waypoints from currentWaypointIndex onwards
// This ensures groups that traveled virtually don't re-get completed waypoints
private _generatedPatrol = (_groupData get "patrolConfig") isNotEqualTo [];
private _waypoints = [_groupId, _position, _allWaypoints, _currentWpIdx, _generatedPatrol] call FLO_fnc_virtualizationGetRemainingWaypoints;

// Check if this is a transport with attached groups
private _isTransport = [_groupData] call FLO_fnc_virtualizationIsTransportCarrier;

// Resolve a safe spawn position without changing authoritative virtual state.
// The position is committed only after every spawn step succeeds.
_position = [_position] call FLO_fnc_getSafeUnvirtualizePos;
_realGroup = [_groupId, _groupData, _position, _spawnPools] call FLO_fnc_virtualizationSpawnRealGroup;
if (isNull _realGroup) exitWith {
    ["VIRTUALIZATION", 1, format [
        "Failed to spawn real group for %1 (%2) at %3",
        _groupId,
        _groupType,
        _position
    ]] call FLO_fnc_log;
    false
};

// ========================================================================
// SIDE FIX - Ensure all units are on the correct side
// This handles cases where mission makers use BLUFOR classnames as OPFOR enemies
// The units' classname side doesn't matter - their group side determines allegiance
// ========================================================================
private _sideCorrectionFailed = false;
if (!isNull _realGroup && {_side in [east, west, independent]} && {_side != civilian}) then {
    private _sideCorrectedGroup = [_realGroup, _side] call FLO_fnc_setSide;
    if (isNull _sideCorrectedGroup) then {
        ["VIRTUALIZATION", 1, format [
            "Failed to apply side correction for %1 (%2) - cleaning up spawned assets",
            _groupId,
            _groupType
        ]] call FLO_fnc_log;
        [_groupData, _realGroup, false] call FLO_fnc_virtualizationDeleteRealGroupAssets;
        _sideCorrectionFailed = true;
    } else {
        _realGroup = _sideCorrectedGroup;
    };
};
if (_sideCorrectionFailed) exitWith { false };
if (isNull _realGroup) exitWith {
    ["VIRTUALIZATION", 1, format [
        "Failed to apply side correction for %1 (%2)",
        _groupId,
        _groupType
    ]] call FLO_fnc_log;
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

// Reset currentWaypointIndex only after activation succeeded.
_groupData set ["currentWaypointIndex", 0];

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

[_groupId, _groupData] call FLO_fnc_virtualizationApplyRealRoute;
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
