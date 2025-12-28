/*
 * Function: FLO_fnc_virtualGroupsUpdateLoop
 * Author: Frontline Operations Development Group
 * Description:
 * Update loop for the virtualization system. Handles:
 * - Virtual group movement along waypoints
 * - Group activation/deactivation based on player distance
 * - Waypoint completion and cycling
 * - Group state management and elimination
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] spawn FLO_fnc_virtualGroupsUpdateLoop;
 */

// Ensure we're running on the server
if (!isServer) exitWith {};

// Prevent multiple loops from running
if (!isNil "FLO_VirtualGroupsUpdateLoopRunning" && {FLO_VirtualGroupsUpdateLoopRunning}) exitWith {
    ["VIRTUALIZATION", 2, "Virtual groups update loop already running - not starting duplicate"] call FLO_fnc_log;
};

FLO_VirtualGroupsUpdateLoopRunning = true;
["VIRTUALIZATION", 3, "Starting virtual groups update loop"] call FLO_fnc_log;

private _processVirtualMovement = {
    params ["_groupData", "_groupId", "_currentTime"];

    private _position = _groupData get "position";

    // Validate position before processing movement
    if (isNil "_position" || {!(_position isEqualType [])} || {count _position < 2}) exitWith {
        ["VIRTUALIZATION", 1, format["ERROR: Group %1 has invalid position type - skipping movement", _groupId]] call FLO_fnc_log;
    };
    if ((_position select 0) < 100 && (_position select 1) < 100) exitWith {
        ["VIRTUALIZATION", 1, format["ERROR: Group %1 position near origin %2 - skipping movement", _groupId, _position]] call FLO_fnc_log;
    };

    private _waypoints = _groupData getOrDefault ["waypoints", []];
    private _currentWaypointIndex = _groupData getOrDefault ["currentWaypointIndex", 0];
    private _virtualSpeed = _groupData getOrDefault ["virtualSpeed", 10]; // Default 10 m/s if not set
    private _lastMoveTime = _groupData getOrDefault ["lastMoveTime", _currentTime];
    
    // Exit if no waypoints or invalid index
    if (count _waypoints == 0 || _currentWaypointIndex >= count _waypoints) exitWith {
        _groupData set ["state", "idle"];
        _groupData set ["currentWaypointIndex", 0];
    };
    
    // Get current waypoint
    private _currentWaypoint = _waypoints select _currentWaypointIndex;

    // Validate waypoint data
    if (isNil "_currentWaypoint" || {count _currentWaypoint < 2}) exitWith {
        ["VIRTUALIZATION", 1, format["Invalid waypoint data for group %1", _groupId]] call FLO_fnc_log;
        _groupData set ["state", "idle"];
        _groupData set ["currentWaypointIndex", 0];
    };

    private _waypointPos = _currentWaypoint select 0;
    private _waypointType = _currentWaypoint select 1;

    // Additional validation for waypoint position and type
    // Need to figure out why on loading, the waypoints that existed when saving become invalid.
    if (isNil "_waypointPos" || {!(_waypointPos isEqualType [])} || {count _waypointPos < 2}) exitWith {
        ["VIRTUALIZATION", 2, format["Invalid waypoint position for group %1, skipping waypoint", _groupId]] call FLO_fnc_log;
        _groupData set ["state", "idle"];
        _groupData set ["currentWaypointIndex", 0];
    };

    if (isNil "_waypointType" || {!(_waypointType isEqualType "")}) exitWith {
        ["VIRTUALIZATION", 1, format["Invalid waypoint type for group %1, skipping waypoint", _groupId]] call FLO_fnc_log;
        _groupData set ["state", "idle"];
        _groupData set ["currentWaypointIndex", 0];
    };
    
    // Calculate movement
    private _timeDelta = _currentTime - _lastMoveTime;
    private _distanceToWaypoint = _position distance2D _waypointPos;
    
    // Process movement if it's a movement type waypoint
    if (_waypointType in ["MOVE", "LOITER", "SAD", "SENTRY", "CYCLE"] && _distanceToWaypoint > 10) then {
        // Calculate movement for this update
        private _maxMoveDistance = _virtualSpeed * _timeDelta;
        private _actualMoveDistance = _maxMoveDistance min _distanceToWaypoint;
        private _direction = _position getDir _waypointPos;
        
        // Calculate new position
        private _newPosition = _position getPos [_actualMoveDistance, _direction];
        _groupData set ["position", _newPosition];
        _groupData set ["lastMoveTime", _currentTime];
        
        // Update debug marker if enabled
        if (FLO_virtualGroups get "_debugMode") then {
            private _marker = format["vgroup_%1", _groupId];
            if (getMarkerColor _marker != "") then {
                _marker setMarkerPos _newPosition;
                _marker setMarkerDir _direction;
            };
        };
        
        ["VIRTUALIZATION", 4, format["Virtual group %1 moved %2m towards waypoint. Distance remaining: %3m", 
            _groupId, _actualMoveDistance, _distanceToWaypoint - _actualMoveDistance]] call FLO_fnc_log;
    } else {
        // Waypoint reached or non-movement waypoint
        if (_distanceToWaypoint <= 10) then {
            // Handle waypoint completion
            switch (_waypointType) do {
                case "CYCLE": {
                    // For cycle, move the completed waypoint to the end of the array
                    private _completedWaypoint = _waypoints deleteAt _currentWaypointIndex;
                    _waypoints pushBack _completedWaypoint;
                    _groupData set ["waypoints", _waypoints];
                    _groupData set ["currentWaypointIndex", 0];
                    ["VIRTUALIZATION", 3, format["Virtual group %1 cycling waypoints", _groupId]] call FLO_fnc_log;
                };
                case "SENTRY": {
                    // For sentry, keep the waypoint but update last visit time
                    _groupData set ["lastSentryTime", _currentTime];
                    ["VIRTUALIZATION", 3, format["Virtual group %1 holding sentry position", _groupId]] call FLO_fnc_log;
                };
                default {
                    // For all other types, delete the completed waypoint
                    _waypoints deleteAt _currentWaypointIndex;
                    _groupData set ["waypoints", _waypoints];
                    
                    // Check if there are more waypoints
                    if (count _waypoints > 0) then {
                        // If we deleted the current waypoint, keep the same index (it now points to the next waypoint)
                        // Otherwise, the index stays the same
                        _groupData set ["currentWaypointIndex", _currentWaypointIndex min ((count _waypoints) - 1)];
                        ["VIRTUALIZATION", 3, format["Virtual group %1 completed waypoint, moving to next", _groupId]] call FLO_fnc_log;
                    } else {
                        // No more waypoints
                        _groupData set ["state", "idle"];
                        _groupData set ["currentWaypointIndex", 0];
                        ["VIRTUALIZATION", 3, format["Virtual group %1 completed all waypoints", _groupId]] call FLO_fnc_log;
                    };
                };
            };
            
            // Update waypoint visualization
            if (FLO_virtualGroups get "_debugMode") then {
                [_groupId, _waypoints, _groupData get "currentWaypointIndex"] call FLO_fnc_createVirtualWaypointMarkers;
            };
        };
    };
};

// Function to check if a player should be considered for distance calculation
private _isValidPlayerForDistance = {
    params ["_player"];
    private _vehicle = vehicle _player;
    
    // Return false if player is in an aircraft
    if (_vehicle != _player) then {
        if (_vehicle isKindOf "Air") exitWith {
            false
        };
    };
    true
};

// Get nearest player distance, excluding those in aircraft
private _getNearestPlayerDistance = {
    params ["_position"];
    private _nearestDistance = 999999;
    private _allPlayers = allPlayers select {alive _x && side _x == west};
    
    {
        if ([_x] call _isValidPlayerForDistance) then {
            private _distance = _position distance2D _x;
            if (_distance < _nearestDistance) then {
                _nearestDistance = _distance;
            };
        };
    } forEach _allPlayers;
    
    _nearestDistance
};

// Main update loop
while {true} do {
    // Only process if the virtualization system is enabled
    if (!isNil "FLO_virtualGroups" && {FLO_virtualGroups get "_enabled"}) then {
        private _currentTime = diag_tickTime;
        private _groups = FLO_virtualGroups get "_groups";
        private _activationDistance = FLO_virtualGroups getOrDefault ["_activationDistance", 2000];
        
        // Process each virtual group
        {
            private _groupId = _x;
            private _groupData = _y;
            
            if (!isNil "_groupData") then {
                private _isActive = _groupData getOrDefault ["isActive", false];
                private _position = _groupData getOrDefault ["position", [0,0,0]];
                private _realGroup = _groupData getOrDefault ["realGroup", grpNull];
                
                // Process virtual movement for inactive groups
                if (!_isActive) then {
                    [_groupData, _groupId, _currentTime] call _processVirtualMovement;
                    private _updatedPos = _groupData get "position";
                    // Only update if we got a valid position back
                    if (!isNil "_updatedPos" && {_updatedPos isEqualType [] && {count _updatedPos >= 2}}) then {
                        _position = _updatedPos;
                    };

                    // If the group is idle with no waypoints, assign a cycle patrol
                    if ((_groupData getOrDefault ["state", ""] == "idle") && {count (_groupData getOrDefault ["waypoints", []]) == 0} && {!(_groupData getOrDefault ["autoPatrol", false])}) then {
                        // Get garrison position, validating it's a proper position array
                        private _garrisonPos = _groupData getOrDefault ["garrisonPosition", []];
                        private _centerPos = if (_garrisonPos isEqualType [] && {count _garrisonPos >= 2} && {(_garrisonPos select 0) > 0 || (_garrisonPos select 1) > 0}) then {
                            _garrisonPos
                        } else {
                            _position
                        };

                        // Validate center position before creating waypoints
                        if (_centerPos isEqualType [] && {count _centerPos >= 2} && {(_centerPos select 0) > 0 || (_centerPos select 1) > 0}) then {
                            private _radius = 200 + random 200; // Random 200-400m patrol radius
                            private _dirBase = random 360;

                            // Get positions and ensure they're on land (not water)
                            private _pos1 = [_centerPos getPos [_radius, _dirBase], _radius] call FLO_fnc_getSafeLandPos;
                            private _pos2 = [_centerPos getPos [_radius, _dirBase + 120], _radius] call FLO_fnc_getSafeLandPos;
                            private _pos3 = [_centerPos getPos [_radius, _dirBase + 240], _radius] call FLO_fnc_getSafeLandPos;

                            private _wp1 = [_pos1, "MOVE", "SAFE", "NORMAL", "COLUMN", "YELLOW", 20];
                            private _wp2 = [_pos2, "MOVE", "SAFE", "NORMAL", "COLUMN", "YELLOW", 20];
                            private _wp3 = [_pos3, "CYCLE", "SAFE", "NORMAL", "COLUMN", "YELLOW", 20];

                            [_groupId, [_wp1, _wp2, _wp3]] call FLO_fnc_updateVirtualGroupWaypoints;
                            _groupData set ["autoPatrol", true];
                        } else {
                            // Invalid position - skip patrol assignment, will retry next cycle
                            ["VIRTUALIZATION", 2, format ["Group %1 has invalid position for patrol: %2", _groupId, _centerPos]] call FLO_fnc_log;
                        };
                    };
                } else {
                    // Update position from real group if active
                    if (!isNull _realGroup) then {
                        private _leader = leader _realGroup;
                        // Only update if leader exists and is alive
                        if (!isNull _leader && {alive _leader}) then {
                            private _realPos = getPos _leader;
                            // Validate position before saving - don't save bad positions
                            if ((_realPos select 0) > 100 || (_realPos select 1) > 100) then {
                                _groupData set ["position", _realPos];
                                _position = _realPos;

                                // Update debug marker if enabled
                                if (FLO_virtualGroups get "_debugMode") then {
                                    private _marker = format["vgroup_%1", _groupId];
                                    if (getMarkerColor _marker != "") then {
                                        _marker setMarkerPos _realPos;
                                        _marker setMarkerDir getDir _leader;
                                    };
                                };
                            };
                        };
                    };
                };
                
                // Handle activation/deactivation
                private _nearestPlayerDistance = [_position] call _getNearestPlayerDistance;

                // Debug: Log distance checks for active groups periodically
                // if (_isActive && {random 1 < 0.01}) then {
                //     ["VIRTUALIZATION", 4, format["Active group %1: pos=%2, dist=%3m, threshold=%4m",
                //         _groupId, _position, round _nearestPlayerDistance, _activationDistance]] call FLO_fnc_log;
                // };

                if (_nearestPlayerDistance <= _activationDistance && !_isActive) then {
                    ["VIRTUALIZATION", 3, format["Activating virtual group %1 (Distance: %2m)", _groupId, _nearestPlayerDistance]] call FLO_fnc_log;
                    [_groupId, _groupData] call FLO_fnc_activateVirtualGroup;
                } else {
                    if (_nearestPlayerDistance > _activationDistance && _isActive) then {
                        ["VIRTUALIZATION", 3, format["Deactivating virtual group %1 (Distance: %2m)", _groupId, _nearestPlayerDistance]] call FLO_fnc_log;
                        [_groupId, _groupData] call FLO_fnc_deactivateVirtualGroup;
                    };
                };
                
                // Check for eliminated groups
                if (_isActive && !isNull _realGroup) then {
                    private _lastStateChangeTime = _groupData getOrDefault ["lastStateChangeTime", 0];
                    if (_currentTime - _lastStateChangeTime > 5) then {
                        if ({alive _x} count units _realGroup == 0) then {
                            ["VIRTUALIZATION", 3, format["Virtual group %1 eliminated - removing from system", _groupId]] call FLO_fnc_log;
                            [FLO_virtualGroups, _groupId] call (FLO_virtualGroups get "_removeGroup");
                        };
                    };
                };
            };
        } forEach _groups;
    };
    
    // Sleep for a reasonable interval - adjust as needed for performance
    sleep 5;
};

["VIRTUALIZATION", 3, "Virtual groups update loop ended"] call FLO_fnc_log; 