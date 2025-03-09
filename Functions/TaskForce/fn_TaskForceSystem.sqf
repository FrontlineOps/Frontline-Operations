/*
    Function: FLO_fnc_TaskForceSystem
    
    Description:
    Manages OPFOR Task Forces that move across the map and appear when near BLUFOR.
    Fully compatible with CDVS Virtualization system.
    Allows creation of defensive lines with fortifications, infantry, and vehicles.
    
    Parameters:
     None
    
    Returns:
     Nothing
    
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
            diag_log "[FLO][TaskForce] Created new taskForces hashmap";
            _self set ["activatedTaskForces", createHashMap];
            _self set ["lastUpdate", time];
            _self set ["lastTaskForceId", 0];
            _self set ["lastTaskForceScan", time];
            _self set ["virtualizationBuffer", 300];
            _self set ["virtualizationCooldown", 60];
            _self call ["initialize",[]];
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
            //         FLO_TaskForce_System call ["updateTaskForces", []];
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
                ["TaskForce", 1, format["Error: Insufficient resources to create Task Force (needed %1, have %2)",
                    _resourceCost, _currentResources]] call FLO_fnc_log;
                ""
            };
            
            // Spend the resources
            ["spend", [_resourceCost]] call FLO_fnc_opforResources;
            
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
           _self get ["taskForces"] set [_taskForceId, _taskForceData];
            
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
            params ["_taskForceId", "_position", "_defensive"];
            
            // Start intensive debug logging
            ["TaskForce", 4, "====================================================================="] call FLO_fnc_log;
            ["TaskForce", 4, format["Starting deployment process for task force %1", _taskForceId]] call FLO_fnc_log;
            ["TaskForce", 4, format["Deployment position: %1, Defensive mode: %2", _position, _defensive]] call FLO_fnc_log;
            
            // Sanitize the task force ID to handle coordinates in the name
            private _originalId = _taskForceId;
            private _sanitizedId = _self call ["_sanitizeTaskForceId", [_taskForceId]];
            ["TaskForce", 4, format["Original ID: %1, Sanitized ID: %2", _originalId, _sanitizedId]] call FLO_fnc_log;
            
            // Get the Task Force data using dual lookup
            private _taskForces = _self get ["taskForces"];
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
                FLO_TaskForce_System call ["removeTaskForce", [_taskForceId]];
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
                    
                    // Check if we already have some deployed units for this task force
                    // These would be units pulled from a garrison that are ready to join our group
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
                    
                    // Only create new units if we need additional ones beyond what we pulled from the garrison
                    private _additionalUnitsNeeded = _unitCount - _existingUnitCount;
                    if (_additionalUnitsNeeded > 0) then {
                        ["TaskForce", 4, format["Creating %1 additional infantry units for task force %2", 
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
            
            // Second pass: Process fire observers
            {
                _x params ["_unitType", "_unitClasses", "_unitCount"];
                
                if (_unitType == "fireObserver") then {
                        for "_i" from 1 to _unitCount do {
                        private _unitClass = selectRandom _unitClasses;
                            
                            // Place fire observer in a tactically advantageous position
                        // Usually slightly separated from main infantry
                        private _observerPos = _position getPos [25 + random 15, random 360];
                            
                            // Check for water and find land if needed
                        if (surfaceIsWater _observerPos) then {
                            _observerPos = [_observerPos, 0, 100, 5, 0, 0.1, 0] call BIS_fnc_findSafePos;
                            };
                            
                        private _unit = _infantryGroup createUnit [_unitClass, _observerPos, [], 5, "NONE"];
                            if (!isNull _unit) then {
                                // Ensure unit is on EAST side
                                [_unit] joinSilent _infantryGroup;
                                // Set unit direction toward BLUFOR
                                _unit setDir _bluforDirection;
                                // Initialize as fire observer
                                [_unit, EAST] call FLO_fnc_fireObserver;
                                _allCreatedUnits pushBack _unit;
                                
                                ["TaskForce", 4, format["Created fire observer of type %1 in task force %2", _unitClass, _taskForceId]] call FLO_fnc_log;
                            } else {
                                ["TaskForce", 1, format["Failed to create fire observer of type %1", _unitClass]] call FLO_fnc_log;
                            };
                        };
                    };
            } forEach _composition;
            
            // Third pass: Process vehicles with better positioning
            private _vehicleElements = _composition select {_x select 0 == "vehicle"};
            private _vehicleCount = 0;
            
            ["TaskForce", 4, format["Found %1 vehicle elements in composition", count _vehicleElements]] call FLO_fnc_log;
            
            if (count _vehicleElements > 0) then {
                // Calculate a good vehicle staging area close to but separate from infantry
                // Use base outpost or current position depending on context
                private _vehicleStagingArea = [_position, _basePos] select (_position distance _basePos < 100);
                
                // Find a safe vehicle assembly area
                private _vehicleAssemblyPos = [_vehicleStagingArea, 100, 300, 20, 0, 0.25, 0] call BIS_fnc_findSafePos;
                
                ["TaskForce", 4, format["Using vehicle assembly area at %1 for task force %2 (base position: %3, deployment position: %4)", 
                    _vehicleAssemblyPos, _taskForceId, _basePos, _position]] call FLO_fnc_log;
                
                // Create each vehicle
                {
                    _x params ["_unitType", "_unitClasses", "_unitCount"];
                    
                    if (_unitType == "vehicle") then {
                        ["TaskForce", 4, format["Processing vehicle element with %1 vehicles of types: %2", 
                            _unitCount, _unitClasses]] call FLO_fnc_log;
                        
                        for "_i" from 1 to _unitCount do {
                            // Select a good vehicle class based on situation
                            private _vehicleClass = "";
                            
                            if (count _unitClasses == 1) then {
                                _vehicleClass = _unitClasses#0;
                            } else {
                                // Try to select an appropriate vehicle based on task force type
                                // If task force ID contains hints, use those
                                switch (true) do {
                                    case (_taskForceId find "ARMOR" > -1): {
                                        // Filter for actual tanks if available
                                        private _tanks = _unitClasses select {_x find "MBT" > -1 || _x find "tank" > -1};
                                        if (count _tanks > 0) then {
                                            _vehicleClass = selectRandom _tanks;
                            } else {
                                _vehicleClass = selectRandom _unitClasses;
                                        };
                                    };
                                    case (_taskForceId find "MECH" > -1): {
                                        // Filter for APCs if available
                                        private _apcs = _unitClasses select {_x find "APC" > -1};
                                        if (count _apcs > 0) then {
                                            _vehicleClass = selectRandom _apcs;
                                        } else {
                                            _vehicleClass = selectRandom _unitClasses;
                                        };
                                    };
                                    case (_type == "mechanized"): {
                                        // Prefer wheeled vehicles for mechanized
                                        private _wheeled = _unitClasses select {_x find "MRAP" > -1 || _x find "Wheeled" > -1};
                                        if (count _wheeled > 0) then {
                                            _vehicleClass = selectRandom _wheeled;
                                        } else {
                                            _vehicleClass = selectRandom _unitClasses;
                                        };
                                    };
                                    default {
                                        _vehicleClass = selectRandom _unitClasses;
                                    };
                                };
                            };
                            
                            ["TaskForce", 4, format["Selected vehicle class: %1 for vehicle %2 of %3", 
                                _vehicleClass, _i, _unitCount]] call FLO_fnc_log;
                            
                            // Calculate position with good spacing between vehicles
                            // Each subsequent vehicle is positioned in a tactical formation
                            private _vehiclePos = [_vehicleAssemblyPos, _vehicleCount] call {
                                params ["_basePos", "_index"];
                                
                                // First vehicle goes at assembly point
                                if (_index == 0) exitWith {_basePos};
                                
                                // Additional vehicles form a line or wedge
                                private _spacing = 20; // meters between vehicles
                                private _formationDir = _bluforDirection;
                                
                                // Create a line formation facing the enemy
                                private _posOffset = [
                                    sin (_formationDir + 90) * _spacing * _index,
                                    cos (_formationDir + 90) * _spacing * _index,
                                    0
                                ];
                                
                                (_basePos vectorAdd _posOffset)
                            };
                            
                            // Find a safe position nearby if exact spot isn't good
                            private _rawVehiclePos = +_vehiclePos; // Store original for debugging
                            _vehiclePos = [_vehiclePos, 0, 50, 10, 0, 0.5, 0] call BIS_fnc_findSafePos;
                            
                            ["TaskForce", 4, format["Vehicle position: Original: %1, Safe: %2", 
                                _rawVehiclePos, _vehiclePos]] call FLO_fnc_log;
                            
                            // Check for water
                            if (surfaceIsWater _vehiclePos) then {
                                private _oldPos = +_vehiclePos;
                                _vehiclePos = [_vehicleAssemblyPos, 50, 200, 15, 0, 0.25, 0] call BIS_fnc_findSafePos;
                                ["TaskForce", 4, format["Relocated vehicle from water position %1 to %2", 
                                    _oldPos, _vehiclePos]] call FLO_fnc_log;
                            };
                            
                            ["TaskForce", 4, format["Creating vehicle %1 at position %2 for task force %3", 
                                _vehicleClass, _vehiclePos, _taskForceId]] call FLO_fnc_log;
                            
                            private _vehicle = createVehicle [_vehicleClass, _vehiclePos, [], 0, "NONE"];
                            _vehicleCount = _vehicleCount + 1;
                            
                            if (!isNull _vehicle) then {
                                _vehicle call {
                                    private _vehicle = _this;
                                    
                                    // Verify the vehicle exists after creation
                                    if (alive _vehicle) then {
                                        ["TaskForce", 4, format["Vehicle %1 successfully created at %2", 
                                            _vehicleClass, getPos _vehicle]] call FLO_fnc_log;
                                    } else {
                                        ["TaskForce", 1, format["ERROR: Vehicle %1 created but not alive", _vehicleClass]] call FLO_fnc_log;
                                    };
                                };
                                
                                // Set vehicle facing direction toward enemy
                                _vehicle setDir _bluforDirection;
                                
                                // Create crew with appropriate skill
                                private _vehicleGroup = createGroup [east, true];
                                createVehicleCrew _vehicle;
                                
                                // Check if any crew members are NOT east side and fix them
                                {
                                    if (side _x != east) then {
                                        ["TaskForce", 2, format["Crew member %1 has incorrect side %2, fixing to EAST", _x, side _x]] call FLO_fnc_log;
                                        
                                        // Get position and role
                                        private _unitPos = getPosATL _x;
                                        private _unitType = typeOf _x;
                                        private _role = assignedVehicleRole _x;
                                        
                                        // Remove incorrect crew member
                                        _x leaveVehicle _vehicle;
                                        deleteVehicle _x;
                                        
                                        // Create new crew member with correct side
                                        private _newUnit = _vehicleGroup createUnit [_unitType, [0,0,0], [], 0, "NONE"];
                                        
                                        // Assign to correct vehicle role
                                        if (count _role > 0) then {
                                            switch (_role select 0) do {
                                                case "driver": { _newUnit assignAsDriver _vehicle; _newUnit moveInDriver _vehicle; };
                                                case "gunner": { _newUnit assignAsGunner _vehicle; _newUnit moveInGunner _vehicle; };
                                                case "commander": { _newUnit assignAsCommander _vehicle; _newUnit moveInCommander _vehicle; };
                                                case "turret": { _newUnit assignAsTurret [_vehicle, _role select 1]; _newUnit moveInTurret [_vehicle, _role select 1]; };
                                                case "cargo": { _newUnit assignAsCargo _vehicle; _newUnit moveInCargo _vehicle; };
                                                default { _newUnit moveInAny _vehicle; };
                                            };
                                        } else {
                                            _newUnit moveInAny _vehicle;
                                        };
                                    } else {
                                        // If side is correct, just move to our group
                                        [_x] joinSilent _vehicleGroup;
                                    };
                                } forEach (crew _vehicle);
                                
                                // Set group ID for easier identification
                                _vehicleGroup setGroupIdGlobal [format ["%1_Vehicle_%2", _taskForceId, _vehicleCount]];
                                
                                // Mark this group as belonging to this task force to ensure proper cleanup
                                _vehicleGroup setVariable ["FLO_TaskForce_ID", _taskForceId, true];
                                _vehicleGroup setVariable ["FLO_TaskForce_VehicleGroup", true, true];
                                
                                // Ensure all crew are in the right group
                                {
                                    [_x] joinSilent _vehicleGroup;
                                } forEach (crew _vehicle);
                                
                                // Track created units and groups
                                _allCreatedUnits pushBack _vehicle;
                                _allCreatedUnits append (crew _vehicle);
                                _allCreatedGroups pushBack _vehicleGroup;
                                
                                // Track the relationship between vehicle and its group for later cleanup
                                _vehicle setVariable ["FLO_TaskForce_VehicleGroup", _vehicleGroup, true];
                                
                                ["TaskForce", 4, format["Successfully created vehicle %1 with crew for task force %2. Crew members: %3", 
                                    _vehicleClass, _taskForceId, count (crew _vehicle)]] call FLO_fnc_log;
                            } else {
                                ["TaskForce", 1, format["ERROR: Failed to create vehicle of type %1", _vehicleClass]] call FLO_fnc_log;
                            };
                        };
                    };
                } forEach _composition;
            };
            
            // Final pass: Process fortifications
            {
                _x params ["_unitType", "_unitClasses", "_unitCount"];
                
                if (_unitType == "fortification") then {
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
                                ["TaskForce", 4, format["Relocated fortification from water to %1", _fortPos]] call FLO_fnc_log;
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
                                ["TaskForce", 1, format["Failed to create fortification of type %1", _fortClass]] call FLO_fnc_log;
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
                                ["TaskForce", 1, format["Failed to create fortification of type %1", _fortClass]] call FLO_fnc_log;
                            };
                        };
                    };
                };
            } forEach _composition;
            
            // Verify units were created
            if (count _allCreatedUnits == 0) exitWith {
                ["TaskForce", 1, format["Error: No units created for Task Force %1", _taskForceId]] call FLO_fnc_log;
                grpNull // Return grpNull instead of false
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
            
            // Update Task Force data with the deployed elements
            _taskForceData set [1, _position];
            _taskForceData set [6, true]; // Set as deployed
            _taskForceData set [7, _allCreatedUnits]; // Store all created units
            _taskForceData set [14, false]; // Not virtualized
            
            // Store the infantry group in the task force data for easy access
            _taskForceData set [15, _infantryGroup];
            
            // Store all vehicle groups separately for easier access
            _taskForceData set [16, _allCreatedGroups];
            
            // Store a flag indicating this is a fully-deployed task force with all components
            _taskForceData set [17, true]; // Indicates complete deployment with all components
            
            // Final debug log with summary info
            ["TaskForce", 4, format["DEPLOYMENT SUMMARY - Task Force: %1", _taskForceId]] call FLO_fnc_log;
            ["TaskForce", 4, format["- Total units created: %1", count _allCreatedUnits]] call FLO_fnc_log;
            ["TaskForce", 4, format["- Vehicle groups: %1", count _allCreatedGroups]] call FLO_fnc_log;
            ["TaskForce", 4, format["- Infantry units: %1", count (units _infantryGroup)]] call FLO_fnc_log;
            
            // Update both the local and global task force registries
            _taskForces set [_taskForceId, _taskForceData];
            _self set ["taskForces", _taskForces];
            
            // Also update the global backup
            FLO_Global_TaskForces set [_taskForceId, _taskForceData];
            
            ["TaskForce", 3, format["Successfully deployed Task Force %1 at position %2 with %3 units facing %4°",
                _taskForceId, _position, count _allCreatedUnits, _bluforDirection]] call FLO_fnc_log;
            ["TaskForce", 4, "====================================================================="] call FLO_fnc_log;

            // Log whether we got a group back (for debugging)
            if (_infantryGroup isEqualType grpNull) then {
                ["TaskForce", 4, format["deployTaskForce returned group %1", _result]] call FLO_fnc_log;
            } else {
                ["TaskForce", 4, format["deployTaskForce returned unexpected result type (%1) for task force ID: %2", typeName _result, _taskForceId]] call FLO_fnc_log;
            };
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
            private _taskForces = _self get ["taskForces"];
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
            if (!isNil "FLO_TaskForce_Garrison_Integration") then {
                // Check if this task force has a source marker in the integration system
                private _taskForceSourceMap = FLO_TaskForce_Garrison_Integration get "_taskForceSourceMap";
                
                if (_taskForceId in keys _taskForceSourceMap) then {
                    private _sourceMarker = _taskForceSourceMap get _taskForceId;
                    ["TaskForce", 4, format["Returning units to source garrison at %1 for Task Force %2", 
                        _sourceMarker, _taskForceId]] call FLO_fnc_log;
                    
                    // Return units to their original garrison using the improved returnUnits method
                    FLO_TaskForce_Garrison_Integration call ["_returnUnitsToGarrison", [_taskForceId, _sourceMarker, _deployedUnits]];
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
            if (!isNil "FLO_TaskForce_Garrison_Integration") then {
                private _taskForceSourceMap = FLO_TaskForce_Garrison_Integration get "_taskForceSourceMap";
                if (_taskForceId in keys _taskForceSourceMap) then {
                    _taskForceSourceMap deleteAt _taskForceId;
                    ["TaskForce", 4, format["Removed task force %1 from garrison integration system", _taskForceId]] call FLO_fnc_log;
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
        }],
        //Serializes current state into plain hashmap
        ["serialize",{
            createhashmapfromarray [
                ["taskForces", _self get "taskForces"],
                ["activatedTaskForces", _self get "activatedTaskForces"],
                ["lastTaskForceId", _self get "lastTaskForceId"],
                ["virtualizationBuffer", _self get "virtualizationBuffer"],
                ["virtualizationCooldown", _self get "virtualizationCooldown"]
            ];
        }],
        //Deserializes from plain hashmap and sets last saved state
        ["deserialize",{
            params ["dto"];
            _self set ["taskForces", _dto get "taskForces"];
            _self set ["activatedTaskForces", _dto get "activatedTaskForces"];
            _self set ["lastTaskForceId", _dto get "lastTaskForceId"];
            _self set ["virtualizationBuffer", _dto get "virtualizationBuffer"];
            _self set ["virtualizationCooldown", _dto get "virtualizationCooldown"];
        }]
    ];
    
    // Create the TaskForceSystem with specified parameters
    FLO_TaskForce_System = createHashMapObject [_taskForceSystemClass];
    
   //Load data from data map
   private _dto = FLO_dataMap get ["FLO_TaskForce_System"];
   if !(isNil "_dto") then {FLO_TaskForce_System call ["deserailize", [_dto]]};
};