/*
    Function: FLO_fnc_TaskForceSystem
    
    Description:
    Manages OPFOR Task Forces that move across the map and appear when near BLUFOR.
    Fully compatible with CDVS Virtualization system.
    Allows creation of defensive lines with fortifications, infantry, and vehicles.
    
    Parameters:
    _mode - The function mode to execute ["init", "createTaskForce", "updateTaskForces", "getTaskForce", "deployTaskForce"] (String)
    _params - Parameters based on mode (Array)
        init: [] - Initialize the Task Force system
        createTaskForce: [_baseMarker, _taskForceType, _taskForceSize, _targetMarker] - Create a new Task Force
        updateTaskForces: [] - Update all Task Forces positions and statuses
        getTaskForce: [_taskForceId] - Get information about a specific Task Force
        deployTaskForce: [_taskForceId, _position, _defensive] - Deploy a Task Force at a specific position
    
    Returns:
    Based on mode:
        init: HashMapObject - The Task Force system object
        createTaskForce: String - The ID of the created Task Force
        updateTaskForces: Nothing
        getTaskForce: Array - Information about the Task Force
        deployTaskForce: Boolean - True if successfully deployed
*/

if (!isServer) exitWith {};

// Global backup variable for task forces to prevent synchronization issues
if (isNil "FLO_Global_TaskForces") then {
    FLO_Global_TaskForces = createHashMap;
};

params [
    ["_mode", "", [""]],
    ["_params", [], [[]]]
];

private _result = false;

// Initialize the Task Force System object if it doesn't exist
if (isNil "FLO_TaskForce_System") then {
    // Define the Task Force System class with its methods and properties
    private _taskForceSystemClass = [
        // Class identifier
        ["#type", "TaskForceSystem"],
        
        // Properties
        ["taskForces", createHashMap],
        ["lastUpdate", time],
        ["lastTaskForceId", 0],
        ["lastTaskForceScan", time],
        
        // Constructor - Called when object is created
        ["#create", {
            _self set ["taskForces", createHashMap];
            _self set ["lastUpdate", time];
            _self set ["lastTaskForceId", 0];
            _self set ["lastTaskForceScan", time];
            diag_log "[FLO][TaskForce] System initialized";
        }],
        
        // Initialize Task Force system and start update loop
        ["initialize", {
            // Initialize the VS_VirtualizedTaskForces hashmap if it doesn't exist
            if (isNil "VS_VirtualizedTaskForces") then {
                VS_VirtualizedTaskForces = createHashMap;
            };
            
            // Start the update loop for Task Force movement
            [] spawn {
                while {true} do {
                    // Update Task Forces every 30 seconds
                    ["updateTaskForces", []] call FLO_fnc_TaskForceSystem;
                    sleep 30;
                };
            };
        }],
        
        // Create a new Task Force with specified parameters
        ["createTaskForce", {
            params [
                ["_baseMarker", "", [""]],
                ["_taskForceType", "infantry", [""]],
                ["_taskForceSize", "squad", [""]],
                ["_targetMarker", "", [""]]
            ];
            
            // Validate base marker
            if (_baseMarker == "") exitWith {
                diag_log "[FLO][TaskForce] Error: Empty base marker name";
                ""
            };
            
            private _basePos = getMarkerPos _baseMarker;
            if (_basePos isEqualTo [0,0,0]) exitWith {
                diag_log "[FLO][TaskForce] Error: Invalid base marker position";
                ""
            };
            
            // Get target position (can be empty for defensive Task Forces)
            private _targetPos = [0,0,0];
            if (_targetMarker != "") then {
                _targetPos = getMarkerPos _targetMarker;
            };
            
            // Generate a unique ID for this Task Force
            private _lastId = _self getOrDefault ["lastTaskForceId", 0];
            private _taskForceId = format ["TF_%1_%2", _lastId + 1, floor random 10000];
            _self set ["lastTaskForceId", _lastId + 1];
            
            // Calculate resource cost based on type and size
            private _resourceCost = [_taskForceType, _taskForceSize] call {
                params ["_type", "_size"];
                
                private _typeCost = switch (toLower _type) do {
                    case "infantry": {5};
                    case "mechanized": {15};
                    case "armored": {25};
                    case "fortification": {10};
                    default {5};
                };
                
                private _sizeCost = switch (toLower _size) do {
                    case "fireteam": {1};
                    case "squad": {5};
                    case "platoon": {15};
                    case "company": {30};
                    default {5};
                };
                
                _typeCost * _sizeCost
            };
            
            // Check if we have enough resources to create this Task Force
            private _currentResources = ["get", []] call FLO_fnc_opforResources;
            if (_currentResources < _resourceCost) exitWith {
                diag_log format ["[FLO][TaskForce] Error: Insufficient resources to create Task Force (needed %1, have %2)",
                    _resourceCost, _currentResources];
                ""
            };
            
            // Spend the resources
            ["spend", [_resourceCost]] call FLO_fnc_opforResources;
            
            // Define the Task Force composition based on type and size
            private _composition = [_taskForceType, _taskForceSize] call {
                params ["_type", "_size"];
                
                // Define size multipliers
                private _sizeMultiplier = switch (toLower _size) do {
                    case "fireteam": {1};
                    case "squad": {1.25};
                    case "platoon": {1.5};
                    case "company": {2};
                    default {1}; // Default to squad size
                };
                
                // Define base compositions per type
                private _baseComposition = switch (toLower _type) do {
                    case "infantry": {
                        [
                            ["infantry", East_Units, 5 * _sizeMultiplier]
                        ]
                    };
                    case "mechanized": {
                        // 15% chance to add a fire observer to mechanized units
                        if (random 1 < 0.15) then {
                            [
                                ["infantry", East_Units, 4 * _sizeMultiplier],
                                ["vehicle", East_Ground_Vehicles_Light, 1 * ceil(_sizeMultiplier/2)],
                                ["fireObserver", East_FireObserver, 1]
                            ]
                        } else {
                            [
                                ["infantry", East_Units, 4 * _sizeMultiplier],
                                ["vehicle", East_Ground_Vehicles_Light, 1 * ceil(_sizeMultiplier/2)]
                            ]
                        }
                    };
                    case "armored": {
                        // 10% chance to add a fire observer to armored units
                        if (random 1 < 0.10) then {
                            [
                                ["infantry", East_Units, 3 * _sizeMultiplier],
                                ["vehicle", East_Ground_Vehicles_Heavy, 1 * ceil(_sizeMultiplier/2)],
                                ["fireObserver", East_FireObserver, 1]
                            ]
                        } else {
                            [
                                ["infantry", East_Units, 3 * _sizeMultiplier],
                                ["vehicle", East_Ground_Vehicles_Heavy, 1 * ceil(_sizeMultiplier/2)]
                            ]
                        }
                    };
                    case "fortification": {
                        [
                            ["infantry", East_Units, 3 * _sizeMultiplier],
                            ["fortification", ["Land_BagBunker_Small_F", "Land_BagFence_Long_F", "Land_BagFence_Round_F"], 2 * _sizeMultiplier]
                        ]
                    };
                    default {
                        [
                            ["infantry", East_Units, 2 * _sizeMultiplier]
                        ]
                    };
                };
                
                _baseComposition
            };
            
            // Create the Task Force data structure
            private _taskForceData = [
                _taskForceId,
                _basePos,
                _targetPos,
                _taskForceType,
                _taskForceSize,
                _composition,
                false, // isDeployed
                [], // deployedUnits
                [], // waypoints
                time, // creationTime
                0, // virtualDistance
                0, // virtualDirection
                10, // movementSpeed
                _resourceCost, // resourceValue
                false // isVirtualized
            ];
            
            // Save to both object hashmap and global backup
            private _taskForces = _self getOrDefault ["taskForces", createHashMap];
            _taskForces set [_taskForceId, _taskForceData];
            _self set ["taskForces", _taskForces];
            
            // Also save to global backup variable
            FLO_Global_TaskForces set [_taskForceId, _taskForceData];
            
            diag_log format ["[FLO][TaskForce] Created Task Force %1 of type %2 (size: %3) at %4",
                _taskForceId, _taskForceType, _taskForceSize, _baseMarker];
            
            _taskForceId
        }],
        
        // Update all Task Forces (position, virtualization status, etc.)
        ["updateTaskForces", {
            private _taskForces = _self get "taskForces";
            private _taskForceKeys = keys _taskForces;
            private _playersPos = allPlayers apply {getPosWorld _x};
            private _activationDistance = VSDistance - 500; // Use a buffer from the virtualization distance
            
            if (count _taskForceKeys == 0) exitWith {}; 
            
            {
                private _taskForceId = _x;
                private _taskForceData = _taskForces get _taskForceId;
                
                _taskForceData params [
                    "_id",
                    "_basePos",
                    "_targetPos",
                    "_type",
                    "_size",
                    "_composition",
                    "_isDeployed",
                    "_deployedUnits",
                    "_waypoints",
                    "_creationTime",
                    "_virtualDistance",
                    "_virtualDirection",
                    "_movementSpeed",
                    "_resourceValue",
                    "_isVirtualized"
                ];
                
                // Process deployed but not virtualized task forces
                if (_isDeployed && !_isVirtualized) then {
                    // Check if Task Force should be virtualized (far from all players)
                    private _shouldVirtualize = true;
                    private _taskForcePos = _basePos; // Use last known position
                    
                    if (count _deployedUnits > 0) then {
                        // If units exist, use their average position
                        private _unitPositions = _deployedUnits apply {
                            if (!isNull _x) then {getPosWorld _x} else {[0,0,0]}
                        };
                        
                        // Filter out null positions
                        _unitPositions = _unitPositions select {!(_x isEqualTo [0,0,0])};
                        
                        if (count _unitPositions > 0) then {
                            // Calculate average position
                            private _totalPos = [0,0,0];
                            {_totalPos = _totalPos vectorAdd _x} forEach _unitPositions;
                            _taskForcePos = _totalPos vectorMultiply (1 / count _unitPositions);
                        };
                    };
                    
                    // Check distance from all players
                    {
                        if (_x distance _taskForcePos < VSDistance) exitWith {
                            _shouldVirtualize = false;
                        };
                    } forEach _playersPos;
                    
                    // Virtualize the Task Force if needed
                    if (_shouldVirtualize) then {
                        // Store Task Force data in VS_VirtualizedTaskForces
                        private _virtualTaskForceData = [
                            _taskForceId,
                            _taskForcePos,
                            _type,
                            _size,
                            _composition,
                            _deployedUnits apply {if (!isNull _x) then {typeOf _x} else {""}},
                            _resourceValue
                        ];
                        
                        // Store in virtualization system
                        private _key = format ["TF_%1_%2", _taskForcePos, floor random 999999];
                        VS_VirtualizedTaskForces set [_key, _virtualTaskForceData];
                        
                        // Delete units
                        {
                            if (!isNull _x) then {
                                if (_x isKindOf "Man") then {
                                    private _group = group _x;
                                    deleteVehicle _x;
                                    if (count units _group == 0) then {
                                        deleteGroup _group;
                                    };
                                } else {
                                    deleteVehicle _x;
                                };
                            };
                        } forEach _deployedUnits;
                        
                        // Update Task Force data
                        _taskForceData set [7, []]; // Clear deployed units
                        _taskForceData set [11, [_taskForcePos, _targetPos] call BIS_fnc_dirTo]; // Update direction
                        _taskForceData set [14, true]; // Mark as virtualized
                        
                        diag_log format ["[FLO][TaskForce] Virtualized Task Force %1 at position %2",
                            _taskForceId, _taskForcePos];
                    };
                };
                
                // Process virtualized task forces with targets
                if (_isVirtualized && !(_targetPos isEqualTo [0,0,0])) then {
                    // Calculate movement since last update
                    private _timeSinceLastUpdate = time - (_self get "lastUpdate");
                    private _distanceMoved = _movementSpeed * _timeSinceLastUpdate;
                    
                    // Update virtual distance moved
                    _virtualDistance = _virtualDistance + _distanceMoved;
                    _taskForceData set [10, _virtualDistance];
                    
                    // Calculate new position based on movement
                    private _totalDistance = _basePos distance _targetPos;
                    
                    // If Task Force has reached target, deploy it
                    if (_virtualDistance >= _totalDistance) then {
                        _taskForceData set [1, _targetPos]; // Update position to target
                        _taskForceData set [10, 0]; // Reset virtual distance
                        
                        // Check if it's near any players
                        private _shouldDeploy = false;
                        {
                            if (_x distance _targetPos < _activationDistance) exitWith {
                                _shouldDeploy = true;
                            };
                        } forEach _playersPos;
                        
                        if (_shouldDeploy) then {
                            // Deploy the Task Force at target
                            [_self, _taskForceId, _targetPos, true] call ["deployTaskForce", [_taskForceId, _targetPos, true]];
                        };
                    } else {
                        // Calculate new virtual position (for tracking purposes)
                        private _dirVector = _targetPos vectorDiff _basePos;
                        _dirVector = _dirVector vectorMultiply (1 / (_basePos distance _targetPos));
                        private _movementVector = _dirVector vectorMultiply _virtualDistance;
                        private _newVirtualPos = _basePos vectorAdd _movementVector;
                        
                        // Update the base position to track progress
                        _taskForceData set [1, _newVirtualPos];
                        
                        // Check if any players are near this virtual position
                        private _shouldDeploy = false;
                        {
                            if (_x distance _newVirtualPos < _activationDistance) exitWith {
                                _shouldDeploy = true;
                            };
                        } forEach _playersPos;
                        
                        if (_shouldDeploy) then {
                            // Deploy the Task Force at current virtual position
                            [_self, _taskForceId, _newVirtualPos, false] call ["deployTaskForce", [_taskForceId, _newVirtualPos, false]];
                        };
                    };
                };
                
                // Update the Task Force data
                _taskForces set [_taskForceId, _taskForceData];
            } forEach _taskForceKeys;
            
            // Update last update timestamp
            _self set ["lastUpdate", time];
        }],
        
        // Deploy a Task Force at a specific position
        ["deployTaskForce", {
            params ["_taskForceId", "_position", "_defensive"];
            
            // Get the Task Force data using dual lookup
            private _taskForces = _self getOrDefault ["taskForces", createHashMap];
            private _taskForceData = nil;
            
            // First try object hashmap
            if (_taskForceId in keys _taskForces) then {
                _taskForceData = _taskForces get _taskForceId;
            } else {
                // Then try global backup hashmap
                if (!isNil "FLO_Global_TaskForces" && {_taskForceId in keys FLO_Global_TaskForces}) then {
                    _taskForceData = FLO_Global_TaskForces get _taskForceId;
                    // Copy to object hashmap
                    _taskForces set [_taskForceId, _taskForceData];
                    _self set ["taskForces", _taskForces];
                    diag_log format ["[FLO][TaskForce] Restored Task Force %1 from global backup", _taskForceId];
                };
            };
            
            // If task force not found in either hashmap
            if (isNil "_taskForceData") exitWith {
                diag_log format ["[FLO][TaskForce] Error: Task Force %1 not found in any hashmap", _taskForceId];
                if (!isNil "FLO_Global_TaskForces") then {
                    diag_log format ["[FLO][TaskForce] Available global task forces: %1", keys FLO_Global_TaskForces];
                };
                false
            };
            
            // Check if any player is within 700 meters of the deployment position
            private _tooCloseToPlayer = false;
            {
                if (_x distance _position < 700) exitWith {
                    _tooCloseToPlayer = true;
                    diag_log format ["[FLO][TaskForce] Task Force %1 deployment canceled - too close to player (%2m)", _taskForceId, _x distance _position];
                };
            } forEach allPlayers;
            
            if (_tooCloseToPlayer) exitWith {
                diag_log format ["[FLO][TaskForce] Task Force %1 deployment canceled - position %2 is within 700m of a player", _taskForceId, _position];
                false
            };
            
            _taskForceData params [
                "_id",
                "_basePos",
                "_targetPos",
                "_type",
                "_size",
                "_composition",
                "_isDeployed",
                "_deployedUnits",
                "_waypoints",
                "_creationTime",
                "_virtualDistance",
                "_virtualDirection",
                "_movementSpeed",
                "_resourceValue",
                "_isVirtualized"
            ];
            
            // If already deployed and not virtualized, exit
            if (_isDeployed && !_isVirtualized) exitWith {
                diag_log format ["[FLO][TaskForce] Task Force %1 is already deployed", _taskForceId];
                false
            };
            
            // Extract direction if position is passed in special format "markerName|direction"
            private _directionOverride = -1;
            
            if (_position isEqualType "") then {
                private _parts = _position splitString "|";
                if (count _parts > 1) then {
                    _position = _parts select 0;
                    _directionOverride = parseNumber (_parts select 1);
                    diag_log format ["[FLO][TaskForce] Direction override detected in marker: %1", _directionOverride];
                };
            };
            
            // Make sure position is not in water
            if (surfaceIsWater _position) then {
                diag_log format ["[FLO][TaskForce] Warning: Deployment position %1 is in water, finding safe position", _position];
                
                // Try to find a land position nearby
                private _landPos = [_position, 0, 300, 10, 0, 0.1, 0] call BIS_fnc_findSafePos;
                
                // Verify the found position is valid and not in water
                if (!surfaceIsWater _landPos) then {
                    _position = _landPos;
                    diag_log format ["[FLO][TaskForce] Adjusted deployment position to land: %1", _position];
                } else {
                    diag_log "[FLO][TaskForce] Warning: Could not find non-water position, deployment may fail";
                };
            };
            
            // Find direction toward BLUFOR territory
            private _bluforDirection = 0;
            
            // If we have a direction override (from defense line), use it
            if (_directionOverride != -1) then {
                _bluforDirection = _directionOverride;
                diag_log format ["[FLO][TaskForce] Using provided direction: %1", _bluforDirection];
            } else {
                // Otherwise calculate direction to nearest BLUFOR marker
                private _bluforMarkers = allMapMarkers select {
                    markerColor _x in ["colorBLUFOR", "ColorWEST", "ColorYellow"] &&
                    markerType _x in ["b_installation", "b_support", "respawn_west", "b_hq"]
                };
                
                // Get nearest BLUFOR marker
                private _nearestBluforDist = 999999;
                private _nearestBluforPos = [0,0,0];
                
                {
                    private _bluforPos = getMarkerPos _x;
                    private _dist = _position distance _bluforPos;
                    if (_dist < _nearestBluforDist) then {
                        _nearestBluforDist = _dist;
                        _nearestBluforPos = _bluforPos;
                    };
                } forEach _bluforMarkers;
                
                // Calculate direction from task force to BLUFOR
                if (!(_nearestBluforPos isEqualTo [0,0,0])) then {
                    _bluforDirection = _position getDir _nearestBluforPos;
                };
                
                diag_log format ["[FLO][TaskForce] Calculated direction to BLUFOR: %1", _bluforDirection];
            };
            
            // Create units based on composition
            private _allCreatedUnits = [];
            private _allCreatedGroups = [];
            
            // Create infantry group
            private _infantryGroup = createGroup [east, true];  // Added true for deleteWhenEmpty
            
            {
                _x params ["_unitType", "_unitClasses", "_unitCount"];
                
                switch (_unitType) do {
                    case "infantry";
                    case "at";
                    case "mg": {
                        for "_i" from 1 to _unitCount do {
                            private _unitClass = selectRandom _unitClasses;
                            // Increase spread of units (more randomness)
                            private _unitPos = _position getPos [20 + random 30, random 360];
                            
                            // Check for water and find land if needed
                            if (surfaceIsWater _unitPos) then {
                                _unitPos = [_unitPos, 0, 100, 5, 0, 0.1, 0] call BIS_fnc_findSafePos;
                            };
                            
                            private _unit = _infantryGroup createUnit [_unitClass, _unitPos, [], 5, "NONE"];
                            if (!isNull _unit) then {
                                // Ensure unit is on EAST side
                                [_unit] joinSilent _infantryGroup;
                                // Set unit direction toward BLUFOR
                                _unit setDir _bluforDirection;
                                _allCreatedUnits pushBack _unit;
                            } else {
                                diag_log format ["[FLO][TaskForce] Failed to create unit of type %1", _unitClass];
                            };
                        };
                    };
                    
                    case "fireObserver": {
                        for "_i" from 1 to _unitCount do {
                            private _unitClass = selectRandom _unitClasses;
                            // Place fire observer in a tactically advantageous position
                            private _unitPos = _position getPos [15 + random 20, random 360];
                            
                            // Check for water and find land if needed
                            if (surfaceIsWater _unitPos) then {
                                _unitPos = [_unitPos, 0, 100, 5, 0, 0.1, 0] call BIS_fnc_findSafePos;
                            };
                            
                            private _unit = _infantryGroup createUnit [_unitClass, _unitPos, [], 5, "NONE"];
                            if (!isNull _unit) then {
                                // Ensure unit is on EAST side
                                [_unit] joinSilent _infantryGroup;
                                // Set unit direction toward BLUFOR
                                _unit setDir _bluforDirection;
                                // Initialize as fire observer
                                [_unit, EAST] call FLO_fnc_fireObserver;
                                _allCreatedUnits pushBack _unit;
                                
                                diag_log format ["[FLO][TaskForce] Created fire observer of type %1 in task force %2", _unitClass, _taskForceId];
                            } else {
                                diag_log format ["[FLO][TaskForce] Failed to create fire observer of type %1", _unitClass];
                            };
                        };
                    };
                    
                    case "vehicle": {
                        for "_i" from 1 to _unitCount do {
                            private _vehicleClass = selectRandom _unitClasses;
                            // Increase vehicle spread for wider formation
                            private _vehiclePos = [_position, 30, 80, 10, 0, 0.5, 0] call BIS_fnc_findSafePos;
                            
                            // Double-check for water - findSafePos should handle this but to be sure
                            if (surfaceIsWater _vehiclePos) then {
                                _vehiclePos = [_position, 0, 200, 10, 0, 0.1, 0] call BIS_fnc_findSafePos;
                                diag_log format ["[FLO][TaskForce] Had to relocate vehicle from water at %1", _vehiclePos];
                            };
                            
                            private _vehicle = createVehicle [_vehicleClass, _vehiclePos, [], 0, "NONE"];
                            if (!isNull _vehicle) then {
                                // Set vehicle direction toward BLUFOR
                                _vehicle setDir _bluforDirection;
                                
                                // Create crew and ensure they're on EAST side
                                private _vehicleGroup = createGroup [east, true];
                                [_vehicle, _vehicleGroup] call BIS_fnc_spawnCrew;
                                
                                // Ensure all crew members are on EAST side
                                {
                                    [_x] joinSilent _vehicleGroup;
                                } forEach (crew _vehicle);
                                
                                _allCreatedUnits pushBack _vehicle;
                                _allCreatedUnits append (crew _vehicle);
                                _allCreatedGroups pushBack _vehicleGroup;
                            } else {
                                diag_log format ["[FLO][TaskForce] Failed to create vehicle of type %1", _vehicleClass];
                            };
                        };
                    };
                    
                    case "fortification": {
                        // Improved defensive fortification layout
                        if (_defensive) then {
                            // Create a radial pattern of fortifications facing BLUFOR
                            private _fortCount = _unitCount min 6;  // Cap at 6 fortifications for better layout
                            private _angleStep = 180 / _fortCount; // Semi-circle (180 degrees) facing BLUFOR
                            
                            for "_i" from 0 to (_fortCount - 1) do {
                                private _fortClass = selectRandom _unitClasses;
                                
                                // Place in a semi-circle facing BLUFOR direction with correct alignment
                                // Calculate angle between -90 and +90 degrees relative to BLUFOR direction
                                private _angle = ((_bluforDirection - 90) + (_i * _angleStep)) mod 360;
                                private _distance = 25 + random 15; // Tighter defensive layout
                                private _fortPos = _position getPos [_distance, _angle];
                                
                                // Check for water when placing fortifications
                                if (surfaceIsWater _fortPos) then {
                                    // Try to find land nearby for the fortification
                                    _fortPos = [_fortPos, 0, 100, 5, 0, 0.1, 0] call BIS_fnc_findSafePos;
                                    diag_log format ["[FLO][TaskForce] Relocated fortification from water to %1", _fortPos];
                                };
                                
                                private _fortification = createVehicle [_fortClass, _fortPos, [], 0, "NONE"];
                                if (!isNull _fortification) then {
                                    // Face toward BLUFOR - this is critical
                                    _fortification setDir _bluforDirection;
                                    _allCreatedUnits pushBack _fortification;
                                    
                                    // Add sandbags in front of bunkers - correctly oriented
                                    if (_fortClass in ["Land_BagBunker_Small_F", "Land_BagBunker_01_small_green_F"]) then {
                                        private _bagPos = _fortPos getPos [5, _bluforDirection];
                                        private _bag = createVehicle ["Land_BagFence_Long_F", _bagPos, [], 0, "NONE"];
                                        // Sandbags need to be perpendicular to blufor direction to provide cover
                                        _bag setDir (_bluforDirection + 90);
                                        _allCreatedUnits pushBack _bag;
                                    };
                                } else {
                                    diag_log format ["[FLO][TaskForce] Failed to create fortification of type %1", _fortClass];
                                };
                            };
                        } else {
                            // Regular fortification placement for non-defensive positions
                            for "_i" from 1 to _unitCount do {
                                private _fortClass = selectRandom _unitClasses;
                                private _fortPos = [_position, 10, 30, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
                                
                                private _fortification = createVehicle [_fortClass, _fortPos, [], 0, "NONE"];
                                if (!isNull _fortification) then {
                                    // Face fortifications toward BLUFOR territory
                                    _fortification setDir _bluforDirection;
                                    _allCreatedUnits pushBack _fortification;
                                } else {
                                    diag_log format ["[FLO][TaskForce] Failed to create fortification of type %1", _fortClass];
                                };
                            };
                        };
                    };
                };
            } forEach _composition;
            
            // Verify units were created
            if (count _allCreatedUnits == 0) exitWith {
                diag_log format ["[FLO][TaskForce] Error: No units created for Task Force %1", _taskForceId];
                false
            };
            
            // Set up behavior based on deployment type
            if (_defensive) then {
                if (count units _infantryGroup > 0) then {
                    // For defensive posture, use taskDefend with facing toward BLUFOR
                    // Increase radius to account for wider spread
                    [_infantryGroup, _position, 150] call BIS_fnc_taskDefend;
                    
                    // Set unit combat mode and behavior
                    _infantryGroup setCombatMode "YELLOW";
                    _infantryGroup setBehaviour "COMBAT";
                    _infantryGroup setFormDir _bluforDirection;
                    
                    // Make units take better defensive positions - make sure they face BLUFOR
                    {
                        // Set unit stance
                        _x setUnitPos selectRandom ["MIDDLE", "DOWN"]; // Either kneeling or prone
                        
                        // Make units face BLUFOR direction - with a slight random variation
                        _x setDir (_bluforDirection + (random 20) - 10); // Add small random variation
                        
                        // Specifically tell them to watch in BLUFOR direction
                        _x doWatch (_x getPos [500, _bluforDirection]);
                        
                        // Give units a doMove command to better spread around defensive positions
                        // Make sure spread is biased toward BLUFOR side
                        private _spreadAngle = (_bluforDirection - 60 + random 120) mod 360; // 120° arc facing BLUFOR
                        private _spreadPos = _position getPos [15 + random 25, _spreadAngle];
                        _x doMove _spreadPos;
                    } forEach (units _infantryGroup);
                };
                
                {
                    private _grp = _x;
                    if (_grp isEqualType grpNull && {count units _grp > 0}) then {
                        // Wider defensive area for vehicle groups
                        [_grp, _position, 200] call BIS_fnc_taskDefend;
                        _grp setCombatMode "YELLOW";
                        _grp setBehaviour "COMBAT";
                        _grp setFormDir _bluforDirection;
                        
                        // If it's a vehicle crew, make them face BLUFOR
                        {
                            if (vehicle _x != _x) then {
                                // Set exact direction toward BLUFOR territory
                                (vehicle _x) setDir _bluforDirection;
                                (vehicle _x) doWatch ((vehicle _x) getPos [1000, _bluforDirection]);
                            };
                        } forEach (units _grp);
                    };
                } forEach _allCreatedGroups;
                
                // Create marker for defensive position
                // private _markerName = format ["tf_def_%1", _taskForceId];
                // createMarker [_markerName, _position];
                // _markerName setMarkerType "mil_triangle";
                // _markerName setMarkerColor "ColorEAST";
                // _markerName setMarkerAlpha 0.6;
                // _markerName setMarkerSize [0.6, 0.6];
                // _markerName setMarkerDir _bluforDirection; // Set marker to face BLUFOR
                // _markerName setMarkerText format ["TF %1", _type];
            } else {
                if (!(_targetPos isEqualTo [0,0,0])) then {
                    if (count units _infantryGroup > 0) then {
                        [_infantryGroup, _targetPos, 200] call BIS_fnc_taskPatrol;
                        _infantryGroup setCombatMode "YELLOW";
                        _infantryGroup setBehaviour "AWARE";
                        _infantryGroup setFormDir (_position getDir _targetPos);
                    };
                    
                    {
                        private _grp = _x;
                        if (_grp isEqualType grpNull && {count units _grp > 0}) then {
                            [_grp, _targetPos, 250] call BIS_fnc_taskPatrol;
                            _grp setCombatMode "YELLOW";
                            _grp setBehaviour "AWARE";
                            _grp setFormDir (_position getDir _targetPos);
                        };
                    } forEach _allCreatedGroups;
                } else {
                    if (count units _infantryGroup > 0) then {
                        [_infantryGroup, _position, 150] call BIS_fnc_taskPatrol;
                        _infantryGroup setCombatMode "YELLOW";
                        _infantryGroup setBehaviour "AWARE";
                        _infantryGroup setFormDir _bluforDirection;
                    };
                    
                    {
                        private _grp = _x;
                        if (_grp isEqualType grpNull && {count units _grp > 0}) then {
                            [_grp, _position, 200] call BIS_fnc_taskPatrol;
                            _grp setCombatMode "YELLOW";
                            _grp setBehaviour "AWARE";
                            _grp setFormDir _bluforDirection;
                        };
                    } forEach _allCreatedGroups;
                };
            };
            
            // Update Task Force data
            _taskForceData set [1, _position];
            _taskForceData set [6, true];
            _taskForceData set [7, _allCreatedUnits];
            _taskForceData set [14, false];
            
            // Update the hashmap
            _taskForces set [_taskForceId, _taskForceData];
            _self set ["taskForces", _taskForces];
            
            diag_log format ["[FLO][TaskForce] Successfully deployed Task Force %1 at position %2 with %3 units facing %4°",
                _taskForceId, _position, count _allCreatedUnits, _bluforDirection];
            
            true
        }],
        
        // Get information about a specific Task Force
        ["getTaskForce", {
            params ["_taskForceId"];
            
            private _taskForces = _self get "taskForces";
            if (!(_taskForceId in keys _taskForces)) exitWith {
                []
            };
            
            _taskForces get _taskForceId
        }],
        
        // Strengthen a deployed defensive line
        ["reinforceDefensiveLine", {
            params ["_position", "_radius"];
            
            private _taskForces = _self get "taskForces";
            private _nearbyTaskForces = [];
            
            // Find Task Forces near the position
            {
                private _taskForceData = _taskForces get _x;
                private _taskForcePos = _taskForceData select 1;
                
                if (_taskForcePos distance _position <= _radius) then {
                    _nearbyTaskForces pushBack _x;
                };
            } forEach keys _taskForces;
            
            if (count _nearbyTaskForces == 0) exitWith {
                diag_log format ["[FLO][TaskForce] No Task Forces found near position %1", _position];
                false
            };
            
            // Create a fortification Task Force to strengthen the line
            _self call ["createTaskForce", ["", "fortification", "squad", ""]];
            
            // Deploy the Task Force at the position
            _self call ["deployTaskForce", [_taskForceId, _position, true]];
            
            diag_log format ["[FLO][TaskForce] Reinforced defensive line at %1", _position];
            true
        }]
    ];
    
    // Create the TaskForceSystem with specified parameters
    FLO_TaskForce_System = createHashMapObject [_taskForceSystemClass];
};

// Handle different operation modes
switch (_mode) do {
    // Initialize the Task Force system and start background processes
    case "init": {
        private _self = FLO_TaskForce_System;
        _self call ["initialize", []];
        _result = FLO_TaskForce_System;
    };
    
    // Create a new Task Force with specified parameters
    case "createTaskForce": {
        _params params [
            ["_baseMarker", "", [""]],
            ["_taskForceType", "infantry", [""]],
            ["_taskForceSize", "squad", [""]],
            ["_targetMarker", "", [""]]
        ];
        
        private _self = FLO_TaskForce_System;
        
        // We need to ensure the HashMapObject is properly initialized
        if (isNil {_self getOrDefault ["taskForces", nil]}) then {
            _self set ["taskForces", createHashMap];
            diag_log "[FLO][TaskForce] Created new taskForces hashmap";
        };
        
        _result = _self call ["createTaskForce", [_baseMarker, _taskForceType, _taskForceSize, _targetMarker]];
    };
    
    // Update all Task Force positions and statuses
    case "updateTaskForces": {
        private _self = FLO_TaskForce_System;
        _self call ["updateTaskForces", []];
    };
    
    // Get information about a specific Task Force
    case "getTaskForce": {
        _params params [["_taskForceId", "", [""]]];
        
        private _self = FLO_TaskForce_System;
        _result = _self call ["getTaskForce", [_taskForceId]];
    };
    
    // Deploy a Task Force at a specific position
    case "deployTaskForce": {
        _params params [
            ["_taskForceId", "", [""]],
            ["_position", [0,0,0], [[]]],
            ["_defensive", false, [false]]
        ];
        
        private _self = FLO_TaskForce_System;
        _result = _self call ["deployTaskForce", [_taskForceId, _position, _defensive]];
    };
};

_result 