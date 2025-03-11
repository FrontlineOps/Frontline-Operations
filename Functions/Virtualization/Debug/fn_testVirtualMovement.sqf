/*
 * Function: FLO_fnc_testVirtualMovement
 * Author: Frontline Operations Development Group
 * Description:
 * Debug function to test virtual movement system.
 * Creates a virtual group with waypoints and enables debug visualization.
 * 
 * Arguments:
 * 0: Group Type <STRING> - Type of group to create (Optional, default: "infantry")
 * 1: Start Position <ARRAY/OBJECT> - Position to start or object to use position from (Optional, default: player position)
 * 2: Pattern <STRING> - Movement pattern ("circle", "square", "backforth") (Optional, default: "circle")
 * 3: Size <NUMBER> - Size of the movement pattern in meters (Optional, default: 500)
 * 
 * Return Value:
 * Group ID of created virtual group <STRING>
 * 
 * Example (Debug Console):
 * _groupId = ["infantry", player, "circle", 500] call FLO_fnc_testVirtualMovement;
 */

params [
    ["_groupType", "infantry", [""]],
    ["_startPos", objNull, [objNull, []]],
    ["_pattern", "circle", [""]],
    ["_patternSize", 500, [0]]
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

// Create the virtual group
private _groupId = [_startPos, _groupType] call FLO_fnc_createVirtualGroup;
private _groupData = (FLO_virtualGroups get "_groups") getOrDefault [_groupId, createHashMap];

// Log creation
systemChat format["Created test virtual group: %1 (Type: %2)", _groupId, _groupType];
["VIRTUALIZATION", 3, format["Created test virtual group: %1 at %2", _groupId, _startPos]] call FLO_fnc_log;

// Generate waypoints based on pattern
private _waypoints = [];
private _centerPos = [(_startPos select 0) + _patternSize/2, (_startPos select 1) + _patternSize/2, 0];

// Calculate waypoints based on selected pattern
switch (_pattern) do {
    case "circle": {
        // Create waypoints in a circle
        for "_i" from 0 to 7 do {
            private _angle = _i * 45;
            private _wpPos = [
                (_centerPos select 0) + (sin _angle * (_patternSize/2)), 
                (_centerPos select 1) + (cos _angle * (_patternSize/2)),
                0
            ];
            _waypoints pushBack [_wpPos, "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"];
        };
    };
    
    case "square": {
        // Create waypoints in a square
        _waypoints = [
            [[(_startPos select 0), (_startPos select 1) + _patternSize, 0], "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"],
            [[(_startPos select 0) + _patternSize, (_startPos select 1) + _patternSize, 0], "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"],
            [[(_startPos select 0) + _patternSize, (_startPos select 1), 0], "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"],
            [[(_startPos select 0), (_startPos select 1), 0], "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"]
        ];
    };
    
    case "backforth": {
        // Create back and forth waypoints
        _waypoints = [
            [[(_startPos select 0) + _patternSize, (_startPos select 1), 0], "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"],
            [[(_startPos select 0), (_startPos select 1), 0], "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"]
        ];
    };
    
    default {
        // Default to a simple line if pattern not recognized
        _waypoints = [
            [[(_startPos select 0) + _patternSize, (_startPos select 1), 0], "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"]
        ];
    };
};

// Assign waypoints to the group
[_groupId, _waypoints] call FLO_fnc_updateVirtualGroupWaypoints;

// Log information to system chat for feedback
systemChat format["Created %1 pattern waypoints for group %2 (size: %3m)", _pattern, _groupId, _patternSize];
systemChat "Debug visualization enabled. Virtual unit will start moving.";

// Return the group ID for further manipulation if needed
_groupId 