/*
 * Function: FLO_fnc_testPathfindingIntegration
 * Author: Frontline Operations Development Group
 * Description:
 * Tests the integration between the Virtualization system and the Pathfinding module.
 * Creates virtual groups at the player's position and sends them to land positions ~4000m away.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call FLO_fnc_testPathfindingIntegration;
 */

// Make sure both systems are initialized
if (isNil "FLO_virtualGroups") then {
    [2000] call FLO_fnc_initVirtualization;
};

// Enable debug mode to visualize the groups and waypoints
[true] call FLO_fnc_toggleVirtualizationDebug;

// Use player position as the starting point
private _playerPos = getPos player;
private _startPos1 = _playerPos;
private _startPos2 = [(_playerPos#0) + 100, (_playerPos#1) + 100, 0]; // Slightly offset second group

// Function to find a suitable land position ~4000m away
private _findLandPosition = {
    params ["_startPos", "_distance"];
    
    private _direction = random 360; // Random direction from player
    private _initialEndPos = _startPos getPos [_distance, _direction];
    
    // Try to find a position on land
    private _attempts = 0;
    private _endPos = _initialEndPos;
    private _isValidPos = false;
    
    while {!_isValidPos && _attempts < 12} do {
        // Adjust direction and try again
        _direction = (_direction + 30) % 360;
        _endPos = _startPos getPos [_distance, _direction];
        
        // Check if position is on land and not in water
        _isValidPos = !surfaceIsWater _endPos;
        
        // If it's valid, do an additional check to make sure it's not too close to water
        if (_isValidPos) then {
            // Check several points nearby to ensure we're not right at the edge of water
            private _subPositions = [
                _endPos getPos [50, 0],
                _endPos getPos [50, 90],
                _endPos getPos [50, 180],
                _endPos getPos [50, 270]
            ];
            
            {
                if (surfaceIsWater _x) then {
                    _isValidPos = false;
                };
            } forEach _subPositions;
        };
        
        _attempts = _attempts + 1;
    };
    
    // If we couldn't find a valid position after all attempts, use the last attempt but push inland
    if (!_isValidPos) then {
        // Find direction toward center of map to increase chance of moving inland
        private _centerDir = _endPos getDir [worldSize/2, worldSize/2];
        _endPos = _endPos getPos [500, _centerDir];
        
        // Log the fallback
        systemChat "Couldn't find ideal position, using fallback position";
        diag_log "[FLO] Pathfinding test: Using fallback destination position";
    };
    
    _endPos
};

// Find suitable end positions ~4000m away on land
private _endPos1 = [_startPos1, 4000] call _findLandPosition;
private _endPos2 = [_startPos2, 4000] call _findLandPosition;

// Create markers for start and end positions (for visualization)
{
    private _marker = createMarker [format["test_marker_%1", _forEachIndex], _x];
    _marker setMarkerType "mil_dot";
    _marker setMarkerColor "ColorBlue";
    _marker setMarkerText format["Test Pos %1", _forEachIndex + 1];
} forEach [_startPos1, _endPos1, _startPos2, _endPos2];

// Create a virtual infantry group
private _infantryGroupId = [_startPos1, "infantry", nil, nil] call FLO_fnc_createVirtualGroup;
diag_log format["Created virtual infantry group: %1", _infantryGroupId];

// Create a virtual motorized group
private _motorizedGroupId = [_startPos2, "motorized", nil, nil] call FLO_fnc_createVirtualGroup;
diag_log format["Created virtual motorized group: %1", _motorizedGroupId];

// Send the infantry group to its destination using pathfinding (with trails allowed)
[_infantryGroupId, [[_endPos1, "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"]], true, true] call FLO_fnc_updateVirtualGroupWaypoints;
systemChat format["Sent infantry group to position %1 using pathfinding (with trails)", _endPos1];
diag_log format["Sent infantry group %1 to destination using pathfinding (with trails)", _infantryGroupId];

// Send the motorized group to its destination using pathfinding (no trails)
[_motorizedGroupId, [[_endPos2, "MOVE", "AWARE", "FULL", "COLUMN", "YELLOW"]], true, false] call FLO_fnc_updateVirtualGroupWaypoints;
systemChat format["Sent motorized group to position %1 using pathfinding (no trails)", _endPos2];
diag_log format["Sent motorized group %1 to destination using pathfinding (no trails)", _motorizedGroupId];

// Output message to chat
systemChat "Virtual groups created and waypoints set. Check the map for visualization.";
diag_log "[FLO] Virtualization-Pathfinding integration test started. Check the map for visualization.";

// Return nothing
nil 