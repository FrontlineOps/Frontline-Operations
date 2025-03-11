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
        private _allPlayers = allPlayers select {alive _x && side _x == west};
        
        // Process each virtual group
        {
            private _groupId = _x;
            private _groupData = _y;
            private _position = _groupData getOrDefault ["position", [0,0,0]];
            private _isActive = _groupData getOrDefault ["isActive", false];
            private _realGroup = _groupData getOrDefault ["realGroup", grpNull];
            
            // Process virtual movement for inactive groups that have waypoints
            if (!_isActive) then {
                private _waypoints = _groupData getOrDefault ["waypoints", []];
                private _currentWaypointIndex = _groupData getOrDefault ["currentWaypointIndex", -1];
                
                // Only process if the group has waypoints and a valid current waypoint
                if (count _waypoints > 0 && _currentWaypointIndex >= 0 && _currentWaypointIndex < count _waypoints) then {
                    private _lastMoveTime = _groupData getOrDefault ["lastMoveTime", _currentTime];
                    private _timeSinceLastMove = _currentTime - _lastMoveTime;
                    private _virtualSpeed = _groupData getOrDefault ["virtualSpeed", 4]; // meters per second
                    
                    // Get current waypoint data
                    private _currentWaypoint = _waypoints select _currentWaypointIndex;
                    private _waypointPos = _currentWaypoint select 0;
                    private _waypointType = _currentWaypoint select 1;
                    
                    // Skip if waypoint is not a movement waypoint
                    if (_waypointType in ["MOVE", "SEEK", "SAD", "ATTACK", "PATROL"]) then {
                        // Calculate distance to waypoint
                        private _distanceToWaypoint = _position distance _waypointPos;
                        
                        // If we're not at the waypoint yet, move toward it
                        if (_distanceToWaypoint > 5) then {
                            // Calculate distance to move this update
                            private _distanceToMove = _virtualSpeed * _timeSinceLastMove;
                            _distanceToMove = _distanceToMove min _distanceToWaypoint; // Don't overshoot
                            
                            // Calculate new position
                            private _direction = [_position, _waypointPos] call BIS_fnc_dirTo;
                            private _newX = (_position select 0) + (sin _direction * _distanceToMove);
                            private _newY = (_position select 1) + (cos _direction * _distanceToMove);
                            private _newZ = getTerrainHeightASL [_newX, _newY];
                            private _newPosition = [_newX, _newY, 0];
                            
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
                            
                            // For debugging - uncommenting this will flood logs
                            // ["VIRTUALIZATION", 4, format["Virtual group %1 moved to %2 (dist to WP: %3m)", 
                            //    _groupId, _newPosition, _distanceToWaypoint - _distanceToMove]] call FLO_fnc_log;
                        } else {
                            // We've reached the waypoint, move to next one if available
                            _currentWaypointIndex = _currentWaypointIndex + 1;
                            
                            // If we've reached the last waypoint, either cycle or stop
                            if (_currentWaypointIndex >= count _waypoints) then {
                                // For now, just cycle back to the first waypoint for continuous movement
                                // Could be expanded with different behaviors based on mission needs
                                _currentWaypointIndex = 0;
                                _groupData set ["state", "idle"];
                                
                                ["VIRTUALIZATION", 3, format["Virtual group %1 completed all waypoints - cycling back", _groupId]] call FLO_fnc_log;
                            } else {
                                ["VIRTUALIZATION", 3, format["Virtual group %1 reached waypoint %2, moving to next", 
                                    _groupId, _currentWaypointIndex-1]] call FLO_fnc_log;
                            };
                            
                            _groupData set ["currentWaypointIndex", _currentWaypointIndex];
                            
                            // Update waypoint visualization in debug mode
                            if (FLO_virtualGroups get "_debugMode") then {
                                [_groupId, _waypoints, _currentWaypointIndex] call FLO_fnc_createVirtualWaypointMarkers;
                            };
                        };
                    };
                };
            };
            
            // Update _position after potential virtual movement
            _position = _groupData getOrDefault ["position", [0,0,0]];
            
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
                // Check if the group has been eliminated
                if ({alive _x} count units _realGroup == 0) then {
                    // Removed dead group
                    [FLO_virtualGroups, _groupId] call (FLO_virtualGroups get "_removeGroup");
                };
            };
        } forEach _groups;
    };
    
    // Sleep for a reasonable interval - adjust as needed for performance
    sleep 5;
};

["VIRTUALIZATION", 3, "Virtual groups update loop ended"] call FLO_fnc_log; 