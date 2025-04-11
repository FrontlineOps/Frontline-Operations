/*
 * Function: FLO_fnc_testVirtualMovementAdvanced
 * Author: Frontline Operations Development Group
 * Description:
 * Advanced debug function to test virtual movement system with multiple group types.
 * Creates several virtual groups with different patterns and speeds.
 * 
 * Arguments:
 * 0: Start Position <ARRAY/OBJECT> - Position to start or object to use position from (Optional, default: player position)
 * 1: Size <NUMBER> - Size of the movement patterns in meters (Optional, default: 1000)
 * 
 * Return Value:
 * Array of created group IDs <ARRAY>
 * 
 * Example (Debug Console):
 * _groupIds = [player, 1000] call FLO_fnc_testVirtualMovementAdvanced;
 */

params [
    ["_startPos", objNull, [objNull, []]],
    ["_patternSize", 1000, [0]]
];

// Convert object to position if needed
if (_startPos isEqualType objNull) then {
    if (isNull _startPos) then {
        _startPos = getPos player;
    } else {
        _startPos = getPos _startPos;
    }
};

// Initialize virtualization system if needed
if (isNil "FLO_virtualGroups") then {
    [2000] call FLO_fnc_initVirtualization;
};

// Enable debug mode
[FLO_virtualGroups, true] call (FLO_virtualGroups get "_setDebugMode");

// Array to store created group IDs
private _groupIds = [];

// Test configurations - different group types with different patterns
private _testConfigs = [
    // Infantry on a circle pattern
    ["infantry", "circle", _patternSize * 0.4],
    
    // Motorized on a square pattern
    ["motorized", "square", _patternSize * 0.6],
    
    // Mechanized on back and forth pattern
    ["mechanized", "backforth", _patternSize * 0.8],
    
    // Armor on a different circle
    ["armor", "circle", _patternSize * 0.7],
    
    // Helicopter with a larger circle
    ["helicopter", "circle", _patternSize]
];

// Offset patterns slightly so they don't all start from the same point
private _offsetX = 0;
private _offsetY = 0;

{
    _x params ["_groupType", "_pattern", "_size"];
    
    // Calculate slight offset for each group
    private _groupStartPos = [
        (_startPos select 0) + _offsetX,
        (_startPos select 1) + _offsetY,
        0
    ];
    
    // Create the group with this pattern
    private _groupId = [_groupType, _groupStartPos, _pattern, _size] call FLO_fnc_testVirtualMovement;
    _groupIds pushBack _groupId;
    
    // Update offset for next group
    _offsetX = _offsetX + 100;
    _offsetY = _offsetY + 100;
    
} forEach _testConfigs;

// Log overall status
systemChat format["Created %1 test groups with various movement patterns", count _groupIds];
["VIRTUALIZATION", 3, format["Created %1 test groups with various movement patterns", count _groupIds]] call FLO_fnc_log;

// Return array of created group IDs
_groupIds 