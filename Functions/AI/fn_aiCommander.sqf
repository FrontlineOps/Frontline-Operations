/*
 * Function: FLO_fnc_aiCommander
 * Author: Azraeelian Angel
 * Description:
 * Creates an AI Commander that controls overall OPFOR operations.
 * Sets operation modes (Attack, Defend, Skirmish) and coordinates task forces.
 *
 * Arguments:
 * 0: Operation Mode <STRING> - "ATTACK", "DEFEND", "SKIRMISH" (Optional, default: "DEFEND")
 *
 * Return Value:
 * AI Commander HashMap Object <HASHMAP>
 *
 * Example:
 * ["ATTACK"] call FLO_fnc_aiCommander;
 */

params [["_operationMode", "DEFEND", [""]]];

// Log function start
["AI Commander", 3, format["Starting AI Commander with operation mode: %1", _operationMode]] call FLO_fnc_log;

// Initialize variables
private _hasSpecialOps = false;
private _lastCommanderUpdate = diag_tickTime;
private _commanderUpdateInterval = 300; // 5 minutes between strategy updates
private _specialOpsUpdateInterval = 900; // 15 minutes between special ops deployments
private _lastSpecialOpsTime = diag_tickTime - 600; // Start with a delay
private _currentThreatLevel = 0;
private _threatThreshold = 0.6; // Threshold to switch to defensive mode if under heavy attack
private _taskForceStrengthFactor = 1.0; // Multiplier for task force size

// Set up the Commander object using a HashMap
private _aiCommander = createHashMapObject [[
    ["_operationMode", _operationMode],
    ["_hasSpecialOps", _hasSpecialOps],
    ["_threatLevel", _currentThreatLevel],
    ["_lastUpdate", _lastCommanderUpdate],
    ["_lastSpecialOps", _lastSpecialOpsTime],
    ["_activeTasks", createHashMap],
    ["_outpostStatus", createHashMap],
    ["_taskForcePool", []],
    ["_taskForceSourceMap", createHashMap], // Maps task force IDs to their source outposts
    ["_garrisonContributions", createHashMap], // Tracks how many units each garrison has contributed
    ["_virtualGroups", createHashMap], // NEW: Tracks virtual groups under commander control

    // Methods
    ["_updateOperationMode", {
        params ["_newMode"];
        private _oldMode = _self get "_operationMode";
        
        if (_oldMode != _newMode) then {
            _self set ["_operationMode", _newMode];
            ["AI Commander", 3, format["Operation mode changed from %1 to %2", _oldMode, _newMode]] call FLO_fnc_log;
            
            // Adjust task force behavior based on new mode
            switch (_newMode) do {
                case "ATTACK": {
                    _self set ["_taskForceStrengthFactor", 1.5]; // More offensive units
                };
                case "DEFEND": {
                    _self set ["_taskForceStrengthFactor", 0.8]; // Focus on defense
                };
                case "SKIRMISH": {
                    _self set ["_taskForceStrengthFactor", 1.2]; // Balanced approach
                };
            };
        }
    }],
    
    ["_assessThreat", {
        // Get all OPFOR outposts - updated with correct marker criteria
        private _outposts = (allMapMarkers select {
            markerColor _x in ["colorOPFOR", "ColorEAST"] && 
            markerType _x in ["o_support", "n_support", "o_installation", "n_installation", "loc_Power", "loc_Ruin", "o_recon", "o_antiair", "o_service"]
        });
        
        // Count blufor forces near OPFOR outposts to assess threat
        private _totalThreat = 0;
        private _totalOutposts = count _outposts;
        
        {
            private _outpost = _x;
            private _position = getMarkerPos _outpost;
            private _nearBlufor = _position nearEntities [["Man", "LandVehicle"], 500];
            _nearBlufor = _nearBlufor select {side _x == west && !(captive _x)};
            
            private _outpostThreat = count _nearBlufor / 20; // Normalize
            _outpostThreat = _outpostThreat min 1; // Cap at 1
            
            // Save status to outpost map
            (_self get "_outpostStatus") set [_outpost, [_outpostThreat, _nearBlufor]];
            
            _totalThreat = _totalThreat + _outpostThreat;
        } forEach _outposts;
        
        // Calculate average threat
        if (_totalOutposts > 0) then {
            _totalThreat = _totalThreat / _totalOutposts;
        };
        
        // Update threat level
        _self set ["_threatLevel", _totalThreat];
        
        // Auto-adjust operation mode based on threat
        if (_totalThreat > (_self get "_threatThreshold") && (_self get "_operationMode") == "ATTACK") then {
            _self call ["_updateOperationMode", ["DEFEND"]];
        };
        
        if (_totalThreat < 0.3 && (_self get "_operationMode") == "DEFEND") then {
            _self call ["_updateOperationMode", ["SKIRMISH"]];
        };
        
        ["AI Commander", 3, format["Current threat assessment: %1", _totalThreat]] call FLO_fnc_log;
        
        _totalThreat
    }],
    
    ["_deployTaskForces", {  
        // Get the current operation mode
        private _mode = _self get "_operationMode";
        private _taskForceStrengthFactor = _self get "_taskForceStrengthFactor";
        
        // Get outposts that can deploy task forces
        private _outposts = keys (_self get "_outpostStatus");
        private _availableOutposts = _outposts select {
            private _data = ((_self get "_outpostStatus") get _x) select 0;
            _data < 0.4 // Only deploy from outposts not under heavy threat
        };
        
        if (count _availableOutposts == 0) exitWith {
            ["AI Commander", 3, "No outposts available to deploy task forces"] call FLO_fnc_log;
        };
        
        // Initialize the garrison integration system if not done already
        if (isNil "FLO_AICommander_UnitCapabilityAnalyzer") then {
            FLO_AICommander_UnitCapabilityAnalyzer = call FLO_fnc_AICommanderUnitCapabilityAnalyzer;
        };
        
        // Logic varies by operation mode
        switch (_mode) do {
            case "ATTACK": {
                // Find blufor objectives to attack - updated with correct marker criteria
                private _bluforObjectives = allMapMarkers select {
                    markerColor _x in ["colorBLUFOR", "ColorWEST", "ColorYellow"] &&
                    markerType _x in ["b_installation", "b_support", "respawn_west", "b_hq"]
                };
                
                if (count _bluforObjectives > 0) then {
                    private _targetObj = selectRandom _bluforObjectives;
                    
                    // Calculate desired task force size first, to use it for outpost selection
                    private _taskForceSize = 8 min (_taskForceStrengthFactor * 15); // Base size estimate
                    _taskForceSize = _taskForceSize max 8 min 40; // Ensure reasonable size limits
                    
                    // Select an outpost that can best provide the required units
                    private _sourceOutpost = _self call ["_selectBestOutpostForTaskForce", [_availableOutposts, _taskForceSize]];
                    
                    // Get updated garrison strength now that we have a suitable outpost
                    private _garrisonStrength = FLO_Garrison_Manager call ["_checkGarrisonStrength", [_sourceOutpost]];
                    // Adjust task force size based on actual garrison strength
                    _taskForceSize = round((_garrisonStrength * 0.4) * _taskForceStrengthFactor);
                    _taskForceSize = _taskForceSize max 8 min 40; // Ensure reasonable size limits
                    
                    // Generate a unique task force ID
                    private _sanitizedOutpost = _sourceOutpost;
                    // Check if the outpost ID contains coordinates (has square brackets)
                    if (_sourceOutpost find "[" > 0) then {
                        // Extract just the base name without coordinates
                        _sanitizedOutpost = "OutpMark" + (str floor random 100000);
                    };
                    private _taskForceID = format ["TF_ATTACK_%1_%2", _sanitizedOutpost, floor(random 1000)];
                    
                    // Define unit composition for offensive operations
                    private _unitTypes = East_Units + East_Units_Officers;
                    
                    // Pull units from the garrison - now returns a count instead of array
                    private _unitsCount = _self call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
                    
                    if (_unitsCount > 0) then {
                        // Create the task force in the system first
                        private _createResult = ["createTaskForce", [_sourceOutpost, "infantry", str(_taskForceSize), "", _taskForceID]] call FLO_fnc_TaskForceSystem;
                        if (_createResult != "") then {
                            // Use the returned task force ID for deployment
                            private _systemTaskForceID = _createResult;
                            // Deploy offensive task force with the pulled units
                            private _taskForceGroup = ["deployTaskForce", [_systemTaskForceID, getMarkerPos _sourceOutpost]] call FLO_fnc_TaskForceSystem;
                            
                            // Check if deployment was successful
                            if (!isNull _taskForceGroup) then {
                                ["AI Commander", 3, format["Deploying offensive task force from %1 to %2 with %3 units", _sourceOutpost, _targetObj, _unitsCount]] call FLO_fnc_log;
                                
                                // Assign attack actions to the task force
                                _self call ["_assignTaskForceActions", [_taskForceGroup, getMarkerPos _targetObj, "ATTACK"]];
                            } else {
                                // Deployment failed
                                ["AI Commander", 3, format["Offensive task force deployment failed - target %1 might be too close to players", _targetObj]] call FLO_fnc_log;
                                
                                // Check for any created vehicle groups that need to be cleaned up
                                private _vehicleGroups = [];
                                private _taskForceDataExists = false;
                                
                                // Get task force data to check for any created units or vehicles
                                private _taskForceData = ["getTaskForce", [_systemTaskForceID]] call FLO_fnc_TaskForceSystem;
                                if (count _taskForceData > 0) then {
                                    _taskForceDataExists = true;
                                    
                                    // Get deployed units to ensure all are cleaned up
                                    private _deployedUnits = _taskForceData select 7;
                                    
                                    // Delete any vehicles and their crews that were created
                                    {
                                        if (!isNull _x && {!(_x isKindOf "Man")}) then {
                                            // It's a vehicle, delete crew first
                                            {
                                                deleteVehicle _x;
                                            } forEach (crew _x);
                                            
                                            // Delete the vehicle itself
                                            deleteVehicle _x;
                                            ["AI Commander", 4, "Deleted vehicle from failed task force"] call FLO_fnc_log;
                                        };
                                    } forEach _deployedUnits;
                                    
                                    // Get and delete vehicle groups
                                    if (count _taskForceData > 16) then {
                                        _vehicleGroups = _taskForceData select 16;
                                        
                                        // Clean up all vehicle groups
                                        {
                                            private _vehGroup = _x;
                                            if (!isNull _vehGroup) then {
                                                {
                                                    deleteVehicle _x;
                                                } forEach units _vehGroup;
                                                deleteGroup _vehGroup;
                                                ["AI Commander", 4, format["Deleted vehicle group %1 from failed task force", _vehGroup]] call FLO_fnc_log;
                                            };
                                        } forEach _vehicleGroups;
                                        
                                        ["AI Commander", 4, format["Cleaned up %1 vehicle groups from failed task force", count _vehicleGroups]] call FLO_fnc_log;
                                    };
                                };
                                
                                // Return units to the garrison
                                _self call ["_returnUnitsToGarrison", [_taskForceID, _sourceOutpost, _unitsCount]];
                                
                                // Clean up the undeployed task force
                                ["removeTaskForce", [_systemTaskForceID]] call FLO_fnc_TaskForceSystem;
                            }
                        } else {
                            ["AI Commander", 3, format["Failed to create task force in system for offensive task force from %1", _sourceOutpost]] call FLO_fnc_log;
                            
                            // Return units to the garrison
                            _self call ["_returnUnitsToGarrison", [_taskForceID, _sourceOutpost, _unitsCount]];
                        };
                    } else {
                        ["AI Commander", 3, format["Failed to pull units from garrison at %1 for offensive task force", _sourceOutpost]] call FLO_fnc_log;
                    };
                };
                
                // Also check for BLUFOR troops in the field
                _self call ["_attackBluforInField", [_taskForceStrengthFactor * 1.2]];
            };
            
            case "DEFEND": {
                // Reinforce threatened outposts
                private _threatenedOutposts = _outposts select {
                    private _data = ((_self get "_outpostStatus") get _x) select 0;
                    _data >= 0.4 && _data < 0.7 // Moderate threat
                };
                
                if (count _threatenedOutposts > 0 && count _availableOutposts > 0) then {
                    private _targetOutpost = selectRandom _threatenedOutposts;
                    
                    // Calculate desired task force size first, to use it for outpost selection
                    private _taskForceSize = 6 min (_taskForceStrengthFactor * 10); // Base size estimate
                    _taskForceSize = _taskForceSize max 6 min 30; // Ensure reasonable size limits
                    
                    // Select an outpost that can best provide the required units (excluding the target outpost)
                    private _availableSourceOutposts = _availableOutposts - [_targetOutpost];
                    private _sourceOutpost = _self call ["_selectBestOutpostForTaskForce", [_availableSourceOutposts, _taskForceSize]];
                    
                    if (!isNil "_sourceOutpost") then {
                        // Calculate task force size based on outpost garrison strength and type
                        private _garrisonStrength = FLO_Garrison_Manager call ["_checkGarrisonStrength", [_sourceOutpost]];
                        private _taskForceSize = round((_garrisonStrength * 0.3) * _taskForceStrengthFactor);
                        _taskForceSize = _taskForceSize max 6 min 30; // Ensure reasonable size limits
                        
                        // Generate a unique task force ID
                        private _sanitizedOutpost = _sourceOutpost;
                        // Check if the outpost ID contains coordinates (has square brackets)
                        if (_sourceOutpost find "[" > 0) then {
                            // Extract just the base name without coordinates
                            _sanitizedOutpost = "OutpMark" + (str floor random 100000);
                        };
                        private _taskForceID = format ["TF_DEFEND_%1_%2", _sanitizedOutpost, floor(random 1000)];
                        
                        // Define unit composition for defensive operations - use array with AT specialists
                        // For defensive operations, prioritize units good for defense
                        private _defensiveUnits = East_Units select {
                            _x find "_AT_F" > 0 ||   // AT specialists
                            _x find "_AR_F" > 0 ||   // Autoriflemen
                            _x find "_MG_F" > 0 ||   // Machine gunners
                            _x find "_medic_F" > 0   // Medics
                        };
                        
                        private _unitTypes = if (count _defensiveUnits > 0) then {
                            East_Units + _defensiveUnits  // Add defensive specialists with extra weight
                        } else {
                            East_Units
                        };
                        
                        // Pull units from the garrison - now returns a count instead of array
                        private _unitsCount = _self call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
                        
                        if (_unitsCount > 0) then {
                            // Create the task force in the system first
                            private _createResult = ["createTaskForce", [_sourceOutpost, "infantry", str(_taskForceSize), "", _taskForceID]] call FLO_fnc_TaskForceSystem;
                            if (_createResult != "") then {
                                // Use the returned task force ID for deployment
                                private _systemTaskForceID = _createResult;
                                // Deploy defensive task force with the pulled units
                                private _taskForceGroup = ["deployTaskForce", [_systemTaskForceID, getMarkerPos _sourceOutpost]] call FLO_fnc_TaskForceSystem;
                                
                                // Check if deployment was successful
                                if (!isNull _taskForceGroup) then {
                                    ["AI Commander", 3, format["Reinforcing %1 with defensive task force from %2 with %3 units", _sourceOutpost, _sourceOutpost, _unitsCount]] call FLO_fnc_log;
                                    
                                    // Assign defend actions to the task force
                                    _self call ["_assignTaskForceActions", [_taskForceGroup, getMarkerPos _sourceOutpost, "DEFEND"]];
                                } else {
                                    // Deployment failed
                                    ["AI Commander", 3, format["Defensive task force deployment failed - target %1 might be too close to players", _sourceOutpost]] call FLO_fnc_log;
                                    
                                    // Return units to the garrison
                                    _self call ["_returnUnitsToGarrison", [_taskForceID, _sourceOutpost, _unitsCount]];
                                    
                                    // Clean up the undeployed task force
                                    ["removeTaskForce", [_systemTaskForceID]] call FLO_fnc_TaskForceSystem;
                                }
                            } else {
                                ["AI Commander", 3, format["Failed to create task force in system for defensive task force from %1", _sourceOutpost]] call FLO_fnc_log;
                                
                                // Return units to the garrison
                                _self call ["_returnUnitsToGarrison", [_taskForceID, _sourceOutpost, _unitsCount]];
                            };
                        } else {
                            ["AI Commander", 3, format["Failed to pull units from garrison at %1 for defensive task force", _sourceOutpost]] call FLO_fnc_log;
                        };
                    };
                };
            };
            
            case "SKIRMISH": {
                // Mix of patrols and counter-attacks
                if (random 1 > 0.5) then {
                    // Find patrol points - roads between outposts
                    // Calculate desired task force size first, to use it for outpost selection
                    private _taskForceSize = 4 min (_taskForceStrengthFactor * 6); // Base size estimate
                    _taskForceSize = _taskForceSize max 4 min 16; // Smaller patrol groups
                    
                    // Select an outpost that can best provide the required units
                    private _sourceOutpost = _self call ["_selectBestOutpostForTaskForce", [_availableOutposts, _taskForceSize]];
                    private _roads = (getMarkerPos _sourceOutpost) nearRoads 1000;
                    
                    if (count _roads > 0) then {
                        private _targetRoad = selectRandom _roads;
                        
                        // Get updated garrison strength now that we have a suitable outpost
                        private _garrisonStrength = FLO_Garrison_Manager call ["_checkGarrisonStrength", [_sourceOutpost]];
                        // Adjust task force size based on actual garrison strength
                        _taskForceSize = round((_garrisonStrength * 0.2) * _taskForceStrengthFactor * 0.7);
                        _taskForceSize = _taskForceSize max 4 min 16; // Smaller patrol groups
                        
                        // Generate a unique task force ID
                        private _sanitizedOutpost = _sourceOutpost;
                        // Check if the outpost ID contains coordinates (has square brackets)
                        if (_sourceOutpost find "[" > 0) then {
                            // Extract just the base name without coordinates
                            _sanitizedOutpost = "OutpMark" + (str floor random 100000);
                        };
                        private _taskForceID = format ["TF_PATROL_%1_%2", _sanitizedOutpost, floor(random 1000)];
                        
                        // Define unit composition for patrol operations
                        private _unitTypes = East_Units;
                        
                        // Pull units from the garrison - now returns a count instead of array
                        private _unitsCount = _self call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
                        
                        if (_unitsCount > 0) then {
                            // Create the task force in the system first
                            private _createResult = ["createTaskForce", [_sourceOutpost, "infantry", str(_taskForceSize), "", _taskForceID]] call FLO_fnc_TaskForceSystem;
                            if (_createResult != "") then {
                                // Use the returned task force ID for deployment
                                private _systemTaskForceID = _createResult;
                                // Deploy patrol task force with the pulled units
                                private _taskForceGroup = ["deployTaskForce", [_systemTaskForceID, getPos _targetRoad]] call FLO_fnc_TaskForceSystem;
                                
                                // Check if deployment was successful
                                if (!isNull _taskForceGroup) then {
                                    ["AI Commander", 3, format["Deploying patrol from %1 with %2 units", _sourceOutpost, _unitsCount]] call FLO_fnc_log;
                                    
                                    // Assign patrol actions to the task force
                                    _self call ["_assignTaskForceActions", [_taskForceGroup, getPos _targetRoad, "PATROL"]];
                                } else {
                                    // Deployment failed
                                    ["AI Commander", 3, format["Patrol task force deployment failed - location might be too close to players"]] call FLO_fnc_log;
                                    
                                    // Return units to the garrison
                                    _self call ["_returnUnitsToGarrison", [_taskForceID, _sourceOutpost, _unitsCount]];
                                    
                                    // Clean up the undeployed task force
                                    ["removeTaskForce", [_systemTaskForceID]] call FLO_fnc_TaskForceSystem;
                                }
                            } else {
                                ["AI Commander", 3, format["Failed to create task force in system for patrol task force from %1", _sourceOutpost]] call FLO_fnc_log;
                                
                                // Return units to the garrison
                                _self call ["_returnUnitsToGarrison", [_taskForceID, _sourceOutpost, _unitsCount]];
                            };
                        } else {
                            ["AI Commander", 3, format["Failed to pull units from garrison at %1 for patrol task force", _sourceOutpost]] call FLO_fnc_log;
                        };
                    };
                } else {
                    // Small raids against blufor positions - updated with correct marker criteria
                    private _bluforPositions = allMapMarkers select {
                        markerColor _x in ["colorBLUFOR", "ColorWEST", "ColorYellow"] &&
                        markerType _x in ["b_installation", "b_support", "respawn_west", "b_hq"]
                    };
                    
                    if (count _bluforPositions > 0 && count _availableOutposts > 0) then {
                        private _targetPos = selectRandom _bluforPositions;
                        
                        // Calculate desired task force size first, to use it for outpost selection
                        private _taskForceSize = 5 min (_taskForceStrengthFactor * 10); // Base size estimate
                        _taskForceSize = _taskForceSize max 5 min 20; // Balanced skirmish size
                        
                        // Select an outpost that can best provide the required units
                        private _sourceOutpost = _self call ["_selectBestOutpostForTaskForce", [_availableOutposts, _taskForceSize]];
                        
                        // Get updated garrison strength now that we have a suitable outpost
                        private _garrisonStrength = FLO_Garrison_Manager call ["_checkGarrisonStrength", [_sourceOutpost]];
                        // Adjust task force size based on actual garrison strength
                        _taskForceSize = round((_garrisonStrength * 0.25) * _taskForceStrengthFactor * 0.8);
                        _taskForceSize = _taskForceSize max 5 min 20; // Balanced skirmish size
                        
                        // Generate a unique task force ID
                        private _sanitizedOutpost = _sourceOutpost;
                        // Check if the outpost ID contains coordinates (has square brackets)
                        if (_sourceOutpost find "[" > 0) then {
                            // Extract just the base name without coordinates
                            _sanitizedOutpost = "OutpMark" + (str floor random 100000);
                        };
                        private _taskForceID = format ["TF_SKIRMISH_%1_%2", _sanitizedOutpost, floor(random 1000)];
                        
                        // Define unit composition for skirmish operations
                        private _unitTypes = East_Units + East_Units_Officers;
                        
                        // Pull units from the garrison - now returns a count instead of array
                        private _unitsCount = _self call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
                        
                        if (_unitsCount > 0) then {
                            // Create the task force in the system first
                            private _createResult = ["createTaskForce", [_sourceOutpost, "infantry", str(_taskForceSize), "", _taskForceID]] call FLO_fnc_TaskForceSystem;
                            if (_createResult != "") then {
                                // Use the returned task force ID for deployment
                                private _systemTaskForceID = _createResult;
                                // Deploy skirmish task force with the pulled units
                                private _taskForceGroup = ["deployTaskForce", [_systemTaskForceID, getMarkerPos _sourceOutpost]] call FLO_fnc_TaskForceSystem;
                                
                                // Check if deployment was successful
                                if (!isNull _taskForceGroup) then {
                                    ["AI Commander", 3, format["Deploying skirmish force from %1 to %2 with %3 units", _sourceOutpost, _targetPos, _unitsCount]] call FLO_fnc_log;
                                    
                                    // Assign skirmish actions to the task force
                                    _self call ["_assignTaskForceActions", [_taskForceGroup, getMarkerPos _targetPos, "ATTACK"]];
                                } else {
                                    // Deployment failed
                                    ["AI Commander", 3, format["Skirmish task force deployment failed - target %1 might be too close to players", _sourceOutpost]] call FLO_fnc_log;
                                    
                                    // Return units to the garrison
                                    _self call ["_returnUnitsToGarrison", [_taskForceID, _sourceOutpost, _unitsCount]];
                                    
                                    // Clean up the undeployed task force
                                    ["removeTaskForce", [_systemTaskForceID]] call FLO_fnc_TaskForceSystem;
                                }
                            } else {
                                ["AI Commander", 3, format["Failed to create task force in system for skirmish task force from %1", _sourceOutpost]] call FLO_fnc_log;
                                
                                // Return units to the garrison
                                _self call ["_returnUnitsToGarrison", [_taskForceID, _sourceOutpost, _unitsCount]];
                            };
                        } else {
                            ["AI Commander", 3, format["Failed to pull units from garrison at %1 for skirmish task force", _sourceOutpost]] call FLO_fnc_log;
                        };
                    };
                    
                    // Also occasionally attack BLUFOR in the field during skirmish mode
                    if (random 1 > 0.7) then {
                        _self call ["_attackBluforInField", [_taskForceStrengthFactor * 0.9]];
                    };
                };
            };
        };
    }],
    
    ["_attackBluforInField", {
        params ["_taskForceStrengthFactor"];
        
        // Get outposts that can deploy task forces
        private _outposts = keys (_self get "_outpostStatus");
        private _availableOutposts = _outposts select {
            private _data = ((_self get "_outpostStatus") get _x) select 0;
            _data < 0.4 // Only deploy from outposts not under heavy threat
        };
        
        if (count _availableOutposts == 0) exitWith {
            ["AI Commander", 3, "No outposts available to deploy attack forces"] call FLO_fnc_log;
            false
        };
        
        // Find BLUFOR units in the field
        private _allDetectedUnits = [];
        private _detectionRange = 3000; // How far OPFOR can detect BLUFOR units
        
        // Check each outpost for detected BLUFOR units
        {
            private _outpost = _x;
            private _position = getMarkerPos _outpost;
            
            // Get all BLUFOR units within detection range
            private _nearBlufor = _position nearEntities [["Man", "LandVehicle", "Air"], _detectionRange];
            _nearBlufor = _nearBlufor select {side _x == west && !(captive _x)};
            
            // Add each unit with its position and the detecting outpost
            {
                _allDetectedUnits pushBack [_x, getPos _x, _outpost, group _x];
            } forEach _nearBlufor;
        } forEach _outposts;
        
        // If no units detected, exit
        if (count _allDetectedUnits == 0) exitWith {
            ["AI Commander", 3, "No BLUFOR units detected in the field to attack"] call FLO_fnc_log;
            false
        };
        
        // Group detected units by their groups to avoid sending multiple task forces to the same group
        private _groupedDetections = createHashMap;
        
        {
            _x params ["_unit", "_position", "_detectingOutpost", "_group"];
            
            // Use the group as the key
            private _groupID = str _group;
            private _existingEntry = _groupedDetections getOrDefault [_groupID, []];
            
            if (count _existingEntry == 0) then {
                // New group, initialize with units and position
                _groupedDetections set [_groupID, [1, _position, _detectingOutpost]];
            } else {
                // Existing group, update count
                _existingEntry set [0, (_existingEntry select 0) + 1];
                _groupedDetections set [_groupID, _existingEntry];
            };
        } forEach _allDetectedUnits;
        
        // Now filter for groups that have a significant number of units (worth attacking)
        private _significantGroups = [];
        
        {
            private _groupData = _y;
            _groupData params ["_unitCount", "_position", "_detectingOutpost"];
            
            // Only target groups with at least 3 units
            if (_unitCount >= 3) then {
                _significantGroups pushBack [_x, _unitCount, _position, _detectingOutpost];
            };
        } forEach _groupedDetections;
        
        // If no significant groups, exit
        if (count _significantGroups == 0) exitWith {
            ["AI Commander", 3, "No significant BLUFOR groups in the field to attack"] call FLO_fnc_log;
            false
        };
        
        // Sort groups by size (largest first)
        _significantGroups sort false;
        
        // Choose one significant group to attack (prioritize larger groups)
        private _targetGroup = selectRandom (_significantGroups select [0, (count _significantGroups) min 3]);
        _targetGroup params ["_groupID", "_unitCount", "_position", "_detectingOutpost"];
        
        // Determine attack strength based on group size
        private _attackStrength = switch (true) do {
            case (_unitCount > 10): {_taskForceStrengthFactor * 1.5}; // Large group
            case (_unitCount > 5): {_taskForceStrengthFactor * 1.2}; // Medium group
            default {_taskForceStrengthFactor * 0.8}; // Small group
        };
        
        // Calculate task force size based on BLUFOR group size and our strength factor
        private _taskForceSize = round(_unitCount * 1.5 * _attackStrength);
        _taskForceSize = _taskForceSize max 6 min 30; // Ensure reasonable size limits
        
        ["AI Commander", 3, format["Planning to attack BLUFOR group of size %1 with a task force of size %2", _unitCount, _taskForceSize]] call FLO_fnc_log;
        
        // Start detailed debug logging
        // diag_log "=================================================================";
        // diag_log format ["[FLO][AI Commander][DEBUG] Starting task force creation process"];
        // diag_log format ["[FLO][AI Commander][DEBUG] Target BLUFOR group size: %1, position: %2", _unitCount, _position];
        // diag_log format ["[FLO][AI Commander][DEBUG] Calculated task force size: %1", _taskForceSize];
        
        // Select a suitable outpost that can provide the required units
        private _sourceOutpost = "";
        
        // First try to use nearby outposts
        private _nearOutposts = _availableOutposts select {
            (getMarkerPos _x) distance _position < 5000
        };
        
        // diag_log format ["[FLO][AI Commander][DEBUG] Found %1 nearby outposts within 5000m", count _nearOutposts];
        // if (count _nearOutposts > 0) then {
        //     diag_log format ["[FLO][AI Commander][DEBUG] Nearby outposts: %1", _nearOutposts];
        // };
        
        if (count _nearOutposts > 0) then {
            // Select the best nearby outpost based on strength
            _sourceOutpost = _self call ["_selectBestOutpostForTaskForce", [_nearOutposts, _taskForceSize]];
        } else {
            // If no nearby outposts, use any available outpost with sufficient strength
            _sourceOutpost = _self call ["_selectBestOutpostForTaskForce", [_availableOutposts, _taskForceSize]];
        };
        
        // diag_log format ["[FLO][AI Commander][DEBUG] Selected source outpost: %1", _sourceOutpost];
        
        // Generate a unique task force ID
        private _sanitizedOutpost = _sourceOutpost;
        // Check if the outpost ID contains coordinates (has square brackets)
        if (_sourceOutpost find "[" > 0) then {
            // Extract just the base name without coordinates
            _sanitizedOutpost = "OutpMark" + (str floor random 100000);
        };
        
        // Create a truly unique ID with timestamp to prevent duplicates
        private _taskForceID = format ["TF_FIELDATTACK_%1_%2_%3", _sanitizedOutpost, floor(random 1000), round(diag_tickTime)];
        // diag_log format ["[FLO][AI Commander][DEBUG] Generated task force ID: %1", _taskForceID];
        
        // Define unit composition for field attack operations - combat-focused with specialists
        // For field attacks, we want combat specialists and heavy firepower
        private _combatSpecialists = East_Units select {
            _x find "_AT_F" > 0 ||   // AT specialists
            _x find "_AR_F" > 0 ||   // Autoriflemen
            _x find "_GL_F" > 0 ||   // Grenadiers
            _x find "_M_F" > 0       // Marksmen
        };
        
        private _unitTypes = if (count _combatSpecialists > 0) then {
            East_Units + _combatSpecialists  // Add combat specialists with extra weight
        } else {
            East_Units
        };
        
        ["AI Commander", 3, format["Attempting to pull %1 units from garrison at %2 for task force %3", _taskForceSize, _sourceOutpost, _taskForceID]] call FLO_fnc_log;
        
        // Pull units from the garrison - now returns a count instead of array
        private _unitsCount = _self call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
        
        // diag_log format ["[FLO][AI Commander][DEBUG] Pulled %1 units from garrison %2 (requested %3)", 
        //    _unitsCount, _sourceOutpost, _taskForceSize];
        
        ["AI Commander", 3, format["Actually pulled %1 units from garrison for task force %2", _unitsCount, _taskForceID]] call FLO_fnc_log;
        
        if (_unitsCount > 0) then {
            // No longer have actual unit objects to log types - just log the count
            ["AI Commander", 3, format["Pulled %1 units for task force %2", _unitsCount, _taskForceID]] call FLO_fnc_log;
            
            // Since we don't have actual unit objects anymore, we'll create a simple infantry composition
            private _unitComposition = [];
            
            // Add a basic infantry element with the total count
            _unitComposition pushBack ["infantry", East_Units, _unitsCount];
            
            // Determine if we should add vehicles based on task force size and type
            private _shouldAddVehicle = false;
            private _vehicleTypes = [];
            private _vehicleCount = 0;
            
            // For field attacks, add vehicles based on size and random chance
            if (_unitsCount >= 8) then {
                // Larger forces get vehicles more often
                private _vehicleChance = 0.5;
                private _roll = random 1;
                
                if (_roll < _vehicleChance) then {
                    _shouldAddVehicle = true;
                    
                    // Determine vehicle type based on task force size and composition
                    if (_unitsCount >= 12) then {
                        // Larger forces can get heavier vehicles
                        _vehicleTypes = East_Ground_Vehicles_Heavy;
                        _vehicleCount = 1;
                    } else {
                        // Medium forces get light vehicles
                        _vehicleTypes = East_Ground_Vehicles_Light;
                        _vehicleCount = 1;
                    };
                };
            } else {
                if (_unitsCount >= 5) then {
                    // Medium forces have a smaller chance for light vehicles
                    private _vehicleChance = 0.2;
                    private _roll = random 1;
                    
                    if (_roll < _vehicleChance) then {
                        _shouldAddVehicle = true;
                        _vehicleTypes = East_Ground_Vehicles_Light;
                        _vehicleCount = 1;
                    };
                };
            };
            
            // Add vehicle to composition if needed
            if (_shouldAddVehicle && count _vehicleTypes > 0) then {
                _unitComposition pushBack ["vehicle", _vehicleTypes, _vehicleCount];
                ["AI Commander", 3, format["Added %1 vehicle(s) to task force %2 composition", _vehicleCount, _taskForceID]] call FLO_fnc_log;
            } else {
                ["AI Commander", 4, "No vehicles added to this task force"] call FLO_fnc_log;
            };
            
            // Debug - dump full composition
            // diag_log format ["[FLO][AI Commander][DEBUG] Final composition for %1: %2", _taskForceID, _unitComposition];
            // {
            //     _x params ["_elementType", "_elementClasses", "_elementCount"];
            //     diag_log format ["[FLO][AI Commander][DEBUG] - Element: Type: %1, Classes: %2, Count: %3", 
            //         _elementType, _elementClasses, _elementCount];
            // } forEach _unitComposition;
            
            // Create the task force with the exact composition of pulled units
            private _createParams = [
                _sourceOutpost,
                "infantry", // Base type is infantry
                str(_unitsCount),
                "",
                _taskForceID,
                _unitComposition // Pass the actual composition as an additional parameter
            ];
            
            // Create the task force in the system first
            ["AI Commander", 3, format["Creating task force with parameters: %1", _createParams]] call FLO_fnc_log;
            private _createResult = ["createTaskForce", _createParams] call FLO_fnc_TaskForceSystem;
            
            if (_createResult != "") then {
                // Use the returned task force ID for deployment
                private _systemTaskForceID = _createResult;
                
                ["AI Commander", 3, format["Task Force %1 created successfully, deploying to position %2", _systemTaskForceID, getMarkerPos _sourceOutpost]] call FLO_fnc_log;
                
                // Deploy attack force with pulled units
                private _taskForceGroup = ["deployTaskForce", [_systemTaskForceID, getMarkerPos _sourceOutpost]] call FLO_fnc_TaskForceSystem;
                
                // Check if deployment was successful
                if (!isNull _taskForceGroup) then {
                    // Successfully deployed - assign actions
                    _self call ["_assignTaskForceActions", [_taskForceGroup, _position, "ATTACK"]];
                
                    private _infantryCount = count (units _taskForceGroup select {_x isKindOf "Man"});
                    private _allUnits = units _taskForceGroup;
                    private _vehicleCount = count (_allUnits select {!(_x isKindOf "Man")});
                    
                    // Create a detailed breakdown of unit types
                    private _unitTypeBreakdown = createHashMap;
                    {
                        if (_x isKindOf "Man") then {
                            private _type = typeOf _x;
                            private _count = _unitTypeBreakdown getOrDefault [_type, 0];
                            _unitTypeBreakdown set [_type, _count + 1];
                        };
                    } forEach _allUnits;
                    
                    // Format the breakdown for logging
                    private _breakdownText = "";
                    {
                        _breakdownText = _breakdownText + format["%1: %2, ", _x, _unitTypeBreakdown get _x];
                    } forEach keys _unitTypeBreakdown;
                    
                    // Log the full deployment details
                    ["AI Commander", 3, format["Task Force %1 breakdown - Infantry: %2, Vehicles: %3, Details: %4", 
                        _systemTaskForceID, _infantryCount, _vehicleCount, _breakdownText]] call FLO_fnc_log;
                    
                    ["AI Commander", 3, format["Deploying force from %1 to attack %2 BLUFOR units in the field with %3 of our units", 
                        _sourceOutpost, _unitCount, _unitsCount]] call FLO_fnc_log;
                    
                    true
                } else {
                    // Deployment failed - handle the failed deployment
                    ["AI Commander", 3, format["Task force deployment failed - position %1 might be too close to players or in an invalid location", _position]] call FLO_fnc_log;
                    
                    // Return units to the garrison since we couldn't deploy them
                    _self call ["_returnUnitsToGarrison", [_taskForceID, _sourceOutpost, _unitsCount]];
                    
                    // Attempt to clean up the undeployed task force
                    ["removeTaskForce", [_systemTaskForceID]] call FLO_fnc_TaskForceSystem;
                    
                    false
                }
            } else {
                ["AI Commander", 3, format["Failed to create task force in system for field attack from %1", _sourceOutpost]] call FLO_fnc_log;
                
                // Return units to the garrison
                _self call ["_returnUnitsToGarrison", [_taskForceID, _sourceOutpost, _unitsCount]];
                
                false
            };
        } else {
            ["AI Commander", 3, format["Failed to pull units from garrison at %1 for field attack task force", _sourceOutpost]] call FLO_fnc_log;
            false
        };
    }],
    
    ["_deploySpecialOperations", {   
        // Only deploy special ops at night
        private _hour = date select 3;
        if (_hour < 20 && _hour > 4) exitWith {
            ["AI Commander", 3, "Special operations only deploy at night (20:00-04:00)"] call FLO_fnc_log;
            false
        };
        
        // Find suitable targets - undefended or lightly defended blufor positions - updated with correct marker criteria
        private _bluforPositions = allMapMarkers select {
            markerColor _x in ["colorBLUFOR", "ColorWEST", "ColorYellow"] &&
            markerType _x in ["b_installation", "b_support", "respawn_west", "b_hq"]
        };
        
        if (count _bluforPositions == 0) exitWith {
            ["AI Commander", 3, "No suitable targets for special operations"] call FLO_fnc_log;
            false
        };
        
        // Select a random target
        private _targetPos = selectRandom _bluforPositions;
        private _targetPosition = getMarkerPos _targetPos;
        
        // Check if target is lightly defended
        private _nearUnits = _targetPosition nearEntities [["Man", "LandVehicle"], 500];
        private _bluforUnits = _nearUnits select {side _x == west && !(captive _x)};
        
        if (count _bluforUnits > 10) exitWith {
            ["AI Commander", 3, format["Target %1 too heavily defended for special operations", _targetPos]] call FLO_fnc_log;
            false
        };
        
        // Find suitable insertion point
        private _insertionPoint = [_targetPosition, 1000, 1500, 10, 0, 0.2, 0] call BIS_fnc_findSafePos;
        
        // Create and deploy special forces team
        private _specialOpsGroup = createGroup [east, true];
        
        // Add special forces operators
        for "_i" from 1 to 8 do {
            // Select appropriate unit types for special operations
            // Prefer marksmen, special forces, and specialists
            private _specialOpsCandidates = East_Units select {
                _x find "_M_F" > 0 ||    // Marksmen
                _x find "_TL_F" > 0 ||   // Team leaders  
                _x find "_exp_F" > 0 ||  // Explosive specialists
                _x find "_medic_F" > 0 || // Medics
                _x find "_GL_F" > 0      // Grenadiers
            };
            
            // If no specialized units found, fall back to regular units
            private _unitType = if (count _specialOpsCandidates > 0) then {
                selectRandom _specialOpsCandidates
            } else {
                selectRandom East_Units
            };
            
            private _unit = _specialOpsGroup createUnit [_unitType, _insertionPoint, [], 0, "NONE"];
            _unit allowDamage false; // Temporarily prevent damage during spawn
            
            // Equip unit with night operations gear
            _unit addPrimaryWeaponItem "acc_pointer_IR";
            _unit addPrimaryWeaponItem "optic_Nightstalker";
            _unit addHeadgear "H_HelmetSpecO_blk";
            _unit addGoggles "G_Balaclava_blk";
            
            // Add NVGs
            _unit linkItem "NVGoggles_OPFOR";
            
            // Special loadout for demo expert
            if (_unitType find "_exp_F" > 0) then {
                for "_m" from 1 to 3 do {
                    _unit addMagazine "DemoCharge_Remote_Mag";
                }; 
            };
            
            // All units get silencers
            _unit addPrimaryWeaponItem "muzzle_snds_H";
            
            // Re-enable damage after setup
            [_unit, true] remoteExec ["allowDamage", 0, _unit];
        };
        
        // Set group behaviors
        _specialOpsGroup setBehaviour "STEALTH";
        _specialOpsGroup setCombatMode "GREEN";
        _specialOpsGroup setSpeedMode "LIMITED";
        
        // Assign tasks based on mission
        // Mine roads or recon the area
        if (random 1 > 0.5) then {
            private _roads = _targetPosition nearRoads 1000;
            if (count _roads > 0) then {
                private _minePoints = [];
                for "_i" from 1 to (3 + floor(random 3)) do {
                    _minePoints pushBack (selectRandom _roads);
                };
                
                {
                    private _wp = _specialOpsGroup addWaypoint [getPos _x, 20];
                    _wp setWaypointType "MOVE";
                    _wp setWaypointBehaviour "STEALTH";
                    
                    private _wpPlaceMine = _specialOpsGroup addWaypoint [getPos _x, 0];
                    _wpPlaceMine setWaypointType "SCRIPTED";
                    _wpPlaceMine setWaypointScript "A3\functions_f\waypoints\fn_wpMine.sqf";
                } forEach _minePoints;
            };
        } 
        // Assault position
        else {
            // Use our waypoint action system to handle the special ops mission
            [_specialOpsGroup, _targetPosition] call FLO_fnc_attackArea;
            
            // Add an escape waypoint at the end to clean up the group
            private _wp = _specialOpsGroup addWaypoint [_insertionPoint, 100];
            _wp setWaypointType "MOVE";
            _wp setWaypointStatements ["true", "
                {deleteVehicle _x} forEach (units group this); 
                deleteGroup group this;
            "];
        };
        
        _self set ["_hasSpecialOps", true];
        _self set ["_lastSpecialOps", diag_tickTime];
        
        ["AI Commander", 3, format["Deployed special operations team to %1", _targetPos]] call FLO_fnc_log;
        true
    }],
    
    ["_assignTaskForceActions", {
        params ["_taskForceGroup", "_targetPosition", "_operationType"];
        
        // Ensure we have a valid group
        if (!(_taskForceGroup isEqualType grpNull) || {isNull _taskForceGroup}) exitWith {
            ["AI Commander", 3, "Cannot assign actions to null or invalid group"] call FLO_fnc_log;
            false
        };
        
        // Determine enemy types at target position for vehicle selection
        private _enemyTypes = [];
        private _nearEntities = _targetPosition nearEntities ["Man", 500];
        private _bluforUnits = _nearEntities select {side _x == west && !(captive _x)};
        
        // Log number of enemies detected
        private _enemyCount = count _bluforUnits;
        ["AI Commander", 3, format["Detected %1 BLUFOR units near target position", _enemyCount]] call FLO_fnc_log;
        
        // Detect enemy types
        private _armor = false;
        private _air = false;
        private _vehicles = false;
        
        {
            if (vehicle _x != _x) then {
                private _veh = vehicle _x;
                _vehicles = true;
                
                if (_veh isKindOf "Tank" || _veh isKindOf "Wheeled_APC") then {
                    _armor = true;
                };
                
                if (_veh isKindOf "Air") then {
                    _air = true;
                };
            };
        } forEach _bluforUnits;
        
        // Add detected enemy types
        if (_enemyCount > 0) then {
            _enemyTypes pushBack "MAN";
        };
        
        if (_vehicles) then {
            _enemyTypes pushBack "CAR";
        };
        
        if (_armor) then {
            _enemyTypes pushBack "ARMOR";
        };
        
        if (_air) then {
            _enemyTypes pushBack "AIR";
        };
        
        // Get task force ID for vehicle assignment
        private _taskForceID = groupId _taskForceGroup;
        if (_taskForceID == "") then {
            _taskForceID = format ["TF_%1_%2", _operationType, floor(random 1000)];
            _taskForceGroup setGroupIdGlobal [_taskForceID];
        };
        
        // Find source outpost (extract from task force ID if possible)
        private _sourceOutpost = "";
        if (_taskForceID find "_" > 0) then {
            private _parts = _taskForceID splitString "_";
            if (count _parts > 2) then {
                _sourceOutpost = _parts select 2;
            };
        };
        
        // If we couldn't find the source outpost, use the first available one
        if (_sourceOutpost == "") then {
            private _outposts = keys (_self get "_outpostStatus");
            if (count _outposts > 0) then {
                _sourceOutpost = _outposts select 0;
            };
        };
        
        // Get vehicle support based on operation type and enemy presence
        private _vehicleGroups = [];
        if (_sourceOutpost != "") then {
            // Prepare vehicle types based on enemy types
            private _requiredVehicles = [];
            
            // Determine what vehicles to request based on enemy types
            if ("ARMOR" in _enemyTypes) then {
                // Against armor, we need anti-tank capability
                _requiredVehicles pushBack [selectRandom East_Ground_Vehicles_Heavy, 1];
            } else {
                if ("AIR" in _enemyTypes) then {
                    // Against air, we need AA capability if available
                    private _aaVehicles = East_Ground_Vehicles_Heavy select {
                        _x find "AA" > -1 || _x find "_AA_" > -1 || _x find "aa_" > -1
                    };
                    
                    if (count _aaVehicles > 0) then {
                        _requiredVehicles pushBack [selectRandom _aaVehicles, 1];
                    } else {
                        _requiredVehicles pushBack [selectRandom East_Ground_Vehicles_Light, 1];
                    };
                } else {
                    // Default light vehicle for infantry support
                    _requiredVehicles pushBack [selectRandom East_Ground_Vehicles_Light, 1];
                };
            };

            ["AI Commander", 3, format["Required vehicles: %1", _requiredVehicles]] call FLO_fnc_log;
            
            // Find the nearest marker to the target position to use as objective reference
            private _nearestObjectiveMarker = "";
            private _nearestDistance = 999999;
            
            // Find all OPFOR markers to use as potential objectives
            private _opforMarkers = allMapMarkers select {
                markerColor _x in ["colorOPFOR", "ColorEAST"] && 
                markerType _x in ["o_support", "n_support", "o_installation", "n_installation", 
                                  "loc_Power", "o_recon", "o_service", "o_antiair", "loc_Ruin"]
            };
            
            // Find the closest marker to the target position
            {
                private _markerPos = getMarkerPos _x;
                private _distance = _markerPos distance _targetPosition;
                
                if (_distance < _nearestDistance) then {
                    _nearestObjectiveMarker = _x;
                    _nearestDistance = _distance;
                };
            } forEach _opforMarkers;
            
            ["AI Commander", 3, format["Nearest objective marker: %1", _nearestObjectiveMarker]] call FLO_fnc_log;
            
            // Call the method with correct parameters - using marker name instead of position
            _vehicleGroups = _self call ["_getVehicleForTaskForce", [_taskForceID, _requiredVehicles, _nearestObjectiveMarker]];
        };
        
        // Assign the appropriate action based on the operation type for infantry
        switch (_operationType) do {
            case "ATTACK": {
                [_taskForceGroup, _targetPosition] call FLO_fnc_attackArea;
                ["AI Commander", 3, format["Assigned attack actions to infantry group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
            };
            
            case "DEFEND": {
                [_taskForceGroup, _targetPosition] call FLO_fnc_defendArea;
                ["AI Commander", 3, format["Assigned defend actions to infantry group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
            };
            
            case "PATROL": {
                [_taskForceGroup, _targetPosition] call FLO_fnc_patrolArea;
                ["AI Commander", 3, format["Assigned patrol actions to infantry group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
            };
            
            case "SKIRMISH": {
                // For skirmish, we alternate between attack and recon based on the situation
                if (random 1 > 0.5) then {
                    [_taskForceGroup, _targetPosition] call FLO_fnc_attackArea;
                    ["AI Commander", 3, format["Assigned attack actions (skirmish) to infantry group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
                } else {
                    [_taskForceGroup, _targetPosition] call FLO_fnc_reconArea;
                    ["AI Commander", 3, format["Assigned recon actions (skirmish) to infantry group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
                };
            };
            
            case "RECON": {
                [_taskForceGroup, _targetPosition] call FLO_fnc_reconArea;
                ["AI Commander", 3, format["Assigned recon actions to infantry group %1 at position %2", _taskForceGroup, _targetPosition]] call FLO_fnc_log;
            };
            
            default {
                ["AI Commander", 3, format["Unknown operation type %1 for group %2", _operationType, _taskForceGroup]] call FLO_fnc_log;
                false
            };
        };
        
        // If we have vehicle groups, assign appropriate vehicle actions
        if (count _vehicleGroups > 0) then {
            _self call ["_assignVehicleActions", [_vehicleGroups, _taskForceGroup, _targetPosition, _operationType]];
            ["AI Commander", 3, format["Assigned %1 vehicle groups to support task force %2", count _vehicleGroups, _taskForceID]] call FLO_fnc_log;
        };
        
        true
    }],
    
    ["_update", {
     
        private _currentTime = diag_tickTime;
        private _lastUpdate = _self get "_lastUpdate";
        private _updateInterval = _self get "_commanderUpdateInterval";
        
        // Only update periodically
        if (_currentTime - _lastUpdate < _updateInterval) exitWith {};
        
        // Assess current threat situation
        private _threat = _self call ["_assessThreat", []];
        
        // Deploy task forces as needed
        _self call ["_deployTaskForces", []];
        
        // Occasionally check for BLUFOR in the field even outside regular task force deployment
        // This ensures direct response to BLUFOR incursions
        if (_self get "_operationMode" != "DEFEND" && random 1 > 0.7) then {
            _self call ["_attackBluforInField", [_self get "_taskForceStrengthFactor"]];
        };
        
        // Check if it's time for special operations (and we don't have an active team)
        private _lastSpecialOps = _self get "_lastSpecialOps";
        private _specialOpsInterval = _self get "_specialOpsUpdateInterval";
        
        // TOOD: GET THIS WORKING
        // if (_currentTime - _lastSpecialOps > _specialOpsInterval && !(_self get "_hasSpecialOps")) then {
        //     _self call ["_deploySpecialOperations", []];
        // };
        
        // Update last update time
        _self set ["_lastUpdate", _currentTime];
    }],
    
    ["_processReconReport", {
        params ["_reportData", "_reportingGroup"];
        
        // Extract information from the report data
        _reportData params [
            "_position",
            "_enemyCount",
            "_infantry",
            "_vehicles",
            "_armor",
            "_air",
            "_enemyTypes"
        ];
        
        // Log the recon report at command level
        ["AI Commander", 2, format["RECON REPORT RECEIVED: %1 total enemies at %2 (%3 infantry, %4 vehicles, %5 armor, %6 air)", 
            _enemyCount, _position, _infantry, _vehicles, _armor, _air]] call FLO_fnc_log;
        
        // Decide whether to act on the information
        private _shouldRespond = false;
        private _responseType = "";
        private _operationMode = _self get "_operationMode";
        
        // Determine if this is a significant enemy presence worth responding to
        switch (_operationMode) do {
            case "ATTACK": {
                // In attack mode, only respond to significant forces
                if (_enemyCount >= 8 || _armor > 0 || _air > 0) then {
                    _shouldRespond = true;
                    _responseType = "ATTACK";
                };
            };
            
            case "DEFEND": {
                // In defend mode, respond to even small forces to protect territory
                if (_enemyCount >= 4 || _armor > 0) then {
                    _shouldRespond = true;
                    _responseType = "DEFEND";
                };
            };
            
            case "SKIRMISH": {
                // In skirmish mode, be selective about engagement
                if ((_enemyCount >= 6 && _infantry > 3) || _armor > 0) then {
                    _shouldRespond = true;
                    _responseType = "SKIRMISH";
                };
            };
        };
        
        // If we decide to respond, find a suitable outpost to deploy from
        if (_shouldRespond) then {
            // Get outposts that can deploy task forces
            private _outposts = keys (_self get "_outpostStatus");
            private _availableOutposts = _outposts select {
                private _data = ((_self get "_outpostStatus") get _x) select 0;
                _data < 0.4 // Only deploy from outposts not under heavy threat
            };
            
            if (count _availableOutposts == 0) exitWith {
                ["AI Commander", 3, "Cannot respond to recon report - no outposts available"] call FLO_fnc_log;
            };
            
            // Find the closest outpost to respond
            private _nearOutposts = [_availableOutposts, [], {(getMarkerPos _x) distance _position}, "ASCEND"] call BIS_fnc_sortBy;
            
            if (count _nearOutposts > 0) then {
                private _sourceOutpost = _nearOutposts select 0;
                private _taskForceStrengthFactor = _self get "_taskForceStrengthFactor";
                
                // Calculate appropriate task force size based on enemy force
                private _taskForceSize = round((_enemyCount * 1.5) * _taskForceStrengthFactor);
                _taskForceSize = _taskForceSize max 6 min 30; // Ensure reasonable size limits
                
                // Generate a unique task force ID
                private _sanitizedOutpost = _sourceOutpost;
                // Check if the outpost ID contains coordinates (has square brackets)
                if (_sourceOutpost find "[" > 0) then {
                    // Extract just the base name without coordinates
                    _sanitizedOutpost = "OutpMark" + (str floor random 100000);
                };
                private _taskForceID = format ["TF_RECON_RESPONSE_%1_%2", _sanitizedOutpost, floor(random 1000)];
                
                // Choose appropriate unit types based on enemy composition
                private _unitTypes = [];
                
                if (_armor > 0) then {
                    // If enemy has armor, prioritize AT units
                    private _atSpecialists = East_Units select {_x find "_AT_F" > 0};
                    _unitTypes = East_Units + _atSpecialists;
                } else {
                    if (_air > 0) then {
                        // If enemy has air, prioritize AA units
                        private _aaSpecialists = East_Units select {_x find "_AA_F" > 0};
                        _unitTypes = East_Units + _aaSpecialists;
                    } else {
                        // Regular infantry mix for general response
                        _unitTypes = East_Units;
                    };
                };
                
                // Pull units from the garrison
                private _unitsCount = _self call ["_pullUnitsFromGarrison", [_sourceOutpost, _unitTypes, _taskForceSize, _taskForceID]];
                
                if (_unitsCount > 0) then {
                    // Deploy task force with the pulled units
                    private _taskForceGroup = ["deployTaskForce", [_taskForceID, _position]] call FLO_fnc_TaskForceSystem;
                    
                    // Assign appropriate actions based on response type
                    _self call ["_assignTaskForceActions", [_taskForceGroup, _position, _responseType]];
                    
                    ["AI Commander", 2, format["Deploying %4 force from %1 to respond to recon report at %2 with %3 units", 
                        _sourceOutpost, _position, _unitsCount, _responseType]] call FLO_fnc_log;
                } else {
                    ["AI Commander", 3, format["Failed to pull units from garrison at %1 for recon response", _sourceOutpost]] call FLO_fnc_log;
                };
            };
        } else {
            ["AI Commander", 3, "Recon report noted but no response required"] call FLO_fnc_log;
        };
    }],

    ["_pullUnitsFromGarrison", {
        params ["_marker", "_unitTypes", "_requestedCount", "_taskForceId"];
        
        // Track this marker as the source for this task force
        private _taskForceSourceMap = _self get "_taskForceSourceMap";
        _taskForceSourceMap set [_taskForceId, _marker];
        
        // Track contributions from this garrison
        private _garrisonContributions = _self get "_garrisonContributions";
        private _currentContribution = _garrisonContributions getOrDefault [_marker, 0];
        
        ["AI Commander", 3, format["Attempting to pull %1 units from garrison at %2 for task force %3", 
            _requestedCount, _marker, _taskForceId]] call FLO_fnc_log;
        
        // Initialize result variable
        private _extractedCount = 0;
        
        // Verify parameters before calling
        if (_marker == "" || _requestedCount <= 0 || _taskForceId == "") then {
            ["AI Commander", 1, format["Invalid parameters: marker=%1, count=%2, taskForceId=%3",
                _marker, _requestedCount, _taskForceId]] call FLO_fnc_log;
        } else {
            // Only process if parameters are valid
            if (!isNil "FLO_Garrison_Manager") then {
                // Ensure the count parameter is passed as a number
                _requestedCount = _requestedCount call BIS_fnc_parseNumber;
                if (_requestedCount <= 0) then { _requestedCount = 1; }; // Fallback if parsing fails
                
                // Call extractUnits with clear parameter names for debugging
                _extractedCount = FLO_Garrison_Manager call ["extractUnits", [_marker, _requestedCount, _taskForceId]];
                
                // Update contribution tracking - extractedCount is already a number, no need for count
                _garrisonContributions set [_marker, _currentContribution + _extractedCount];
                
                ["AI Commander", 3, format["Successfully pulled %1 units from garrison at %2 for task force %3", 
                    _extractedCount, _marker, _taskForceId]] call FLO_fnc_log;
            } else {
                ["AI Commander", 1, "Garrison Manager not available for unit extraction"] call FLO_fnc_log;
            };
        };
        
        // Return the extracted count
        _extractedCount
    }],
    
    ["_returnUnitsToGarrison", {
        params ["_taskForceId", "_targetMarker", "_count"];
        
        // Ensure count is a number
        if (typeName _count != "SCALAR") then {
            _count = count _count; // In case an array of units is passed
        };
        
        // Get the original source marker for this task force
        private _taskForceSourceMap = _self get "_taskForceSourceMap";
        private _sourceMarker = _taskForceSourceMap getOrDefault [_taskForceId, _targetMarker];
        
        ["AI Commander", 3, format["Returning %1 units from task force %2 to garrison at %3", 
            _count, _taskForceId, _sourceMarker]] call FLO_fnc_log;
        
        // IMPROVED: Use the new returnUnits method directly from the garrison manager
        private _returnedCount = 0;
        if (!isNil "FLO_Garrison_Manager") then {
            _returnedCount = FLO_Garrison_Manager call ["returnUnits", [_count, _taskForceId, _sourceMarker]];
            
            // Update contribution tracking
            private _garrisonContributions = _self get "_garrisonContributions";
            private _currentContribution = _garrisonContributions getOrDefault [_sourceMarker, 0];
            _garrisonContributions set [_sourceMarker, (_currentContribution - _returnedCount) max 0];
            
            ["AI Commander", 3, format["Successfully returned %1 units to garrison at %2 from task force %3", 
                _returnedCount, _sourceMarker, _taskForceId]] call FLO_fnc_log;
        } else {
            ["AI Commander", 1, "Garrison Manager not available for unit return"] call FLO_fnc_log;
            
            // If we can't return units to garrison, delete them
            {
                if (!isNull _x && {alive _x}) then {
                    deleteVehicle _x;
                };
            } forEach _units;
            
            ["AI Commander", 3, format["Deleted %1 units since Garrison Manager was unavailable", count _units]] call FLO_fnc_log;
        };
        
        // Clean up task force mapping if all units returned
        if (count _units == _returnedCount) then {
            _taskForceSourceMap deleteAt _taskForceId;
        };
        
        _returnedCount
    }],

    // Vehicles are a special assignment by the AI Commander. A Task Force can not request vehicles.
    // They must be assigned by the AI Commander.
    ["_getVehicleForTaskForce", {
        params ["_taskForceID", "_requiredVehicles", "_nearestObjective"];
        
        // Track what we've acquired
        private _vehicleGroups = [];
        private _vehiclesAcquired = 0;
        
        // Check if we have a garrison manager
        if (isNil "FLO_Garrison_Manager") exitWith {
            ["AI Commander", 2, "Cannot get vehicles - Garrison Manager not available"] call FLO_fnc_log;
            _vehicleGroups
        };
        
        // Loop through required vehicles and try to source them from nearby garrisons
        {
            _x params ["_vehType", "_count"];
            
            // Find the closest garrison that has available vehicles
            private _closestMarker = "";
            private _closestDistance = 999999;
            private _vehicleCounts = FLO_Garrison_Manager get "vehicleCounts";
            
            // Check all markers with vehicles
            {
                private _marker = _x;
                private _markerPos = getMarkerPos _marker;
                private _counts = _vehicleCounts get _marker;
                
                // Skip invalid markers
                if (_markerPos isEqualTo [0,0,0]) then {continue};
                
                // Check if we can take a vehicle from this marker
                private _canTake = false;
                private _isHeavy = (_vehType in East_Ground_Vehicles_Heavy);
                
                if (_isHeavy) then {
                    // Need at least one heavy vehicle available
                    _canTake = (_counts select 1) > 0;
                } else {
                    // Need at least one light vehicle available
                    _canTake = (_counts select 0) > 0;
                };
                
                if (_canTake) then {
                    // Calculate distance to objective
                    private _distance = _markerPos distance (getMarkerPos _nearestObjective);
                    
                    // If closer than previous best, use this one
                    if (_distance < _closestDistance) then {
                        _closestMarker = _marker;
                        _closestDistance = _distance;
                    };
                };
            } forEach keys _vehicleCounts;
            
            // If we found a marker with available vehicles, create one
            if (_closestMarker != "") then {
                ["AI Commander", 3, format["Found vehicle %1 at %2 for task force %3", _vehType, _closestMarker, _taskForceID]] call FLO_fnc_log;
                
                // Remove the vehicle from the garrison's count
                FLO_Garrison_Manager call ["removeVehicleFromCount", [_closestMarker, _vehType]];
                
                // Create the vehicle
                private _markerPos = getMarkerPos _closestMarker;
                private _spawnPos = [_markerPos, 10, 100, 5, 0, 0.5, 0, [], [_markerPos, _markerPos]] call BIS_fnc_findSafePos;
                private _vehicle = createVehicle [_vehType, _spawnPos, [], 0, "NONE"];
                
                // Create a group for the vehicle crew
                private _vehGroup = createGroup [east, true];
                
                // Create crew for the vehicle
                private _crew = units (east createVehicleCrew _vehicle);
                
                // Ensure all crew members are in our vehicle group
                {
                    [_x] joinSilent _vehGroup;
                    
                    // Double-check that the unit maintained EAST side after moving in
                    if (side _x != east) then {
                        ["AI Commander", 2, format["Crew member %1 lost EAST side after vehicle assignment, fixing", _x]] call FLO_fnc_log;
                        [_x] joinSilent _vehGroup;
                    };
                } forEach _crew;
                
                // Evaluate the vehicle's capabilities
                FLO_AICommander_UnitCapabilityAnalyzer call ["_evaluateVehicleCapabilities", [_vehicle]];
                
                // Set group ID for the vehicle group
                _vehGroup setGroupIdGlobal [format ["%1_VEH_%2", _taskForceID, _vehiclesAcquired]];
                
                // Add the vehicle group to our return array
                _vehicleGroups pushBack [_vehGroup, _vehicle];
                _vehiclesAcquired = _vehiclesAcquired + 1;
                
                ["AI Commander", 3, format["Created vehicle %1 for task force %2", _vehType, _taskForceID]] call FLO_fnc_log;
            };
        } forEach _requiredVehicles;
        
        // Return the array of vehicle groups
        _vehicleGroups
    }],
    
    ["_assignVehicleActions", {
        params ["_vehicleGroups", "_infantryGroup", "_targetPosition", "_operationType"];
        
        // Ensure we have valid groups
        if (count _vehicleGroups == 0 || isNull _infantryGroup) exitWith {
            ["AI Commander", 3, "Cannot assign vehicle actions - no vehicles or invalid infantry group"] call FLO_fnc_log;
            false
        };
        
        // Get the infantry group leader for position reference
        private _infantryLeader = leader _infantryGroup;
        
        // Assign actions based on the operation type
        {
            _x params ["_vehicleGroup", "_vehicle"];
            
            // Set initial formation and combat settings
            _vehicleGroup setBehaviour "AWARE";
            _vehicleGroup setCombatMode "YELLOW";
            
            switch (_operationType) do {
                case "ATTACK": {
                    // For attack, assign vehicles to support the infantry attack
                    [_vehicleGroup, _targetPosition, "ATTACK", _infantryGroup] call FLO_fnc_attackArea;
                    
                    // Handle different vehicle types appropriately
                    if (_vehicle isKindOf "Tank") then {
                        // Tanks lead the assault
                        _vehicleGroup setFormation "WEDGE";
                        _vehicleGroup setSpeedMode "NORMAL";
                    } else {
                        if (_vehicle isKindOf "APC") then {
                            // APCs provide close support
                            _vehicleGroup setFormation "LINE";
                            _vehicleGroup setSpeedMode "LIMITED";
                        } else {
                            // MRAPs and other vehicles provide perimeter security
                            _vehicleGroup setFormation "DIAMOND";
                            _vehicleGroup setSpeedMode "NORMAL";
                        };
                    };
                };
                
                case "DEFEND": {
                    // For defense, position vehicles at strategic points
                    [_vehicleGroup, _targetPosition, "DEFEND", _infantryGroup] call FLO_fnc_defendArea;
                    
                    // Position different vehicle types appropriately
                    if (_vehicle isKindOf "Tank") then {
                        // Tanks cover the most likely approach
                        _vehicleGroup setFormation "LINE";
                        _vehicleGroup setSpeedMode "LIMITED";
                    } else {
                        // Other vehicles provide perimeter security
                        _vehicleGroup setFormation "DIAMOND";
                        _vehicleGroup setSpeedMode "LIMITED";
                    };
                };
                
                case "PATROL": {
                    // For patrol, vehicles provide mobile reconnaissance
                    [_vehicleGroup, _targetPosition, "PATROL", _infantryGroup] call FLO_fnc_patrolArea;
                    _vehicleGroup setFormation "COLUMN";
                    _vehicleGroup setSpeedMode "NORMAL";
                };
                
                case "SKIRMISH": {
                    // For skirmish, vehicles provide fire support
                    [_vehicleGroup, _targetPosition, "ATTACK", _infantryGroup] call FLO_fnc_attackArea;
                    
                    _vehicleGroup setFormation "WEDGE";
                    _vehicleGroup setSpeedMode "NORMAL";
                };
                
                case "RECON": {
                    // For recon, vehicles provide overwatch
                    [_vehicleGroup, _targetPosition, "RECON", _infantryGroup] call FLO_fnc_reconArea;
                    _vehicleGroup setFormation "DIAMOND";
                    _vehicleGroup setSpeedMode "LIMITED";
                    _vehicleGroup setBehaviour "STEALTH";
                };
                
                default {
                    // Default behavior
                    [_vehicleGroup, _targetPosition] call FLO_fnc_patrolArea;
                };
            };
            
            ["AI Commander", 3, format["Assigned %1 actions to vehicle group %2 supporting infantry group %3", 
                _operationType, _vehicleGroup, _infantryGroup]] call FLO_fnc_log;
            
        } forEach _vehicleGroups;
        
        true
    }],
    
    // Add a new method to select the best outpost based on garrison strength
    ["_selectBestOutpostForTaskForce", {
        params ["_availableOutposts", "_requiredSize"];
        
        // Default to random selection if no specific size is provided
        if (isNil "_requiredSize" || {_requiredSize <= 0}) exitWith {
            selectRandom _availableOutposts
        };
        
        // Get frontline outposts from Logistics Network if available
        private _frontlineOutposts = [];
        if (!isNil "FLO_Logistics_Network") then {
            _frontlineOutposts = FLO_Logistics_Network call ["getFrontlineOutposts", []];
            ["AI Commander", 3, format["Found %1 frontline outposts from Logistics Network", count _frontlineOutposts]] call FLO_fnc_log;
        };
        
        // Filter available outposts to prioritize frontline outposts
        private _prioritizedOutposts = [];
        if (count _frontlineOutposts > 0) then {
            // Only include outposts that are both available and on the frontline
            _prioritizedOutposts = _availableOutposts select {_x in _frontlineOutposts};
            
            ["AI Commander", 3, format["%1 of %2 available outposts are on the frontline", 
                count _prioritizedOutposts, count _availableOutposts]] call FLO_fnc_log;
                
            // If we found frontline outposts among available ones, use only those
            if (count _prioritizedOutposts > 0) then {
                _availableOutposts = _prioritizedOutposts;
            } else {
                ["AI Commander", 3, "No frontline outposts available for task force, using standard available outposts"] call FLO_fnc_log;
            };
        } else {
            ["AI Commander", 3, "No frontline outposts data from Logistics Network, using standard available outposts"] call FLO_fnc_log;
        };
        
        private _bestOutpost = "";
        private _bestSurplus = 0;
        private _candidates = [];
        
        // First, check all outposts and calculate their surplus capacity
        {
            private _outpost = _x;
            // Get garrison data
            private _garrisonStrength = FLO_Garrison_Manager call ["_checkGarrisonStrength", [_outpost]];
            
            // Get minimum required garrison size based on marker type
            private _markerType = markerType _outpost;
            private _baseMinSize = switch (_markerType) do {
                case "o_installation": { 15 };
                case "n_installation": { 12 };
                case "o_support": { 8 };
                case "n_support": { 10 };
                case "loc_Power": { 6 };
                case "o_recon": { 2 };
                case "o_service": { 6 };
                case "o_antiair": { 8 };
                case "loc_Ruin": { 12 };
                default { 4 };
            };
            
            // Calculate adjusted minimum based on current strength
            private _adjustedMin = switch (true) do {
                case (_garrisonStrength >= 75): { _baseMinSize * 0.5 }; // Very large garrisons can go down to 50% of min
                case (_garrisonStrength >= 50): { _baseMinSize * 0.6 }; // Large garrisons can go down to 60% of min
                case (_garrisonStrength >= 30): { _baseMinSize * 0.7 }; // Medium garrisons can go down to 70% of min
                case (_garrisonStrength >= 20): { _baseMinSize * 0.8 }; // Smaller garrisons can go down to 80% of min
                default { _baseMinSize }; // Base minimum for small garrisons
            };
            _adjustedMin = round _adjustedMin max 2;
            
            // Calculate surplus - how many units can we pull without going below the adjusted minimum
            private _surplus = _garrisonStrength - _adjustedMin;
            
            // Add frontline bonus for outposts that are on the frontline
            private _frontlineBonus = if (_outpost in _frontlineOutposts) then {
                // Give extra weight to frontline outposts
                _surplus = _surplus * 1.5;
                " (FRONTLINE)"
            } else {
                ""
            };
            
            // Store as a candidate if it has sufficient surplus
            if (_surplus >= _requiredSize) then {
                // Include outpost, strength, surplus, and frontline status in the candidate data
                _candidates pushBack [_outpost, _garrisonStrength, _surplus, _adjustedMin, _outpost in _frontlineOutposts];
                
                // Track the outpost with the largest surplus as fallback
                if (_surplus > _bestSurplus) then {
                    _bestOutpost = _outpost;
                    _bestSurplus = _surplus;
                };
                
                ["AI Commander", 4, format["Candidate outpost: %1%2 with %3 units (surplus: %4, min: %5)", 
                    _outpost, _frontlineBonus, _garrisonStrength, _surplus, _adjustedMin]] call FLO_fnc_log;
            };
        } forEach _availableOutposts;
        
        // If we have candidates, select the best one
        if (count _candidates > 0) then {
            // First sort by frontline status (prioritize frontline outposts)
            _candidates = [_candidates, [], {if (_x select 4) then {0} else {1}}, "ASCEND"] call BIS_fnc_sortBy;
            
            // Then prioritize by surplus-to-strength ratio within each category (frontline vs non-frontline)
            private _frontlineCandidates = _candidates select {_x select 4};
            private _otherCandidates = _candidates select {!(_x select 4)};
            
            // Sort frontline candidates 
            if (count _frontlineCandidates > 0) then {
                _frontlineCandidates = [_frontlineCandidates, [], {(_x select 2) / (_x select 1)}, "DESCEND"] call BIS_fnc_sortBy;
                
                // Take the top 3 if available
                private _topCandidates = if (count _frontlineCandidates > 3) then {
                    _frontlineCandidates select [0, 3]
                } else {
                    _frontlineCandidates
                };
                
                // From the top candidates, pick the one closest to the task force size + buffer
                _topCandidates = [_topCandidates, [], {abs((_x select 1) - (_requiredSize + 8))}, "ASCEND"] call BIS_fnc_sortBy;
                
                // Select the best candidate
                _bestOutpost = (_topCandidates select 0) select 0;
                
                ["AI Commander", 3, format["Selected FRONTLINE outpost %1 with %2 units (surplus: %3, min: %4) for task force requiring %5 units", 
                    _bestOutpost, 
                    (_topCandidates select 0) select 1, 
                    (_topCandidates select 0) select 2,
                    (_topCandidates select 0) select 3,
                    _requiredSize]] call FLO_fnc_log;
            } else {
                // If no frontline candidates, use other candidates
                _otherCandidates = [_otherCandidates, [], {(_x select 2) / (_x select 1)}, "DESCEND"] call BIS_fnc_sortBy;
                
                // Take the top 3 if available
                private _topCandidates = if (count _otherCandidates > 3) then {
                    _otherCandidates select [0, 3]
                } else {
                    _otherCandidates
                };
                
                // From the top candidates, pick the one closest to the task force size + buffer
                _topCandidates = [_topCandidates, [], {abs((_x select 1) - (_requiredSize + 8))}, "ASCEND"] call BIS_fnc_sortBy;
                
                // Select the best candidate
                _bestOutpost = (_topCandidates select 0) select 0;
                
                ["AI Commander", 3, format["No frontline outposts available with sufficient units. Selected standard outpost %1 with %2 units (surplus: %3, min: %4) for task force requiring %5 units", 
                    _bestOutpost, 
                    (_topCandidates select 0) select 1, 
                    (_topCandidates select 0) select 2,
                    (_topCandidates select 0) select 3,
                    _requiredSize]] call FLO_fnc_log;
            };
        } else {
            // If no suitable candidates, pick the one with the largest garrison
            private _largestOutpost = "";
            private _largestStrength = 0;
            private _isFrontline = false;
            
            {
                private _outpost = _x;
                private _strength = FLO_Garrison_Manager call ["_checkGarrisonStrength", [_outpost]];
                private _outpostIsFrontline = _outpost in _frontlineOutposts;
                
                // Prioritize frontline outposts or ones with larger strength
                if ((_outpostIsFrontline && (!_isFrontline || _strength > _largestStrength * 0.7)) || 
                    (!_isFrontline && !_outpostIsFrontline && _strength > _largestStrength)) then {
                    _largestOutpost = _outpost;
                    _largestStrength = _strength;
                    _isFrontline = _outpostIsFrontline;
                };
            } forEach _availableOutposts;
            
            if (_largestStrength > 0) then {
                _bestOutpost = _largestOutpost;
                private _frontlineStatus = if (_isFrontline) then {"FRONTLINE "} else {""};
                ["AI Commander", 3, format["No outposts with sufficient surplus found. Using largest available: %1%2 with %3 units (need %4)", 
                    _frontlineStatus, _bestOutpost, _largestStrength, _requiredSize]] call FLO_fnc_log;
            } else {
                // Last resort - prioritize frontline outposts for random selection
                if (count _prioritizedOutposts > 0) then {
                    _bestOutpost = selectRandom _prioritizedOutposts;
                    ["AI Commander", 3, format["No outposts with units found. Randomly selected FRONTLINE outpost %1", _bestOutpost]] call FLO_fnc_log;
                } else {
                    // If no frontline outposts, use any available outpost
                    _bestOutpost = selectRandom _availableOutposts;
                    ["AI Commander", 3, format["No outposts with units found. Randomly selected outpost %1", _bestOutpost]] call FLO_fnc_log;
                };
            };
        };
        
        _bestOutpost
    }],
    
    // NEW METHOD: Issue waypoints to virtual group
    ["_issueVirtualGroupWaypoints", {
        params ["_self", "_groupId", "_waypoints"];
        
        // Skip if virtualization system is not initialized
        if (isNil "FLO_virtualGroups") exitWith {
            ["AI Commander", 2, "Cannot issue virtual group waypoints - virtualization system not initialized"] call FLO_fnc_log;
            false
        };
        
        // Update the virtual group's waypoints
        [_groupId, _waypoints] call FLO_fnc_updateVirtualGroupWaypoints;
        
        // Add to tracked virtual groups
        (_self get "_virtualGroups") set [_groupId, diag_tickTime];
        
        ["AI Commander", 3, format["Issued waypoints to virtual group %1", _groupId]] call FLO_fnc_log;
        true
    }],
    
    // NEW METHOD: Assign task to virtual groups at objective
    ["_assignVirtualGroupsTask", {
        params ["_self", "_objectiveId", "_taskType", "_targetPos"];
        
        // Skip if virtualization system is not initialized
        if (isNil "FLO_virtualGroups") exitWith {
            ["AI Commander", 2, "Cannot assign task to virtual groups - virtualization system not initialized"] call FLO_fnc_log;
            false
        };
        
        // Get virtual groups associated with this objective
        private _groups = [FLO_virtualGroups, _objectiveId] call (FLO_virtualGroups get "_getObjectiveGroups");
        if (count _groups == 0) exitWith {
            ["AI Commander", 3, format["No virtual groups found for objective %1", _objectiveId]] call FLO_fnc_log;
            false
        };
        
        // Define waypoint parameters based on task type
        private _wpBehavior = "AWARE";
        private _wpSpeed = "NORMAL";
        private _wpFormation = "COLUMN";
        private _wpCombatMode = "YELLOW";
        
        switch (_taskType) do {
            case "ATTACK": {
                _wpBehavior = "COMBAT";
                _wpSpeed = "FULL";
                _wpCombatMode = "RED";
            };
            case "DEFEND": {
                _wpBehavior = "COMBAT";
                _wpFormation = "LINE";
            };
            case "PATROL": {
                _wpBehavior = "AWARE";
                _wpFormation = "STAG COLUMN";
            };
            case "RECON": {
                _wpBehavior = "STEALTH";
                _wpSpeed = "LIMITED";
            };
        };
        
        // Create waypoint data
        private _waypoints = [[_targetPos, _taskType, _wpBehavior, _wpSpeed, _wpFormation, _wpCombatMode]];
        
        // Issue waypoints to all groups
        {
            [_self, _x, _waypoints] call (_self get "_issueVirtualGroupWaypoints");
        } forEach _groups;
        
        ["AI Commander", 3, format["Assigned %1 task to %2 virtual groups at objective %3", _taskType, count _groups, _objectiveId]] call FLO_fnc_log;
        true
    }]
]];

// Initialize Commander
_aiCommander set ["_commanderUpdateInterval", 300];
_aiCommander set ["_specialOpsUpdateInterval", 900];
_aiCommander set ["_threatThreshold", 0.6];

// Start the commander loop
[_aiCommander] spawn {
    params ["_commander"];
    
    while {true} do {
        // Update the commander
        _commander call ["_update", []];
        
        // Sleep for a bit
        sleep 60;
    };
};

// Set the global AI Commander variable for other scripts to reference
FLO_AI_Commander = _aiCommander;
["AI Commander", 3, "Global AI Commander variable set"] call FLO_fnc_log;

// Return the commander object
_aiCommander 