/*
 * Function: FLO_fnc_updateVirtualGroupWaypoints
 * Author: Frontline Operations Development Group
 * Description:
 * Updates the waypoints for a virtual group. If the group is active, updates its real waypoints.
 * If inactive, stores the waypoints for when it gets activated.
 *
 * Arguments:
 * 0: Group ID <STRING> - Unique identifier for the virtual group
 * 1: Waypoints <ARRAY> - Array of waypoint data in format:
 *   Each waypoint is an array: [position, type, behavior, speed, formation, combat mode]
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * ["vgroup_1", [[getMarkerPos "marker_1", "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"]]] call FLO_fnc_updateVirtualGroupWaypoints;
 */

params [
    "_groupId",
    "_waypoints"
];

// Ensure virtualization system is initialized
if (isNil "FLO_virtualGroups") exitWith {
    ["VIRTUALIZATION", 1, "Cannot update waypoints - virtualization system not initialized"] call FLO_fnc_log;
    false
};

// Get the group data
private _groupData = (FLO_virtualGroups get "_groups") getOrDefault [_groupId, objNull];
if (isNull _groupData) exitWith {
    ["VIRTUALIZATION", 2, format["Cannot update waypoints - virtual group %1 not found", _groupId]] call FLO_fnc_log;
    false
};

// Update the stored waypoints in the group data
_groupData set ["waypoints", _waypoints];

// If the group is active, update its real waypoints
if (_groupData getOrDefault ["isActive", false]) then {
    private _realGroup = _groupData getOrDefault ["realGroup", grpNull];
    if (!isNull _realGroup) then {
        // Clear existing waypoints
        while {count waypoints _realGroup > 0} do {
            deleteWaypoint [_realGroup, 0];
        };
        
        // Add new waypoints
        {
            private _wpPos = _x select 0;
            private _wpType = _x select 1;
            private _wpBehavior = _x select 2;
            private _wpSpeed = _x select 3;
            private _wpFormation = _x select 4;
            private _wpMode = _x select 5;
            
            private _wp = _realGroup addWaypoint [_wpPos, 0];
            _wp setWaypointType _wpType;
            _wp setWaypointBehaviour _wpBehavior;
            _wp setWaypointSpeed _wpSpeed;
            _wp setWaypointFormation _wpFormation;
            _wp setWaypointCombatMode _wpMode;
        } forEach _waypoints;
        
        // Set new movement state
        _groupData set ["state", "moving"];
        
        // Update marker if debug mode is on
        if (FLO_virtualGroups get "_debugMode") then {
            [_groupId, _groupData] call FLO_fnc_createVirtualGroupMarker;
        };
    };
};

// Log the update
["VIRTUALIZATION", 3, format["Updated waypoints for virtual group %1", _groupId]] call FLO_fnc_log;

// Return success
true 