/*
 * Function: FLO_fnc_virtualGroupsUpdateLoop
 * Author: Frontline Operations Development Group
 * Description:
 * Update loop for the virtualization system. Checks distances to players and activates/deactivates groups.
 * Also processes movement for virtual groups along their assigned waypoints.
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

["VIRTUALIZATION", 3, "Starting virtual groups update loop"] call FLO_fnc_log;

// Main update loop
while {true} do {
    // Only process if the virtualization system is enabled
    if (!isNil "FLO_virtualGroups" && {FLO_virtualGroups get "_enabled"}) then {
        private _activationDistance = FLO_virtualGroups get "_activationDistance";
        private _groups = FLO_virtualGroups get "_groups";
        private _currentTime = diag_tickTime;
        
        // Get all players
        private _allPlayers = allPlayers select {alive _x && side _x isEqualTo west};
        
        // Process each virtual group
        {
            private _groupId = _x;
            private _groupData = _y;
            private _position = _groupData get "position";
            private _isActive = _groupData get "isActive";
            private _realGroup = _groupData get "realGroup";
            
            // Skip if the group is already active
            if (!_isActive) then {
                // Process virtual waypoints for inactive groups
                private _waypoints = _groupData get "waypoints";
                private _currentWaypointIndex = _groupData getOrDefault ["currentWaypointIndex", -1];
                
                // Only process if the group has waypoints and a valid current waypoint
                if (count _waypoints > 0 && _currentWaypointIndex >= 0 && _currentWaypointIndex < count _waypoints) then {
                    private _lastMoveTime = _groupData get "lastMoveTime";
                    private _timeSinceLastMove = _currentTime - _lastMoveTime;
                    private _virtualSpeed = _groupData get "virtualSpeed"; // meters per second
                    
                    // If this is the first time processing waypoints for this group, initialize lastMoveTime
                    if (_lastMoveTime isEqualTo _currentTime) then {
                        _groupData set ["lastMoveTime", _currentTime];
                        _timeSinceLastMove = 0;
                    };
                    
                    // Get current waypoint data
                    private _currentWaypoint = _waypoints select _currentWaypointIndex;
                    private _waypointPos = _currentWaypoint select 0;
                    private _waypointType = _currentWaypoint select 1;
                    
                    // Skip if waypoint is not a movement waypoint
                    if (_waypointType in ["MOVE", "LOITER", "SAD", "SENTRY", "CYCLE"]) then {
                        // Calculate distance to waypoint (2D distance to avoid height issues)
                        private _distanceToWaypoint = _position distance2D _waypointPos;
                        private _completeWaypoint = false;
                        
                        // Debug log for stuck groups
                        if (FLO_virtualGroups get "_debugMode") then {
                            ["VIRTUALIZATION", 4, format["Virtual group %1 distance to waypoint: %2m", _groupId, _distanceToWaypoint]] call FLO_fnc_log;
                        };
                        
                        // If we're not at the waypoint yet, move toward it
                        if (_distanceToWaypoint > 10) then {
                            // Calculate distance to move this update
                            private _distanceToMove = _virtualSpeed * _timeSinceLastMove;
                            
                            // Debug log for movement
                            if (FLO_virtualGroups get "_debugMode") then {
                                ["VIRTUALIZATION", 4, format["Virtual group %1 calculating move distance: %2m", _groupId, _distanceToMove]] call FLO_fnc_log;
                            };
                            
                            // Check if we would overshoot the waypoint
                            private _newPosition = [];
                            if (_distanceToMove >= _distanceToWaypoint) then {
                                // Would overshoot, so place directly at the waypoint
                                _newPosition = _waypointPos;
                                ["VIRTUALIZATION", 3, format["Virtual group %1 would overshoot waypoint, placing directly at position", _groupId]] call FLO_fnc_log;
                                _completeWaypoint = true;
                            } else {
                                // Calculate new position based on direction and distance
                                private _direction = [_position, _waypointPos] call BIS_fnc_dirTo;
                                private _newX = (_position select 0) + (sin _direction * _distanceToMove);
                                private _newY = (_position select 1) + (cos _direction * _distanceToMove);
                                _newPosition = [_newX, _newY, 0];
                                
                                // After calculating the new position, check if we'd cross/pass the waypoint
                                private _newDistanceToWaypoint = _newPosition distance2D _waypointPos;
                                if (_newDistanceToWaypoint > _distanceToWaypoint) then {
                                    // We're getting farther away, which means we probably passed it
                                    _newPosition = _waypointPos;
                                    ["VIRTUALIZATION", 3, format["Virtual group %1 would pass waypoint, placing directly at position", _groupId]] call FLO_fnc_log;
                                    _completeWaypoint = true;
                                };
                            };
                            
                            // Update group position
                            _groupData set ["position", _newPosition];
                            _groupData set ["lastMoveTime", _currentTime];
                            
                            // Update marker if debug mode is enabled
                            if (FLO_virtualGroups get "_debugMode") then {
                                private _marker = format["vgroup_%1", _groupId];
                                if (getMarkerColor _marker != "") then {
                                    _marker setMarkerPos _newPosition;
                                };
                            };
                            
                            // Check if we're now close enough to complete the waypoint
                            if (!_completeWaypoint) then {
                                private _newDistanceToWaypoint = _newPosition distance2D _waypointPos;
                                if (_newDistanceToWaypoint <= 10) then {
                                    ["VIRTUALIZATION", 3, format["Virtual group %1 now close enough to waypoint (%2m), completing", _groupId, _newDistanceToWaypoint]] call FLO_fnc_log;
                                    // Place group directly at waypoint position
                                    _groupData set ["position", _waypointPos];
                                    _completeWaypoint = true;
                                };
                            };
                        } else {
                            // We've reached the waypoint
                            ["VIRTUALIZATION", 3, format["Virtual group %1 reached waypoint at position %2", 
                                _groupId, _waypointPos]] call FLO_fnc_log;
                            
                            _completeWaypoint = true;
                        };
                        
                        // Process waypoint completion if flagged
                        if (_completeWaypoint) then {
                            // Delete the completed waypoint
                            _waypoints deleteAt _currentWaypointIndex;
                            _groupData set ["waypoints", _waypoints];
                            
                            // If no more waypoints, set to idle
                            if (count _waypoints == 0) then {
                                _groupData set ["state", "idle"];
                                _groupData set ["currentWaypointIndex", -1];
                                
                                ["VIRTUALIZATION", 3, format["Virtual group %1 completed all waypoints", _groupId]] call FLO_fnc_log;
                            } else {
                                // If the waypoint type was CYCLE, cycle back to the first waypoint
                                if (_waypointType == "CYCLE" && count _waypoints > 0) then {
                                    _currentWaypointIndex = 0;
                                    ["VIRTUALIZATION", 3, format["Virtual group %1 cycling waypoints", _groupId]] call FLO_fnc_log;
                                } else {
                                    // Keep the index at 0 to process the next waypoint in line
                                    _currentWaypointIndex = 0;
                                    ["VIRTUALIZATION", 3, format["Virtual group %1 moving to next waypoint", _groupId]] call FLO_fnc_log;
                                };
                                
                                _groupData set ["currentWaypointIndex", _currentWaypointIndex];
                            };
                            
                            // Update waypoint visualization in debug mode
                            if (FLO_virtualGroups get "_debugMode") then {
                                [_groupId, _waypoints, _currentWaypointIndex] call FLO_fnc_createVirtualWaypointMarkers;
                            };
                        };
                    };
                };
            };
            
            // Update _position after potential virtual movement
            _position = _groupData get "position";
            
            // Check if any player is within activation distance
            private _shouldActivate = false;
            {
                if (_position distance _x < _activationDistance) exitWith {
                    _shouldActivate = true;
                };
            } forEach _allPlayers;
            
            // Activate or deactivate group based on distance
            if (_shouldActivate && !_isActive) then {
                [_groupId, _groupData] call FLO_fnc_activateVirtualGroup;
            } else {
                if (!_shouldActivate && _isActive) then {
                    [_groupId, _groupData] call FLO_fnc_deactivateVirtualGroup;
                };
            };
            
            // If the group is active and has a real group that's been killed, remove it from the system
            if (_isActive && !isNull _realGroup) then {
                // Add a transition protection - don't check for elimination right after state changes
                private _lastStateChangeTime = _groupData getOrDefault ["lastStateChangeTime", 0];
                private _timeSinceStateChange = _currentTime - _lastStateChangeTime;
                
                // Only check for elimination if we're not in a transition period (5 seconds grace period)
                if (_timeSinceStateChange > 5) then {
                    // Check if the group has been eliminated
                    if ({alive _x} count units _realGroup isEqualTo 0) then {
                        ["VIRTUALIZATION", 3, format["Virtual group %1 has been eliminated - removing from system", _groupId]] call FLO_fnc_log;
                        // Remove dead group
                        [FLO_virtualGroups, _groupId] call (FLO_virtualGroups get "_removeGroup");
                    };
                };
            };
        } forEach _groups;
    };
    
    // Sleep for a reasonable interval - adjust as needed for performance
    sleep 5;
};

["VIRTUALIZATION", 3, "Virtual groups update loop ended"] call FLO_fnc_log; 