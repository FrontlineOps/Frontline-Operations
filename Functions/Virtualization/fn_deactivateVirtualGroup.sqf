/*
 * Function: FLO_fnc_deactivateVirtualGroup
 * Author: Frontline Operations Development Group
 * Description:
 * Deactivates a virtual group by removing it from the game world but keeping its virtual status.
 *
 * Arguments:
 * 0: Group ID <STRING> - Unique identifier for the virtual group
 * 1: Group Data <HASHMAP> - HashMap containing group data
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * ["vgroup_1", _groupData] call FLO_fnc_deactivateVirtualGroup;
 */

params ["_groupId", "_groupData"];

// Ensure we're running on the server
if (!isServer) exitWith {false};

["VIRTUALIZATION", 3, format["Deactivating virtual group %1", _groupId]] call FLO_fnc_log;

// Extract data from group
private _realGroup = _groupData getOrDefault ["realGroup", grpNull];

// If the group is not active or doesn't have a real group, nothing to do
if (isNull _realGroup) exitWith {
    ["VIRTUALIZATION", 2, format["Attempted to deactivate virtual group %1 but no real group exists", _groupId]] call FLO_fnc_log;
    false
};

// Save the current position before deleting the group
private _currentPos = [0,0,0];
if (count units _realGroup > 0) then {
    _currentPos = getPos (leader _realGroup);
    _groupData set ["position", _currentPos];
};

// Save any current waypoints before deleting
private _waypoints = [];
{
    if (_forEachIndex > 0) then { // Skip the first waypoint (which is the current position)
        private _waypointData = [
            waypointPosition _x,
            waypointType _x,
            waypointBehaviour _x,
            waypointSpeed _x,
            waypointFormation _x,
            waypointCombatMode _x
        ];
        _waypoints pushBack _waypointData;
    };
} forEach waypoints _realGroup;

// Update the waypoints in the group data
_groupData set ["waypoints", _waypoints];

// Save the current state/behavior before deleting
private _state = "idle";
if (behaviour (leader _realGroup) == "COMBAT") then {
    _state = "attacking";
} else {
    if (currentCommand (leader _realGroup) == "MOVE") then {
        _state = "moving";
    };
};
_groupData set ["state", _state];

// Delete all units in the group
{
    deleteVehicle _x;
} forEach (units _realGroup + (vehicles select {_x in (units _realGroup apply {vehicle _x})}));

// Delete the group
deleteGroup _realGroup;

// Update group data
_groupData set ["realGroup", grpNull];
_groupData set ["isActive", false];

// Update debug marker if needed
if (FLO_virtualGroups get "_debugMode") then {
    [_groupId, _groupData] call FLO_fnc_createVirtualGroupMarker;
};

// Return success
true 