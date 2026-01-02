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
["VIRTUALIZATION", 3, format["Deactivating virtual group %1", _groupId]] call FLO_fnc_log;

// Extract data from group
private _realGroup = _groupData get "realGroup";

// If the group is not active or doesn't have a real group, nothing to do
if (isNull _realGroup) then {
    ["VIRTUALIZATION", 2, format["Attempted to deactivate virtual group %1 but no real group exists", _groupId]] call FLO_fnc_log;
};

// Save the current position before deleting the group
// Only save if we get a valid position from a living leader
private _leader = leader _realGroup;
if (!isNull _leader && {alive _leader}) then {
    private _currentPos = getPos _leader;
    // Validate position - only save if it's not near origin
    if ((_currentPos select 0) > 100 || (_currentPos select 1) > 100) then {
        _groupData set ["position", _currentPos];
        ["VIRTUALIZATION", 4, format["Saved position %1 for group %2", _currentPos, _groupId]] call FLO_fnc_log;
    } else {
        ["VIRTUALIZATION", 2, format["WARNING: Not saving invalid position %1 for group %2 - keeping original", _currentPos, _groupId]] call FLO_fnc_log;
    };
};

// Save any current waypoints before deleting
// Only overwrite virtual waypoints if the real group has actual waypoints
private _realWaypoints = waypoints _realGroup;
if (count _realWaypoints > 1) then {
    private _savedWaypoints = [];
    {
        if (_forEachIndex > 0) then {
            private _wpPos = waypointPosition _x;
            if (_wpPos isEqualType [] && {count _wpPos >= 2} && {(_wpPos select 0) > 100 || (_wpPos select 1) > 100}) then {
                private _waypointData = [
                    _wpPos,
                    waypointType _x,
                    waypointBehaviour _x,
                    waypointSpeed _x,
                    waypointFormation _x,
                    waypointCombatMode _x
                ];
                _savedWaypoints pushBack _waypointData;
            };
        };
    } forEach _realWaypoints;

    // Only update if we got valid waypoints
    if (count _savedWaypoints > 0) then {
        _groupData set ["waypoints", _savedWaypoints];
        _groupData set ["currentWaypointIndex", 0];
        ["VIRTUALIZATION", 4, format["Saved %1 waypoints from real group %2", count _savedWaypoints, _groupId]] call FLO_fnc_log;
    };
} else {
    ["VIRTUALIZATION", 4, format["Keeping existing virtual waypoints for %1 (real group had no waypoints)", _groupId]] call FLO_fnc_log;
};

// Save the current state/behavior before deleting
private _state = "idle";
if (behaviour (leader _realGroup) isEqualTo "COMBAT") then {
    _state = "attacking";
} else {
    if (currentCommand (leader _realGroup) isEqualTo "MOVE") then {
        _state = "moving";
    };
};
_groupData set ["state", _state];

// Save the composition of the group for persistence - only include living units
// The ProcessedVehicles array is used to prevent duplicate vehicles from being added to the composition
// This is a bit of a hack, but it works. I want to find a better way to do this, @Crashdome
private _comp = [];
private _processedVehicles = []; // Track vehicles we've already processed

{
    // Only include alive units in the composition
    if (alive _x) then {
        private _unit = _x;
        private _unitType = "";
        
        if (vehicle _unit != _unit) then {
            // Unit is in a vehicle
            private _vehicle = vehicle _unit;
            private _vehicleType = typeOf _vehicle;
            
            // Check if we've already processed this vehicle
            if (!(_vehicle in _processedVehicles)) then {
                // Add vehicle to processed list
                _processedVehicles pushBack _vehicle;
                
                // Store the vehicle type
                _unitType = _vehicleType;
                _comp pushBack _unitType;
                
                ["VIRTUALIZATION", 3, format["Saving vehicle %1 to composition", _vehicleType]] call FLO_fnc_log;
            };
        } else {
            // Unit is on foot - store as normal
            _unitType = typeOf _unit;
            _comp pushBack _unitType;
        };
    };
} forEach units _realGroup;

// Update the composition in the group data
_groupData set ["comp", _comp];

// Delete all units in the group
{
    deleteVehicle _x;
} forEach (units _realGroup + (vehicles select {_x in (units _realGroup apply {vehicle _x})}));

// Delete the group
deleteGroup _realGroup;

// Update group data
_groupData set ["realGroup", grpNull];
_groupData set ["isActive", false];
_groupData set ["lastStateChangeTime", diag_tickTime];

["FLO_Virtualization_GroupDeactivated", [_groupId, _groupData]] call CBA_fnc_localEvent;

["VIRTUALIZATION", 3, format["Deactivated virtual group: %1", _groupId]] call FLO_fnc_log;

true