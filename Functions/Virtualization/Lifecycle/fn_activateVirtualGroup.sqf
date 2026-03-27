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
private _groupType = _groupData get "groupType";
private _side = _groupData get "side";
private _unitCount = _groupData get "unitCount";
private _allWaypoints = _groupData get "waypoints";
private _currentWpIdx = _groupData get "currentWaypointIndex";
private _realGroup = grpNull;
private _spawnPools = [_side] call FLO_fnc_virtualizationGetSpawnPools;

if (_unitCount <= 0) exitWith {
    ["VIRTUALIZATION", 1, format [
        "Refusing to activate zero-strength virtual group %1 (%2) - removing stale record",
        _groupId,
        _groupType
    ]] call FLO_fnc_log;
    [FLO_virtualGroups, _groupId] call FLO_fnc_virtualizationRemoveGroup;
    false
};

// Only use remaining waypoints from currentWaypointIndex onwards
// This ensures groups that traveled virtually don't re-get completed waypoints
private _waypoints = [_groupId, _position, _allWaypoints, _currentWpIdx] call FLO_fnc_virtualizationGetRemainingWaypoints;

// Check if this is a transport with attached groups
private _isTransport = [_groupData] call FLO_fnc_virtualizationIsTransportCarrier;

// Ensure we don't spawn on top of players.
_position = [_position] call FLO_fnc_getSafeUnvirtualizePos;
[FLO_virtualGroups, _groupId, _position] call FLO_fnc_virtualizationUpdateGroupPosition;
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
if (!isNull _realGroup && {_side in [east, west, independent]} && {_side != civilian}) then {
    _realGroup = [_realGroup, _side] call FLO_fnc_setSide;
};
if (isNull _realGroup) exitWith {
    ["VIRTUALIZATION", 1, format [
        "Failed to apply side correction for %1 (%2)",
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
_groupData set ["isActive", true];
_groupData set ["lastStateChangeTime", diag_tickTime];
_realGroup setVariable ["FLO_virtualGroupId", _groupId];

if (_isTransport) then {
    [_groupId, _groupData, _realGroup, _position, _spawnPools] call FLO_fnc_virtualizationLoadTransportPassengers;
};

[_groupId, _groupData] call FLO_fnc_virtualizationApplyRealRoute;

// Fire activation event for GTN/AI Commander integration
["FLO_Virtualization_GroupActivated", [_groupId, _groupData, _realGroup]] call CBA_fnc_localEvent;

["VIRTUALIZATION", 3, format["Activated virtual group: %1 with %2 units", _groupId, count units _realGroup]] call FLO_fnc_log;

// Return success
true
