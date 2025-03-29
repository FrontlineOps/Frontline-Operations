/*
    Function: FLO_fnc_TaskForceSystem
    
    Description:
    Manages OPFOR Task Forces that move across the map and appear when near BLUFOR.
    Fully compatible with CDVS Virtualization system.
    Allows creation of defensive lines with fortifications, infantry, and vehicles.
    
    Parameters:
    _mode - The function mode to execute ["init", "createTaskForce", "updateTaskForces", "getTaskForce", "deployTaskForce", "removeTaskForce"] (String)
    _params - Parameters based on mode (Array)
        init: [] - Initialize the Task Force system
        createTaskForce: [_baseMarker, _taskForceType, _taskForceSize, _targetMarker] - Create a new Task Force
        updateTaskForces: [] - Update all Task Forces positions and statuses
        getTaskForce: [_taskForceId] - Get information about a specific Task Force
        deployTaskForce: [_taskForceId, _position] - Deploy a Task Force at a specific position
        removeTaskForce: [_taskForceId] - Remove an existing Task Force and clean up all resources
    
    Returns:
    Based on mode:
        init: HashMapObject - The Task Force system object
        createTaskForce: String - The ID of the created Task Force
        updateTaskForces: Nothing
        getTaskForce: Array - Information about the Task Force
        deployTaskForce: Boolean - True if successfully deployed
        removeTaskForce: Boolean - True if successfully removed
    
    Log conversion status:
    Several log calls have been converted from diag_log to FLO_fnc_log, but many debug logs
    still need conversion. The pattern to follow for remaining conversions is:
    
    For errors (level 1):
    diag_log format ["[FLO][TaskForce] Error: ..."] → ["TaskForce", 1, format["Error: ..."]] call FLO_fnc_log;
    
    For warnings (level 2):
    diag_log format ["[FLO][TaskForce] Warning: ..."] → ["TaskForce", 2, format["Warning: ..."]] call FLO_fnc_log;
    
    For info (level 3):
    diag_log format ["[FLO][TaskForce] ..."] → ["TaskForce", 3, format["..."]] call FLO_fnc_log;
    
    For debug (level 4):
    diag_log format ["[FLO][TaskForce][DEBUG] ..."] → ["TaskForce", 4, format["..."]] call FLO_fnc_log;
*/

if (!isServer) exitWith {};

// Global backup variable for task forces to prevent synchronization issues
if (isNil "FLO_Global_TaskForces") then {
    FLO_Global_TaskForces = createHashMap;
};

// Add global virtualization state cooldown tracker
// if (isNil "FLO_TaskForce_VirtualStateChanges") then {
//     FLO_TaskForce_VirtualStateChanges = createHashMap;
// };

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
        ["activatedTaskForces", createHashMap],
        ["lastUpdate", time],
        ["lastTaskForceId", 0],
        ["lastTaskForceScan", time],
        ["virtualizationBuffer", 300],
        ["virtualizationCooldown", 60],
        
        // Constructor - Called when object is created
        ["#create", {
            _self set ["taskForces", createHashMap];
            _self set ["activatedTaskForces", createHashMap];
            _self set ["lastUpdate", time];
            _self set ["lastTaskForceId", 0];
            _self set ["lastTaskForceScan", time];
            _self set ["virtualizationBuffer", 300];
            _self set ["virtualizationCooldown", 60];
            ["TaskForce", 3, "System initialized"] call FLO_fnc_log;
        }],
        
        // Initialize Task Force system and start update loop
        ["initialize", {
            // Initialize the VS_VirtualizedTaskForces hashmap if it doesn't exist
            // if (isNil "VS_VirtualizedTaskForces") then {
            //     VS_VirtualizedTaskForces = createHashMap;
            // };
            
            // // Start the update loop for Task Force movement
            // [] spawn {
            //     while {true} do {
            //         // Update Task Forces every 30 seconds
            //         ["updateTaskForces", []] call FLO_fnc_TaskForceSystem;
            //         sleep 30;
            //     };
            // };
        }],
        
        // Create a new Task Force with specified parameters
        ["createTaskForce", {
            params [
                ["_baseMarker", "", [""]],
                ["_taskForceType", "infantry", [""]],
                ["_taskForceSize", "squad", [""]],
                ["_targetMarker", "", [""]],
                ["_providedTaskForceId", "", [""]],
                ["_providedComposition", [], [[]]]
            ];
            
            // Validate base marker
            if (_baseMarker == "") exitWith {
                ["TaskForce", 1, "Error: Empty base marker name"] call FLO_fnc_log;
                ""
            };
            
            private _basePos = getMarkerPos _baseMarker;
            if (_basePos isEqualTo [0,0,0]) exitWith {
                ["TaskForce", 1, "Error: Invalid base marker position"] call FLO_fnc_log;
                ""
            };
            
            // Get target position (can be empty for defensive Task Forces)
            private _targetPos = [0,0,0];
            if (_targetMarker != "") then {
                _targetPos = getMarkerPos _targetMarker;
            };
            
            // Generate a unique ID for this Task Force - use provided ID if available
            private _taskForceId = "";
            if (_providedTaskForceId != "") then {
                _taskForceId = _providedTaskForceId;
                ["TaskForce", 3, format["Using provided task force ID: %1", _taskForceId]] call FLO_fnc_log;
            } else {
                private _lastId = _self getOrDefault ["lastTaskForceId", 0];
                _taskForceId = format ["TF_%1_%2", _lastId + 1, floor random 10000];
                _self set ["lastTaskForceId", _lastId + 1];
            };
            
            // Sanitize the task force ID if it contains coordinates
            if (_taskForceId find "[" > 0) then {
                _taskForceId = _self call ["_sanitizeTaskForceId", [_taskForceId]];
                ["TaskForce", 3, format["Sanitized task force ID to: %1", _taskForceId]] call FLO_fnc_log;
            };
            
            // Calculate resource cost based on type and size
            private _resourceCost = [_taskForceType, _taskForceSize] call {
                params ["_type", "_size"];
                
                private _typeCost = switch (toLower _type) do {
                    case "infantry": {10};
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
            private _currentResources = FLO_OPFOR_Resources call ["getResources", []];
            if (_currentResources < _resourceCost) exitWith {
                ["TaskForce", 1, format["Error: Insufficient resources to create Task Force (needed %1, have %2)",
                    _resourceCost, _currentResources]] call FLO_fnc_log;
                ""
            };
            
            // Spend the resources
            // Cost of Arming & Supplying
            FLO_OPFOR_Resources call ["spendResources", [_resourceCost, "offensiveops"]]; 
            
            // Define the Task Force composition based on type and size or use provided composition
            private _composition = [];
            
            // If a composition was provided, use it
            if (count _providedComposition > 0) then {
                _composition = _providedComposition;
                ["TaskForce", 3, format["Using provided composition for Task Force %1 with %2 elements", 
                    _taskForceId, count _providedComposition]] call FLO_fnc_log;
            } else {
                // Otherwise generate composition based on type and size
                _composition = [_taskForceType, _taskForceSize] call {
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
                                ["infantry", East_Units + East_FireObserver + East_Units_Officers, 4 * _sizeMultiplier]
                            ]
                        };
                        default {
                            [
                                ["infantry", East_Units + East_FireObserver + East_Units_Officers, 2 * _sizeMultiplier]
                            ]
                        };
                    };
                    
                    _baseComposition
                };
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
            
            ["TaskForce", 3, format["Created Task Force %1 of type %2 (size: %3) at %4 with composition of %5 elements",
                _taskForceId, _taskForceType, _taskForceSize, _baseMarker, count _composition]] call FLO_fnc_log;
            
            _taskForceId
        }],
        
        // Update all Task Forces (position, virtualization status, etc.)
        ["updateTaskForces", {
            private _taskForces = _self get "taskForces";
            private _taskForceKeys = keys _taskForces;
            private _playersPos = allPlayers apply {getPosWorld _x};
            private _activationDistance = VSDistance - 500; // Use a buffer from the virtualization distance
            private _virtualizationBuffer = _self get "virtualizationBuffer";
            private _virtualizationCooldown = _self get "virtualizationCooldown";
            
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
                
                // Get last state change timestamp
                private _lastStateChange = FLO_TaskForce_VirtualStateChanges getOrDefault [_taskForceId, 0];
                private _stateChangeCooldown = (time - _lastStateChange) < _virtualizationCooldown;
                
                // Process deployed but not virtualized task forces
                if (_isDeployed && !_isVirtualized) then {
                    // Only check for virtualization if not in cooldown period
                    if (!_stateChangeCooldown) then {
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
                        
                        // Use a larger distance for virtualization (VSDistance + buffer)
                        // This creates hysteresis - units virtualize at a further distance than they devirtualize
                        private _virtualizeDistance = VSDistance + _virtualizationBuffer;
                        
                        // Check distance from all players
                        {
                            if (_x distance _taskForcePos < _virtualizeDistance) exitWith {
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
                            
                            // Record state change time
                            FLO_TaskForce_VirtualStateChanges set [_taskForceId, time];
                            
                            ["TaskForce", 3, format["Virtualized Task Force %1 at position %2",
                                _taskForceId, _taskForcePos]] call FLO_fnc_log;
                        };
                    };
                };
                
                // Process virtualized task forces
                if (_isVirtualized) then {
                    // Handling movement for virtualized task forces with targets
                    if (!(_targetPos isEqualTo [0,0,0])) then {
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
                            
                            // Check if it's near any players - only if not in cooldown
                            if (!_stateChangeCooldown) then {
                                private _shouldDeploy = false;
                                {
                                    // Use a smaller distance for devirtualization (normal activation distance)
                                    // This maintains the hysteresis effect
                                    if (_x distance _targetPos < _activationDistance) exitWith {
                                        _shouldDeploy = true;
                                    };
                                } forEach _playersPos;
                                
                                if (_shouldDeploy) then {
                                    // Deploy the Task Force at target
                                    [_self, _taskForceId, _targetPos, true] call ["deployTaskForce", [_taskForceId, _targetPos, true]];
                                    // Record state change time
                                    FLO_TaskForce_VirtualStateChanges set [_taskForceId, time];
                                };
                            };
                        } else {
                            // Calculate new virtual position (for tracking purposes)
                            private _dirVector = _targetPos vectorDiff _basePos;
                            _dirVector = _dirVector vectorMultiply (1 / (_basePos distance _targetPos));
                            private _movementVector = _dirVector vectorMultiply _virtualDistance;
                            private _newVirtualPos = _basePos vectorAdd _movementVector;
                            
                            // Update the base position to track progress
                            _taskForceData set [1, _newVirtualPos];
                            
                            // Check if any players are near this virtual position - only if not in cooldown
                            if (!_stateChangeCooldown) then {
                                private _shouldDeploy = false;
                                {
                                    // Use normal activation distance for devirtualization
                                    if (_x distance _newVirtualPos < _activationDistance) exitWith {
                                        _shouldDeploy = true;
                                    };
                                } forEach _playersPos;
                                
                                if (_shouldDeploy) then {
                                    // Deploy the Task Force at current virtual position
                                    [_self, _taskForceId, _newVirtualPos, false] call ["deployTaskForce", [_taskForceId, _newVirtualPos, false]];
                                    // Record state change time
                                    FLO_TaskForce_VirtualStateChanges set [_taskForceId, time];
                                };
                            };
                        };
                    } else {
                        // Handle static virtualized task forces - only if not in cooldown
                        if (!_stateChangeCooldown) then {
                            private _shouldDeploy = false;
                            {
                                // Use normal activation distance for devirtualization
                                if (_x distance _basePos < _activationDistance) exitWith {
                                    _shouldDeploy = true;
                                };
                            } forEach _playersPos;
                            
                            if (_shouldDeploy) then {
                                // Deploy the Task Force at its last known position
                                [_self, _taskForceId, _basePos, true] call ["deployTaskForce", [_taskForceId, _basePos, true]];
                                // Record state change time
                                FLO_TaskForce_VirtualStateChanges set [_taskForceId, time];
                            };
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
            params ["_taskForceId", "_position"];
            
            // Start intensive debug logging
            ["TaskForce", 4, "====================================================================="] call FLO_fnc_log;
            ["TaskForce", 4, format["Starting deployment process for task force %1", _taskForceId]] call FLO_fnc_log;
            ["TaskForce", 4, format["Deployment position: %1", _position]] call FLO_fnc_log;
            
            // Sanitize the task force ID to handle coordinates in the name
            private _originalId = _taskForceId;
            private _sanitizedId = _self call ["_sanitizeTaskForceId", [_taskForceId]];
            ["TaskForce", 4, format["Original ID: %1, Sanitized ID: %2", _originalId, _sanitizedId]] call FLO_fnc_log;
            
            // Get the Task Force data using dual lookup
            private _taskForces = _self getOrDefault ["taskForces", createHashMap];
            private _taskForceData = nil;
            
            // Log available task forces for debugging
            ["TaskForce", 4, format["Available task forces in local registry: %1", keys _taskForces]] call FLO_fnc_log;
            if (!isNil "FLO_Global_TaskForces") then {
                ["TaskForce", 4, format["Available task forces in global registry: %1", keys FLO_Global_TaskForces]] call FLO_fnc_log;
            };
            
            // First try object hashmap with original and sanitized IDs
            if (_originalId in keys _taskForces) then {
                _taskForceData = _taskForces get _originalId;
            } else {
                if (_sanitizedId in keys _taskForces) then {
                    _taskForceData = _taskForces get _sanitizedId;
                    _taskForceId = _sanitizedId; // Use sanitized ID for subsequent operations
                } else {
                    // Then try global backup hashmap
                    if (!isNil "FLO_Global_TaskForces") then {
                        if (_originalId in keys FLO_Global_TaskForces) then {
                            _taskForceData = FLO_Global_TaskForces get _originalId;
                        } else {
                            if (_sanitizedId in keys FLO_Global_TaskForces) then {
                                _taskForceData = FLO_Global_TaskForces get _sanitizedId;
                                _taskForceId = _sanitizedId; // Use sanitized ID for subsequent operations
                            };
                        };
                        
                        if (!isNil "_taskForceData") then {
                            // Copy to object hashmap
                            _taskForces set [_taskForceId, _taskForceData];
                            _self set ["taskForces", _taskForces];
                            ["TaskForce", 3, format["Restored Task Force %1 from global backup", _taskForceId]] call FLO_fnc_log;
                        };
                    };
                };
            };
            
            // If task force not found in either hashmap
            if (isNil "_taskForceData") exitWith {
                ["TaskForce", 1, format["Error: Task Force %1 not found in any hashmap", _taskForceId]] call FLO_fnc_log;
                if (!isNil "FLO_Global_TaskForces") then {
                    ["TaskForce", 3, format["Available global task forces: %1", keys FLO_Global_TaskForces]] call FLO_fnc_log;
                };
                grpNull // Return grpNull instead of false
            };
            
            // Extract direction if position is passed in special format "markerName|direction"
            private _directionOverride = -1;
            
            if (_position isEqualType "") then {
                private _parts = _position splitString "|";
                if (count _parts > 1) then {
                    _position = _parts select 0;
                    _directionOverride = parseNumber (_parts select 1);
                    ["TaskForce", 3, format["Direction override detected in marker: %1", _directionOverride]] call FLO_fnc_log;
                };
            };
            
            // If position is a marker, get its position
            if (_position isEqualType "") then {
                _position = getMarkerPos _position;
            };
            
            // Make sure position is not in water
            if (surfaceIsWater _position) then {
                ["TaskForce", 2, format["Warning: Deployment position %1 is in water, finding safe position", _position]] call FLO_fnc_log;
                
                // Try to find a land position nearby
                private _landPos = [_position, 0, 300, 10, 0, 0.1, 0] call BIS_fnc_findSafePos;
                
                // Verify the found position is valid and not in water
                if (!surfaceIsWater _landPos) then {
                    _position = _landPos;
                    ["TaskForce", 3, format["Adjusted deployment position to land: %1", _position]] call FLO_fnc_log;
                } else {
                    ["TaskForce", 2, "Warning: Could not find non-water position, deployment may fail"] call FLO_fnc_log;
                };
            };
            
            // Check if any player is within 700 meters of the deployment position
            private _tooCloseToPlayer = false;
            private _closestPlayerDistance = 999999;
            private _closestPlayer = objNull;
            
            {
                private _distance = _x distance _position;
                if (_distance < 700) then {
                    _tooCloseToPlayer = true;
                    if (_distance < _closestPlayerDistance) then {
                        _closestPlayerDistance = _distance;
                        _closestPlayer = _x;
                    };
                };
            } forEach allPlayers;
            
            // If too close to players, try to find alternative position
            if (_tooCloseToPlayer) then {
                // Log original issue
                ["TaskForce", 2, format["Task Force %1 initial position %2 is within 700m of a player (%3m)", 
                    _taskForceId, _position, _closestPlayerDistance]] call FLO_fnc_log;
                
                // Try to find alternative positions
                private _alternatePositions = [];
                private _sourceOutpost = "";
                
                // Extract source outpost from task force data
                _taskForceData params [
                    "_id",
                    "_basePos",
                    "_targetPos"
                ];
                
                _sourceOutpost = _basePos;
                
                // Try different directions from the source outpost
                for "_dir" from 0 to 315 step 45 do {
                    private _testDistance = 1000;
                    private _testPos = _sourceOutpost getPos [_testDistance, _dir];
                    
                    // Check if this position is far enough from all players
                    private _isSafe = true;
                    {
                        if (_x distance _testPos < 700) exitWith {
                            _isSafe = false;
                        };
                    } forEach allPlayers;
                    
                    if (_isSafe) then {
                        _alternatePositions pushBack [_testPos, _dir];
                    };
                };
                
                // If we found some alternative positions, use the closest one to the original target
                if (count _alternatePositions > 0) then {
                    _alternatePositions = [_alternatePositions, [], {(_x select 0) distance _position}, "ASCEND"] call BIS_fnc_sortBy;
                    _position = (_alternatePositions select 0) select 0;
                    _directionOverride = (_alternatePositions select 0) select 1;
                    
                    ["TaskForce", 3, format["Found alternative position for Task Force %1 at %2, direction %3", 
                        _taskForceId, _position, _directionOverride]] call FLO_fnc_log;
                        
                    // Reset flag since we found a safe position
                    _tooCloseToPlayer = false;
                };
            };
            
            // If still too close to player and no alternative found, exit
            if (_tooCloseToPlayer) exitWith {
                ["TaskForce", 2, format["Task Force %1 deployment canceled - too close to player (%2m)", 
                    _taskForceId, _closestPlayerDistance]] call FLO_fnc_log;
                ["TaskForce", 2, format["Task Force %1 deployment canceled - position %2 is within 700m of a player", 
                    _taskForceId, _position]] call FLO_fnc_log;
                    
                // Clean up and remove this task force (it will be returned to garrison by the calling code)
                ["removeTaskForce", [_taskForceId]] call FLO_fnc_TaskForceSystem;
                grpNull
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
                ["TaskForce", 3, format["Task Force %1 is already deployed", _taskForceId]] call FLO_fnc_log;
                
                // Try to get the existing infantry group if it exists
                private _existingGroup = grpNull;
                if (count _taskForceData > 15) then {
                    _existingGroup = _taskForceData select 15;
                    if (!isNull _existingGroup) then {
                        // Return the existing group if it's valid
                        _existingGroup
                    } else {
                        grpNull
                    };
                } else {
                    grpNull
                };
            };
            
            // Find direction toward BLUFOR territory
            private _bluforDirection = 0;
            
            // If we have a direction override (from defense line or alternative position), use it
            if (_directionOverride != -1) then {
                _bluforDirection = _directionOverride;
                ["TaskForce", 3, format["Using provided direction: %1", _bluforDirection]] call FLO_fnc_log;
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
                
                ["TaskForce", 3, format["Calculated direction to BLUFOR: %1", _bluforDirection]] call FLO_fnc_log;
            };
            
            // Create units based on composition
            private _allCreatedUnits = [];
            private _allCreatedGroups = [];
            
            // Check if we have an original garrison group to reuse
            private _infantryGroup = grpNull;
            private _originalGroupId = "";
            private _hasOriginalGroup = false;
            
            // Check if we received a garrison group with the pulled units
            if (_isDeployed && count _deployedUnits > 0) then {
                // The last element might be the garrison group if it was included
                private _lastElement = _deployedUnits select (count _deployedUnits - 1);
                
                if (_lastElement isEqualType grpNull) then {
                    // We got a group at the end of the array
                    _infantryGroup = _lastElement;
                    _originalGroupId = groupId _infantryGroup;
                    _hasOriginalGroup = true;
                    
                    // Remove the group from the deployed units array
                    _deployedUnits resize (count _deployedUnits - 1);
                    
                    ["TaskForce", 4, format["Reusing original garrison group: %1 with ID: %2", 
                        _infantryGroup, _originalGroupId]] call FLO_fnc_log;
                    
                    // IMPORTANT: We need to ensure this group is properly tracked
                    // Store the original group ID for later reference when cleaning up
                    _infantryGroup setVariable ["FLO_TaskForce_OriginalGroup", true, true];
                    _infantryGroup setVariable ["FLO_TaskForce_ID", _taskForceId, true];
                };
            };
            
            // Create infantry group if we don't have one from the garrison
            if (isNull _infantryGroup) then {
                _infantryGroup = createGroup [east, true];  // Added true for deleteWhenEmpty
                _infantryGroup setVariable ["FLO_TaskForce_ID", _taskForceId, true];
                ["TaskForce", 4, "Created new infantry group since no garrison group was available"] call FLO_fnc_log;
            };
            
            // Set the group ID to match the task force ID for easier identification
            // IMPORTANT CHANGE: Always set the group ID to the task force ID to prevent confusion
            _infantryGroup setGroupIdGlobal [_taskForceId];
            ["TaskForce", 4, format["Set infantry group ID to task force ID: %1", _taskForceId]] call FLO_fnc_log;
            
            // Store the original ID if we have one
            if (_hasOriginalGroup) then {
                ["TaskForce", 4, format["Original group ID was: %1 for task force: %2", _originalGroupId, _taskForceId]] call FLO_fnc_log;
                
                // Store in task force data that this is using a garrison group with the original name
                if (count _taskForceData < 18) then {
                    _taskForceData resize 18;
                };
                _taskForceData set [17, _originalGroupId]; // Store original group ID for tracking
            };
            
            // Track which types we've already added to prevent duplicates
            private _addedTypes = [];
            
            // First pass: Process infantry units to create a cohesive squad
            private _infantryUnits = _composition select {_x select 0 == "infantry"};
            private _totalInfantryCount = 0;
            
            // Calculate total infantry count
            {
                _x params ["_unitType", "_unitClasses", "_unitCount"];
                _totalInfantryCount = _totalInfantryCount + _unitCount;
            } forEach _infantryUnits;
            
            ["TaskForce", 4, format["Task Force %1 will create %2 infantry units from %3 composition elements", 
                _taskForceId, _totalInfantryCount, count _infantryUnits]] call FLO_fnc_log;
            
            // Debug log entire composition
            {
                _x params ["_elementType", "_elementClasses", "_elementCount"];
                ["TaskForce", 4, format["Composition element: Type: %1, Classes: %2, Count: %3", 
                    _elementType, _elementClasses, _elementCount]] call FLO_fnc_log;
            } forEach _composition;
            
            // Process infantry first
            {
                _x params ["_unitType", "_unitClasses", "_unitCount"];
                
                if (_unitType == "infantry" || _unitType == "at" || _unitType == "mg") then {
                    // Calculate spread based on squad size
                    private _spreadRadius = 5 + (_totalInfantryCount * 1.5);
                    _spreadRadius = _spreadRadius min 30; // Cap at 30m
                    
                    // Check if this is a virtualized task force
                    // If so, we need to check if we have existing units to pull from
                    // Otherwise, we will create new units
                    private _existingUnits = _deployedUnits select {_x isKindOf "Man" && alive _x};
                    private _existingUnitCount = count _existingUnits;
                    
                    if (_existingUnitCount > 0) then {
                        ["TaskForce", 4, format["Found %1 existing units for task force %2", 
                            _existingUnitCount, _taskForceId]] call FLO_fnc_log;
                            
                        // Add existing units to our infantry group
                        {
                            // Check if the unit is not already in our infantry group
                            if (group _x != _infantryGroup) then {
                                [_x] joinSilent _infantryGroup;
                                ["TaskForce", 4, format["Joined existing unit %1 to infantry group", _x]] call FLO_fnc_log;
                            };
                            
                            // Position the unit tactically
                            private _formationPos = [_position, _spreadRadius] call {
                                params ["_centerPos", "_radius"];
                                
                                // Use tactical positioning - create a scattered but coherent formation
                                private _posVariation = _radius * 0.8;
                                private _angle = random 360;
                                private _distance = random _posVariation;
                                
                                _centerPos getPos [_distance, _angle]
                            };

                            // Check if the unit is a fire observer
                            if (_x in East_FireObserver) then {
                                [_x, west] call FLO_fnc_fireObserver;
                                ["TaskForce", 4, format["Unit %1 is a fire observer, initializing fire observer functionality", _x]] call FLO_fnc_log;
                            };
                            
                            // Check for water and find land if needed
                            if (surfaceIsWater _formationPos) then {
                                _formationPos = [_formationPos, 0, 50, 5, 0, 0.1, 0] call BIS_fnc_findSafePos;
                            };
                            
                            // Move the unit to the position
                            _x setPos _formationPos;
                            _x setDir _bluforDirection;
                            
                            // Add to created units tracking list
                            _allCreatedUnits pushBack _x;
                        } forEach _existingUnits;
                        
                        // Remove the units from the deployed units array
                        _deployedUnits = _deployedUnits - _existingUnits;
                    };
                    
                    // Probably a new task force if we got here.
                    private _additionalUnitsNeeded = _unitCount - _existingUnitCount;
                    if (_additionalUnitsNeeded > 0) then {
                        ["TaskForce", 4, format["Creating %1 additional(Or New) infantry units for task force %2", 
                            _additionalUnitsNeeded, _taskForceId]] call FLO_fnc_log;
                            
                        for "_i" from 1 to _additionalUnitsNeeded do {
                            private _unitClass = "";
                            
                            // If we have a single class in the array, use it directly
                            if (count _unitClasses == 1) then {
                                _unitClass = _unitClasses#0;
                            } else {
                                // Select a unit type we haven't added yet, if possible
                                private _availableTypes = _unitClasses - _addedTypes;
                                if (count _availableTypes > 0) then {
                                    _unitClass = selectRandom _availableTypes;
                            } else {
                                _unitClass = selectRandom _unitClasses;
                                };
                            };
                            
                            // Track this type to avoid duplicates unless we need more of same type
                            _addedTypes pushBack _unitClass;
                            
                            // Create position in a tactical formation around the center point
                            private _formationPos = [_position, _spreadRadius] call {
                                params ["_centerPos", "_radius"];
                                
                                // Use tactical positioning - create a scattered but coherent formation
                                private _posVariation = _radius * 0.8;
                                private _angle = random 360;
                                private _distance = random _posVariation;
                                
                                _centerPos getPos [_distance, _angle]
                            };
                            
                            // Check for water and find land if needed
                            if (surfaceIsWater _formationPos) then {
                                _formationPos = [_formationPos, 0, 50, 5, 0, 0.1, 0] call BIS_fnc_findSafePos;
                            };
                            
                            private _unit = _infantryGroup createUnit [_unitClass, _formationPos, [], 5, "NONE"];
                            if (!isNull _unit) then {
                                // Ensure unit is on EAST side
                                [_unit] joinSilent _infantryGroup;
                                // Check if unit is a fire observer type
                                if (_unitClass in East_FireObserver) then {
                                    // Initialize as fire observer
                                    [_unit, EAST] call FLO_fnc_fireObserver;
                                    ["TaskForce", 4, format["Initialized unit of type %1 as fire observer in task force %2", _unitClass, _taskForceId]] call FLO_fnc_log;
                                };
                                // Set unit direction toward BLUFOR
                                _unit setDir _bluforDirection;
                                _allCreatedUnits pushBack _unit;
                            } else {
                                ["TaskForce", 1, format["Failed to create unit of type %1", _unitClass]] call FLO_fnc_log;
                            };
                        };
                    }
                };
            } forEach _composition;
            
            // Verify units were created
            if (count _allCreatedUnits == 0) exitWith {
                ["TaskForce", 1, format["Error: No units created for Task Force %1", _taskForceId]] call FLO_fnc_log;
                grpNull // Return grpNull instead of false
            };
            
            // Update Task Force data with the deployed elements
            _taskForceData set [1, _position];
            _taskForceData set [6, true]; // Set as deployed
            _taskForceData set [7, _allCreatedUnits]; // Store all created units
            _taskForceData set [14, false]; // Not virtualized
            
            // Store the infantry group in the task force data for easy access
            _taskForceData set [15, _infantryGroup];
            
            // Store all vehicle groups separately for easier access
            // Vehicles not longer deployed via TaskForceSystem
            _taskForceData set [16, _allCreatedGroups];
            
            // Store a flag indicating this is a fully-deployed task force with all components
            _taskForceData set [17, true]; // Indicates complete deployment with all components
            
            // Final debug log with summary info
            ["TaskForce", 4, format["DEPLOYMENT SUMMARY - Task Force: %1", _taskForceId]] call FLO_fnc_log;
            ["TaskForce", 4, format["- Total units created: %1", count _allCreatedUnits]] call FLO_fnc_log;
            ["TaskForce", 4, format["- DEPRECATED - Vehicle groups: %1", count _allCreatedGroups]] call FLO_fnc_log;
            ["TaskForce", 4, format["- Infantry units: %1", count (units _infantryGroup)]] call FLO_fnc_log;
            
            // Update both the local and global task force registries
            _taskForces set [_taskForceId, _taskForceData];
            _self set ["taskForces", _taskForces];
            
            // Also update the global backup
            FLO_Global_TaskForces set [_taskForceId, _taskForceData];
            
            ["TaskForce", 3, format["Successfully deployed Task Force %1 at position %2 with %3 units facing %4°",
                _taskForceId, _position, count _allCreatedUnits, _bluforDirection]] call FLO_fnc_log;
            ["TaskForce", 4, "====================================================================="] call FLO_fnc_log;
            
            // Return the infantry group
            _infantryGroup
        }],
        
        // Get information about a specific Task Force
        ["getTaskForce", {
            params ["_taskForceId", ["_returnGroup", false, [false]]];
            
            // Sanitize the task force ID to handle coordinates in the name
            private _originalId = _taskForceId;
            private _sanitizedId = _self call ["_sanitizeTaskForceId", [_taskForceId]];
            
            private _taskForces = _self get "taskForces";
            private _taskForceData = [];
            
            // Try both original and sanitized IDs
            if (_originalId in keys _taskForces) then {
                _taskForceData = _taskForces get _originalId;
            } else {
                if (_sanitizedId in keys _taskForces) then {
                    _taskForceData = _taskForces get _sanitizedId;
                } else {
                    // Check global backup if not found in local hashmap
                    if (!isNil "FLO_Global_TaskForces") then {
                        if (_originalId in keys FLO_Global_TaskForces) then {
                            _taskForceData = FLO_Global_TaskForces get _originalId;
                        } else {
                            if (_sanitizedId in keys FLO_Global_TaskForces) then {
                                _taskForceData = FLO_Global_TaskForces get _sanitizedId;
                            };
                        };
                    };
                };
            };
            
            // Return the group if requested and available
            if (_returnGroup && count _taskForceData > 15) then {
                _taskForceData select 15
            } else {
                _taskForceData
            };
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
                ["TaskForce", 1, format["No Task Forces found near position %1", _position]] call FLO_fnc_log;
                false
            };
            
            // Create a fortification Task Force to strengthen the line
            _self call ["createTaskForce", ["", "fortification", "squad", "", "", []]];
            
            // Deploy the Task Force at the position
            _self call ["deployTaskForce", [_taskForceId, _position, true]];
            
            ["TaskForce", 1, format["Reinforced defensive line at %1", _position]] call FLO_fnc_log;
            true
        }],
        
        // Utility function to sanitize task force IDs
        ["_sanitizeTaskForceId", {
            params ["_taskForceId"];
            private _sanitizedId = _taskForceId;
            
            // Check if the ID contains coordinates (using square bracket as indicator)
            if (_taskForceId find "[" > 0) then {
                // Extract main parts of the ID
                private _parts = _taskForceId splitString "_";
                if (count _parts >= 3) then {
                    // Keep the prefix and number, replace the coordinates part
                    _sanitizedId = format ["%1_OutpMark_%2", _parts#0, _parts#(count _parts - 1)];
                };
            };
            
            _sanitizedId
        }],
        
        // Method to properly remove a task force and clean up resources
        // If you are wondering why this is so complicated, it's because we need to handle all aspects of task force removal
        // Task Forces carry a lot of data, and we need to make sure we remove all of it properly
        ["_removeTaskForce", {
            params ["_taskForceId"];
            
            // Add detailed debug logging for tracking task force removal
            ["TaskForce", 4, format["Starting removal of task force %1", _taskForceId]] call FLO_fnc_log;
            
            // Sanitize the task force ID to handle coordinates in the name
            private _originalId = _taskForceId;
            private _sanitizedId = _self call ["_sanitizeTaskForceId", [_taskForceId]];
            
            ["TaskForce", 4, format["Original ID: %1, Sanitized ID: %2", _originalId, _sanitizedId]] call FLO_fnc_log;
            
            // Get the Task Force data using dual lookup
            private _taskForces = _self getOrDefault ["taskForces", createHashMap];
            private _taskForceData = nil;
            
            // Check both original and sanitized IDs in the local registry
            if (_originalId in keys _taskForces) then {
                _taskForceData = _taskForces get _originalId;
                _taskForceId = _originalId;
                ["TaskForce", 4, format["Found task force with original ID in local registry"]] call FLO_fnc_log;
            } else {
                if (_sanitizedId in keys _taskForces) then {
                    _taskForceData = _taskForces get _sanitizedId;
                    _taskForceId = _sanitizedId;
                    ["TaskForce", 4, format["Found task force with sanitized ID in local registry"]] call FLO_fnc_log;
                } else {
                    // Check global backup hashmap
                    if (!isNil "FLO_Global_TaskForces") then {
                        if (_originalId in keys FLO_Global_TaskForces) then {
                            _taskForceData = FLO_Global_TaskForces get _originalId;
                            _taskForceId = _originalId;
                            ["TaskForce", 4, format["Found task force with original ID in global registry"]] call FLO_fnc_log;
                        } else {
                            if (_sanitizedId in keys FLO_Global_TaskForces) then {
                                _taskForceData = FLO_Global_TaskForces get _sanitizedId;
                                _taskForceId = _sanitizedId;
                                ["TaskForce", 4, format["Found task force with sanitized ID in global registry"]] call FLO_fnc_log;
                            };
                        };
                    };
                };
            };
            
            // If task force not found, exit
            if (isNil "_taskForceData") exitWith {
                ["TaskForce", 1, format["Error: Task Force %1 not found for removal", _taskForceId]] call FLO_fnc_log;
                false
            };
            
            // Extract task force data
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
            
            // Return any garrison-extracted units first
            if (!isNil "FLO_AI_Commander") then {
                // Check if this task force has a source marker in the integration system
                private _taskForceSourceMap = FLO_AI_Commander get "_taskForceSourceMap";
                
                if (_taskForceId in keys _taskForceSourceMap) then {
                    private _sourceMarker = _taskForceSourceMap get _taskForceId;
                    ["TaskForce", 4, format["Returning units to source garrison at %1 for Task Force %2", 
                        _sourceMarker, _taskForceId]] call FLO_fnc_log;
                    
                    // Return units to their original garrison using the improved returnUnits method
                    FLO_AI_Commander call ["_returnUnitsToGarrison", [_taskForceId, _sourceMarker, _deployedUnits]];
                };
            };
            
            // Delete all deployed units, even if they're far away
            {
                if (!isNull _x) then {
                    if (_x isKindOf "Man") then {
                        private _group = group _x;
                        
                        // Check if this unit was extracted from a garrison
                        private _fromGarrison = _x getVariable ["FLO_Original_Garrison", ""];
                        
                        // Only delete units not returning to garrison
                        if (_fromGarrison == "") then {
                            deleteVehicle _x;
                        };
                        // Don't delete group yet, check if empty later
                    } else {
                        // Handle vehicles - delete crew first, checking garrison origin
                        {
                            // Check if crew member is from a garrison
                            private _fromGarrison = _x getVariable ["FLO_Original_Garrison", ""];
                            
                            // Only delete crew not returning to garrison
                            if (_fromGarrison == "") then {
                                deleteVehicle _x;
                            };
                        } forEach (crew _x);
                        
                        // Delete the vehicle itself
                        deleteVehicle _x;
                    };
                };
            } forEach _deployedUnits;
            
            // Find and clean up all groups related to this task force using enhanced detection
            {
                private _group = _x;
                private _isRelatedGroup = false;
                
                // Check if group is still valid
                if (!isNull _group) then {
                    // Check if group is related to this task force through any of these methods:
                    // 1. Group has our task force ID variable
                    if (_group getVariable ["FLO_TaskForce_ID", ""] == _taskForceId) then {
                        _isRelatedGroup = true;
                        ["TaskForce", 4, format["Found related group %1 via variable for Task Force %2", 
                            groupId _group, _taskForceId]] call FLO_fnc_log;
                    };
                    
                    // 2. Group ID contains our task force ID
                    if (!_isRelatedGroup && {groupId _group find _taskForceId > -1}) then {
                        _isRelatedGroup = true;
                        ["TaskForce", 4, format["Found related group %1 via groupId for Task Force %2", 
                            groupId _group, _taskForceId]] call FLO_fnc_log;
                    };
                    
                    // 3. Group string contains our task force ID
                    if (!_isRelatedGroup && {str _group find _taskForceId > -1}) then {
                        _isRelatedGroup = true;
                        ["TaskForce", 4, format["Found related group %1 via string representation for Task Force %2", 
                            groupId _group, _taskForceId]] call FLO_fnc_log;
                    };
                    
                    // 4. Check if this is an extract group from a garrison
                    if (!_isRelatedGroup && {groupId _group find "TF_EX_" > -1 && {_group getVariable ["FLO_Requester_ID", ""] == _taskForceId}}) then {
                        _isRelatedGroup = true;
                        ["TaskForce", 4, format["Found related extraction group %1 for Task Force %2", 
                            groupId _group, _taskForceId]] call FLO_fnc_log;
                    };
                    
                    // If it's related, clean it up
                    if (_isRelatedGroup) then {
                        // First check if any units need to return to garrison
                        private _unitsToPreserve = [];
                        
                        {
                            private _unit = _x;
                            private _fromGarrison = _unit getVariable ["FLO_Original_Garrison", ""];
                            
                            // If unit is from a garrison, add it to preserve list
                            if (_fromGarrison != "") then {
                                _unitsToPreserve pushBack _unit;
                            } else {
                                // Otherwise, delete the unit
                                deleteVehicle _unit;
                            };
                        } forEach units _group;
                        
                        // If there are units to preserve, don't delete the group
                        if (count _unitsToPreserve > 0) then {
                            ["TaskForce", 4, format["Preserving %1 units from group %2 for return to garrison", 
                                count _unitsToPreserve, groupId _group]] call FLO_fnc_log;
                        } else {
                            // If no units to preserve, delete the group
                            deleteGroup _group;
                            ["TaskForce", 4, format["Deleted related group %1 for Task Force %2", 
                                groupId _group, _taskForceId]] call FLO_fnc_log;
                        };
                    };
                };
            } forEach allGroups;
            
            // Check if this task force is using a garrison group with preserved name
            private _originalGroupId = "";
            if (count _taskForceData > 18) then {
                _originalGroupId = _taskForceData select 18;
            };
            
            // If we have an original group ID, also clean up any groups with that exact ID
            if (_originalGroupId != "") then {
                {
                    private _group = _x;
                    
                    if (groupId _group == _originalGroupId) then {
                        // Found a match with original ID - clean up
                        ["TaskForce", 4, format["Found task force group with original garrison ID: %1", _originalGroupId]] call FLO_fnc_log;
                        
                        // Check for units from garrison before deleting
                        private _unitsToPreserve = [];
                        
                        {
                            private _unit = _x;
                            private _fromGarrison = _unit getVariable ["FLO_Original_Garrison", ""];
                            
                            // If unit is from a garrison, add it to preserve list
                            if (_fromGarrison != "") then {
                                _unitsToPreserve pushBack _unit;
                            } else {
                                // Otherwise, delete the unit
                                deleteVehicle _unit;
                            };
                        } forEach units _group;
                        
                        // If there are units to preserve, don't delete the group
                        if (count _unitsToPreserve > 0) then {
                            ["TaskForce", 4, format["Preserving %1 units from original group for return to garrison", 
                                count _unitsToPreserve]] call FLO_fnc_log;
                        } else {
                            // If no units to preserve, delete the group
                            deleteGroup _group;
                            ["TaskForce", 4, format["Deleted group with original garrison ID: %1", _originalGroupId]] call FLO_fnc_log;
                        };
                    };
                } forEach allGroups;
            };
            
            // Check if task force has a specific infantry group (index 15)
            private _infantryGroup = grpNull;
            if (count _taskForceData > 15) then {
                _infantryGroup = _taskForceData select 15;
                
                // Delete the group and its units if it exists
                if (!isNull _infantryGroup) then {
                    // Check for units from garrison before deleting
                    private _unitsToPreserve = [];
                    
                    {
                        private _unit = _x;
                        private _fromGarrison = _unit getVariable ["FLO_Original_Garrison", ""];
                        
                        // If unit is from a garrison, add it to preserve list
                        if (_fromGarrison != "") then {
                            _unitsToPreserve pushBack _unit;
                        } else {
                            // Otherwise, delete the unit
                            deleteVehicle _unit;
                        };
                    } forEach units _infantryGroup;
                    
                    // If there are units to preserve, don't delete the group
                    if (count _unitsToPreserve > 0) then {
                        ["TaskForce", 4, format["Preserving %1 units from infantry group for return to garrison", 
                            count _unitsToPreserve]] call FLO_fnc_log;
                    } else {
                        // If no units to preserve, delete the group
                        deleteGroup _infantryGroup;
                        ["TaskForce", 4, format["Deleted infantry group for Task Force %1", _taskForceId]] call FLO_fnc_log;
                    };
                };
            };
            
            // Check if we have vehicle data (index 16)
            if (count _taskForceData > 16) then {
                private _vehicleGroups = _taskForceData select 16;
                
                // Delete all vehicle groups and their crews
                {
                    private _vehGroup = _x;
                    
                    // Check if group is valid
                    if (!isNull _vehGroup) then {
                        // Check for crew members from garrison before deleting
                        private _unitsToPreserve = [];
                        
                        {
                            private _unit = _x;
                            private _fromGarrison = _unit getVariable ["FLO_Original_Garrison", ""];
                            
                            // If unit is from a garrison, add it to preserve list
                            if (_fromGarrison != "") then {
                                _unitsToPreserve pushBack _unit;
                            } else {
                                // Otherwise, delete the unit
                                deleteVehicle _unit;
                            };
                        } forEach units _vehGroup;
                        
                        // If there are units to preserve, don't delete the group
                        if (count _unitsToPreserve > 0) then {
                            ["TaskForce", 4, format["Preserving %1 units from vehicle group for return to garrison", 
                                count _unitsToPreserve]] call FLO_fnc_log;
                        } else {
                            // If no units to preserve, delete the group
                            deleteGroup _vehGroup;
                            ["TaskForce", 4, format["Deleted vehicle group %1 for Task Force %2", _vehGroup, _taskForceId]] call FLO_fnc_log;
                        };
                    };
                } forEach _vehicleGroups;
                
                ["TaskForce", 4, format["Processed %1 vehicle groups for Task Force %2", count _vehicleGroups, _taskForceId]] call FLO_fnc_log;
            };
            
            // Remove the cooling tracker for this task force
            if (!isNil "FLO_TaskForce_StateChanges" && {_taskForceId in keys FLO_TaskForce_StateChanges}) then {
                FLO_TaskForce_StateChanges deleteAt _taskForceId;
                ["TaskForce", 4, format["Removed task force %1 from state changes tracker", _taskForceId]] call FLO_fnc_log;
            };
            
            // Clean up from integration system as well
            if (!isNil "FLO_AI_Commander") then {
                private _taskForceSourceMap = FLO_AI_Commander get "_taskForceSourceMap";
                if (_taskForceId in keys _taskForceSourceMap) then {
                    _taskForceSourceMap deleteAt _taskForceId;
                    ["TaskForce", 4, format["Removed task force %1 from AI Commander", _taskForceId]] call FLO_fnc_log;
                };
            };
            
            // Finally, clean from all registries
            // Remove from local registry
            _taskForces deleteAt _taskForceId;
            
            // Remove from global registry
            if (!isNil "FLO_Global_TaskForces") then {
                // Check both original and sanitized IDs
                if (_originalId in keys FLO_Global_TaskForces) then {
                    FLO_Global_TaskForces deleteAt _originalId;
                    ["TaskForce", 4, format["Removed task force %1 from global registry (original ID)", _originalId]] call FLO_fnc_log;
                };
                
                if (_sanitizedId in keys FLO_Global_TaskForces) then {
                    FLO_Global_TaskForces deleteAt _sanitizedId;
                    ["TaskForce", 4, format["Removed task force %1 from global registry (sanitized ID)", _sanitizedId]] call FLO_fnc_log;
                };
            };
            
            ["TaskForce", 1, format["Successfully removed Task Force %1 from all registries", _taskForceId]] call FLO_fnc_log;
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
            ["_targetMarker", "", [""]],
            ["_providedTaskForceId", "", [""]],
            ["_providedComposition", [], [[]]]
        ];
        
        private _self = FLO_TaskForce_System;
        
        // We need to ensure the HashMapObject is properly initialized
        if (isNil {_self getOrDefault ["taskForces", nil]}) then {
            _self set ["taskForces", createHashMap];
            diag_log "[FLO][TaskForce] Created new taskForces hashmap";
        };
        
        _result = _self call ["createTaskForce", [_baseMarker, _taskForceType, _taskForceSize, _targetMarker, _providedTaskForceId, _providedComposition]];
    };
    
    // Remove an existing Task Force and clean up all resources
    case "removeTaskForce": {
        _params params [
            ["_taskForceId", "", [""]]
        ];
        
        private _self = FLO_TaskForce_System;
        _result = _self call ["_removeTaskForce", [_taskForceId]];
    };
    
    // Update all Task Force positions and statuses
    case "updateTaskForces": {
        private _self = FLO_TaskForce_System;
        _self call ["updateTaskForces", []];
    };
    
    // Get information about a specific Task Force
    case "getTaskForce": {
        _params params [
            ["_taskForceId", "", [""]],
            ["_returnGroup", false, [false]]
        ];
        
        private _self = FLO_TaskForce_System;
        _result = _self call ["getTaskForce", [_taskForceId, _returnGroup]];
    };
    
    // Deploy a Task Force at a specific position
    case "deployTaskForce": {
        _params params [
            ["_taskForceId", "", [""]],
            ["_position", [0,0,0], [[]]]
        ];
        
        private _self = FLO_TaskForce_System;
        _result = _self call ["deployTaskForce", [_taskForceId, _position]];
        
        // Log whether we got a group back (for debugging)
        if (_result isEqualType grpNull) then {
            ["TaskForce", 4, format["deployTaskForce returned group %1", _result]] call FLO_fnc_log;
        } else {
            ["TaskForce", 4, format["deployTaskForce returned unexpected result type (%1) for task force ID: %2", typeName _result, _taskForceId]] call FLO_fnc_log;
        };
    };
};

_result