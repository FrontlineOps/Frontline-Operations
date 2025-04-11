/*
 * Function: FLO_fnc_updateVirtualGroupWaypoints
 * Author: Frontline Operations Development Group
 * Description:
 * Updates the waypoints for a virtual group. If the group is active, updates its real waypoints.
 * If inactive, stores the waypoints for virtual movement processing.
 * Now supports pathfinding integration for road-based movement.
 *
 * Arguments:
 * 0: Group ID <STRING> - Unique identifier for the virtual group
 * 1: Waypoints <ARRAY> - Array of waypoint data in format:
 *   Each waypoint is an array: [position, type, behavior, speed, formation, combat mode]
 * 2: (Optional) Use Road Pathfinding <BOOLEAN> - Whether to use road pathfinding (Default: false)
 * 3: (Optional) Allow Trails <BOOLEAN> - Whether to allow trails for pathfinding (Default: false)
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * ["vgroup_1", [[getMarkerPos "marker_1", "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"]]] call FLO_fnc_updateVirtualGroupWaypoints;
 * ["vgroup_1", [[getMarkerPos "marker_1", "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"]], true] call FLO_fnc_updateVirtualGroupWaypoints;
 */

params [
    "_groupId",
    "_waypoints",
    ["_usePathfinding", false, [true]],
    ["_allowTrails", false, [true]]
];

// Ensure virtualization system is initialized
if (isNil "FLO_virtualGroups") exitWith {
    ["VIRTUALIZATION", 1, "Cannot update waypoints - virtualization system not initialized"] call FLO_fnc_log;
    false
};

// Get the group data
private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
if (_groupData isEqualTo createHashMap) exitWith {
    ["VIRTUALIZATION", 2, format["Cannot update waypoints - virtual group %1 not found", _groupId]] call FLO_fnc_log;
    false
};

// Get the current position of the group
private _currentPos = _groupData get "position";

// If no waypoints or using direct assignment (no pathfinding)
if (count _waypoints == 0 || !_usePathfinding) then {
    // Store the waypoints and initialize tracking for both virtual and physical movement
    _groupData set ["waypoints", _waypoints];

    // Add or update virtual waypoint data
    if (count _waypoints > 0) then {
        // Set group state to moving
        _groupData set ["state", "moving"];
        
        // Initialize virtual waypoint tracking
        _groupData set ["currentWaypointIndex", 0];
        _groupData set ["lastMoveTime", diag_tickTime];
        
        // Calculate speed in meters per second based on waypoint speed setting
        private _wpSpeed = (_waypoints select 0) select 3;
        private _speedMPS = switch (_wpSpeed) do {
            case "LIMITED": { 2 }; // ~7 km/h
            case "NORMAL": { 4 }; // ~14 km/h
            case "FULL": { 8 }; // ~29 km/h
            default { 4 };
        };
        
        // Adjust speed based on group type
        private _groupType = _groupData get "groupType";
        private _speedMultiplier = switch (_groupType) do {
            case "infantry": { 1.0 };
            case "motorized": { 2.5 };
            case "mechanized": { 2.0 };
            case "armor": { 1.8 };
            case "helicopter";
            case "air": { 6.0 };
            case "jet": { 10.0 };
            default { 1.0 };
        };
        
        _groupData set ["virtualSpeed", _speedMPS * _speedMultiplier];
        
        // Create or update waypoint visualization in debug mode
        if (FLO_virtualGroups get "_debugMode") then {
            [_groupId, _waypoints, 0] call FLO_fnc_createVirtualWaypointMarkers;
        };
        
        ["VIRTUALIZATION", 3, format["Set up virtual movement for group %1 (Speed: %2 m/s)", 
            _groupId, _speedMPS * _speedMultiplier]] call FLO_fnc_log;
    };

    // If the group is active, update its real waypoints too
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
            
            // Update marker if debug mode is on
            if (FLO_virtualGroups get "_debugMode") then {
                [_groupId, _groupData] call FLO_fnc_createVirtualGroupMarker;
            };
        };
    };
} else {
    // Using pathfinding - we'll need to temporarily store the waypoint settings
    // Store only the first waypoint settings temporarily (we'll apply them to all generated waypoints)
    if (count _waypoints > 0) then {
        private _firstWaypoint = _waypoints select 0;
        private _endPos = _firstWaypoint select 0;
        
        // Temporary storage for waypoint settings
        _groupData set ["tempWaypointSettings", _firstWaypoint];
        _groupData set ["tempWaypointCount", 0];
        
        // Create a callback function using compileFinal
        private _callbackCode = compileFinal {
            params ["_status", "_posArray", "_args"];
            _args params ["_groupId","_waypointSettings"];
            
            if (!_status) exitWith {
                ["VIRTUALIZATION", 2, format["Pathfinding failed for group %1", _groupId]] call FLO_fnc_log;
                // Call fallback function
                [false, _posArray, _args] call FLO_fnc_pathfindingFallbackCode;
            };
            
            // Extract waypoint settings
            private _wpType = _waypointSettings select 1;
            private _wpBehavior = _waypointSettings select 2;
            private _wpSpeed = _waypointSettings select 3;
            private _wpFormation = _waypointSettings select 4;
            private _wpMode = _waypointSettings select 5;
            
            // Create new waypoints array
            private _newWaypoints = [];
            {
                _newWaypoints pushBack [_x, _wpType, _wpBehavior, _wpSpeed, _wpFormation, _wpMode];
            } forEach _posArray;
            
            // Update the virtual group with the new waypoints
            private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
            if (_groupData isEqualTo createHashMap) exitWith {
                ["VIRTUALIZATION", 2, format["Group %1 not found after pathfinding completed", _groupId]] call FLO_fnc_log;
            };
            
            // Store the waypoints
            _groupData set ["waypoints", _newWaypoints];
            _groupData set ["tempWaypointCount", count _newWaypoints];
            
            // Set group state to moving
            _groupData set ["state", "moving"];
            
            // Initialize virtual waypoint tracking
            _groupData set ["currentWaypointIndex", 0];
            _groupData set ["lastMoveTime", diag_tickTime];
            
            // Calculate speed in meters per second based on waypoint speed setting
            private _speedMPS = switch (_wpSpeed) do {
                case "LIMITED": { 2 }; // ~7 km/h
                case "NORMAL": { 4 }; // ~14 km/h
                case "FULL": { 8 }; // ~29 km/h
                default { 4 };
            };
            
            // Adjust speed based on group type
            private _groupType = _groupData get "groupType";
            private _speedMultiplier = switch (_groupType) do {
                case "infantry": { 1.0 };
                case "motorized": { 2.5 };
                case "mechanized": { 2.0 };
                case "armor": { 1.8 };
                case "helicopter";
                case "air": { 6.0 };
                case "jet": { 10.0 };
                default { 1.0 };
            };
            
            _groupData set ["virtualSpeed", _speedMPS * _speedMultiplier];
            
            // Create or update waypoint visualization in debug mode
            if (FLO_virtualGroups get "_debugMode") then {
                [_groupId, _newWaypoints, 0] call FLO_fnc_createVirtualWaypointMarkers;
            };
            
            ["VIRTUALIZATION", 3, format["Pathfinding completed for group %1 with %2 waypoints", _groupId, count _newWaypoints]] call FLO_fnc_log;
            
            // If the group is active, update its real waypoints too
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
                        
                        private _wp = _realGroup addWaypoint [_wpPos, 0];
                        _wp setWaypointType _wpType;
                        _wp setWaypointBehaviour _wpBehavior;
                        _wp setWaypointSpeed _wpSpeed;
                        _wp setWaypointFormation _wpFormation;
                        _wp setWaypointCombatMode _wpMode;
                    } forEach _newWaypoints;
                    
                    // Update marker if debug mode is on
                    if (FLO_virtualGroups get "_debugMode") then {
                        [_groupId, _groupData] call FLO_fnc_createVirtualGroupMarker;
                    };
                };
            };
        };
        
        // Define the fallback function
        FLO_fnc_pathfindingFallbackCode = compileFinal {
            params ["_status", "_posArray", "_args"];
            _args params [_groupId,_originalWaypoint];
            
            ["VIRTUALIZATION", 2, format["Pathfinding failed for group %1, falling back to direct waypoint", _groupId]] call FLO_fnc_log;
            
            // Get the group data again
            private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
            if (_groupData isEqualTo createHashMap) exitWith {};
            
            // Create a single direct waypoint
            private _directWaypoints = [_originalWaypoint];
            _groupData set ["waypoints", _directWaypoints];
            
            // Set group state to moving
            _groupData set ["state", "moving"];
            _groupData set ["currentWaypointIndex", 0];
            _groupData set ["lastMoveTime", diag_tickTime];
            
            // If the group is active, update its real waypoints
            if (_groupData getOrDefault ["isActive", false]) then {
                private _realGroup = _groupData getOrDefault ["realGroup", grpNull];
                if (!isNull _realGroup) then {
                    // Clear existing waypoints
                    while {count waypoints _realGroup > 0} do {
                        deleteWaypoint [_realGroup, 0];
                    };
                    
                    // Add direct waypoint
                    private _wpPos = _originalWaypoint select 0;
                    private _wpType = _originalWaypoint select 1;
                    private _wpBehavior = _originalWaypoint select 2;
                    private _wpSpeed = _originalWaypoint select 3;
                    private _wpFormation = _originalWaypoint select 4;
                    private _wpMode = _originalWaypoint select 5;
                    
                    private _wp = _realGroup addWaypoint [_wpPos, 0];
                    _wp setWaypointType _wpType;
                    _wp setWaypointBehaviour _wpBehavior;
                    _wp setWaypointSpeed _wpSpeed;
                    _wp setWaypointFormation _wpFormation;
                    _wp setWaypointCombatMode _wpMode;
                };
            };
        };
        
        // Start the pathfinding process
        ["VIRTUALIZATION", 3, format["Starting pathfinding for group %1 from %2 to %3", _groupId, _currentPos, _endPos]] call FLO_fnc_log;
        [_currentPos, _endPos, _callbackCode, [_groupId, _firstWaypoint], _allowTrails] call FLO_fnc_findRoadPath;
    };
};

// Log the update
["VIRTUALIZATION", 3, format["Updated waypoints for virtual group %1", _groupId]] call FLO_fnc_log;

// Return success
true 