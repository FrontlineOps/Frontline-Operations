/*
 * Function: FLO_fnc_gtnExecutor
 * Author: Frontline Operations Development Group
 * 
 * Description:
 * Goal Task Network Plan Executor - Executes primitive actions from plans.
 * Bridges GTN plans to actual game commands (group orders, fire missions, etc.)
 * Handles action completion monitoring and failure recovery.
 *
 * Arguments:
 * 0: Commander Reference <HASHMAP> - The OPFOR commander object
 *
 * Return Value:
 * Executor HashMap Object <HASHMAP>
 *
 * Example:
 * private _executor = [_commander] call FLO_fnc_gtnExecutor;
 * _executor call ["_executePrimitive", [_taskNode]];
 */

params [["_commander", nil]];

if (isNil "_commander") exitWith {
    ["GTN", 1, "Executor requires commander reference"] call FLO_fnc_log;
    nil
};

["GTN", 3, "Initializing GTN Executor"] call FLO_fnc_log;

private _executor = createHashMapObject [[
    // AI Commander reference (passed in)
    ["_aiCommander", _commander],

    // GTN Commander reference (set after creation)
    ["_gtnCommander", nil],

    // Active executions (taskId -> execution data)
    ["_activeExecutions", createHashMap],

    // Execution handlers (primitive id -> handler function)
    ["_handlers", createHashMap],

    // Set GTN Commander reference (called after GTN commander is created)
    ["_setGTNCommander", {
        params ["_gtnCmdr"];
        _self set ["_gtnCommander", _gtnCmdr];
    }],
    
    // === HANDLER REGISTRATION ===
    
    ["_registerHandler", {
        params ["_primitiveId", "_handlerFn"];
        private _handlers = _self get "_handlers";
        _handlers set [_primitiveId, _handlerFn];
        _self set ["_handlers", _handlers];
    }],
    
    // Completed task data for param resolution
    ["_completedTaskData", createHashMap],

    // Store completed task data for later reference
    ["_storeTaskData", {
        params ["_key", "_value"];
        private _data = _self get "_completedTaskData";
        _data set [_key, _value];
        _self set ["_completedTaskData", _data];
    }],

    // Get stored task data
    ["_getTaskData", {
        params ["_key"];
        private _data = _self get "_completedTaskData";
        _data getOrDefault [_key, nil]
    }],

    // Resolve dynamic parameter references
    ["_resolveRuntimeParams", {
        params ["_params"];

        private _resolved = [];
        private _completedData = _self get "_completedTaskData";

        {
            private _param = _x;

            if (_param isEqualType "" && {_param find "_SELECTED_" == 0}) then {
                // Look up in completed task data
                private _key = _param select [1];  // Remove leading underscore
                private _value = _completedData getOrDefault [_key, nil];
                if (!isNil "_value") then {
                    _resolved pushBack _value;
                } else {
                    ["GTN", 2, format["Could not resolve param: %1", _param]] call FLO_fnc_log;
                    _resolved pushBack "";
                };
            } else {
                _resolved pushBack _param;
            };
        } forEach _params;

        _resolved
    }],

    // === PRIMITIVE EXECUTION ===

    // Execute a primitive task node
    ["_executePrimitive", {
        params ["_taskNode"];

        private _taskId = _taskNode get "taskId";
        private _rawParams = _taskNode get "params";

        // Resolve any dynamic parameter references
        private _params = _self call ["_resolveRuntimeParams", [_rawParams]];
        
        private _handlers = _self get "_handlers";
        private _handler = _handlers getOrDefault [_taskId, nil];
        
        if (isNil "_handler") exitWith {
            ["GTN", 2, format["No handler registered for primitive: %1", _taskId]] call FLO_fnc_log;
            false
        };

        ["GTN", 3, format[">>> EXECUTING PRIMITIVE: %1 with params: %2", _taskId, _params]] call FLO_fnc_log;
        
        // Create execution context
        private _context = createHashMapFromArray [
            ["commander", _self get "_gtnCommander"],
            ["aiCommander", _self get "_aiCommander"],
            ["executor", _self],
            ["taskNode", _taskNode],
            ["params", _params],
            ["startTime", diag_tickTime],
            ["status", "RUNNING"]
        ];
        
        // Execute handler
        private _result = [_context] call _handler;
        
        // Store active execution
        private _active = _self get "_activeExecutions";
        _active set [_taskId, _context];
        
        _result
    }],
    
    // Check execution status - re-polls RUNNING tasks by re-calling their handler
    ["_checkExecution", {
        params ["_taskId"];

        private _active = _self get "_activeExecutions";
        private _context = _active getOrDefault [_taskId, nil];

        if (isNil "_context") exitWith { "UNKNOWN" };

        private _status = _context get "status";

        // If still RUNNING, re-call the handler to poll for completion
        if (_status == "RUNNING") then {
            private _handlers = _self get "_handlers";
            private _handler = _handlers getOrDefault [_taskId, nil];

            if (!isNil "_handler") then {
                [_context] call _handler;
                _status = _context get "status";
            };
        };

        _status
    }],
    
    // Update execution data
    ["_updateExecution", {
        params ["_taskId", "_key", "_value"];
        
        private _active = _self get "_activeExecutions";
        private _context = _active getOrDefault [_taskId, nil];
        
        if (!isNil "_context") then {
            _context set [_key, _value];
        };
    }],
    
    // Complete an execution
    ["_completeExecution", {
        params ["_taskId", ["_success", true]];
        
        private _active = _self get "_activeExecutions";
        private _context = _active getOrDefault [_taskId, nil];
        
        if (!isNil "_context") then {
            _context set ["status", if (_success) then { "SUCCESS" } else { "FAILED" }];
            _context set ["endTime", diag_tickTime];
        };
    }],
    
    // === INITIALIZATION - Register all handlers ===
    
    ["_initialize", {
        // Register all primitive handlers
        _self call ["_registerHandlers", []];
        ["GTN", 3, "Executor handlers registered"] call FLO_fnc_log;
    }],
    
    ["_registerHandlers", {
        private _cmdr = _self get "_commander";
        
        // prim_select_staging_point
        // Analyzes objective and stores capability requirements for staging flow
        // WAITS for recon intel before proceeding to ensure accurate force sizing
        _self call ["_registerHandler", ["prim_select_staging_point", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _cmdr = _ctx get "commander";
            private _executor = _ctx get "executor";
            private _gtnCmdr = _self get "_gtnCommander";

            // === CHECK IF RECON INTEL IS AVAILABLE ===
            // Wait for recon to complete before staging so we know what force we need
            private _hasGoodIntel = false;
            private _intelWaitStart = (_executor get "_completedTaskData") getOrDefault ["STAGING_INTEL_WAIT_START", -1];
            private _intelTimeout = 300; // 5 minutes max wait for recon

            // Access World State via GTN Commander (Global doesn't exist)
            private _ws = _gtnCmdr call ["_getWorldState", []];
            private _intel = _ws call ["_getObjectiveIntel", [_objId]];
            if (!isNil "_intel") then {
                private _quality = _intel getOrDefault ["intelQuality", 0];
                if (_quality > 0.5) then {
                    _hasGoodIntel = true;
                };
            };

            if (!_hasGoodIntel) then {
                // Force ID to string for consistent HashMap keys
                private _intelKey = str _objId;

                if (_intelWaitStart < 0) then {
                    // First time - start waiting
                    _executor call ["_storeTaskData", ["STAGING_INTEL_WAIT_START", diag_tickTime]];
                    _intelWaitStart = diag_tickTime;
                    ["GTN", 3, format["Staging for %1: Waiting for recon intel before staging", _intelKey]] call FLO_fnc_log;
                };

                private _waitedTime = diag_tickTime - _intelWaitStart;
                if (_waitedTime < _intelTimeout) then {
                    // Still waiting for intel
                    ["GTN", 4, format["Staging for %1: Waiting for recon (%1s/%2s)", 
                        _intelKey, round _waitedTime, _intelTimeout]] call FLO_fnc_log;
                    
                    if (_waitedTime mod 10 < 1) then {
                        private _debugIntel = _ws call ["_getObjectiveIntel", [_intelKey]];
                        ["GTN", 3, format["[DEBUG] Staging Read Result Key(%1): %2", _intelKey, _debugIntel]] call FLO_fnc_log;
                    };
                    
                    if (_ws call ["_isIntelFresh", [_intelKey, _intelTimeout]]) then {
                        ["GTN", 3, format["Staging for %1: Fresh intel found, proceeding", _intelKey]] call FLO_fnc_log;
                        _ctx set ["status", "SUCCESS"];
                        // Clear wait time so next run doesn't wait
                        _executor call ["_storeTaskData", ["STAGING_INTEL_WAIT_START", -1]];
                    };
                } else {
                    // Timeout - proceed without full intel
                    ["GTN", 2, format["Staging for %1: Recon timeout - proceeding with limited intel", _objId]] call FLO_fnc_log;
                    _hasGoodIntel = true; // Force proceed
                };
            };

            // Exit if still waiting for intel
            if !(_hasGoodIntel) exitWith { true };

            // Use GTN Commander's staging position calculation
            private _stagingPos = _cmdr call ["_getStagingPosition", [_objId]];

            if (isNil "_stagingPos") exitWith {
                ["GTN", 2, format["Cannot create staging point - no position for %1", _objId]] call FLO_fnc_log;
                _ctx set ["status", "FAILED"];
                false
            };

            // === ANALYZE OBJECTIVE FOR CAPABILITY REQUIREMENTS ===
            private _analyzer = FLO_GTN_CapabilityAnalyzer;
            private _requiredPower = 100;
            private _requiresAT = false;
            private _requiresAA = false;

            if (!isNil "_analyzer") then {
                private _ws = _gtnCmdr get "_worldState";
                private _objAnalysis = _analyzer call ["_analyzeObjective", [_objId, _ws]];
                if (!isNil "_objAnalysis") then {
                    _requiredPower = _objAnalysis get "recommendedAttackForce";
                    _requiresAT = _objAnalysis get "hasArmor";
                    _requiresAA = _objAnalysis get "hasAA";

                    ["GTN", 3, format["Staging analysis for %1: Required Power=%2, NeedsAT=%3, NeedsAA=%4",
                        _objId, round _requiredPower, _requiresAT, _requiresAA]] call FLO_fnc_log;
                };
            };

            // Store in executor's shared data for cross-task access
            _executor call ["_storeTaskData", ["STAGING_POSITION", _stagingPos]];
            _executor call ["_storeTaskData", ["STAGING_OBJECTIVE", _objId]];
            _executor call ["_storeTaskData", ["STAGING_REQUIRED_POWER", _requiredPower]];
            _executor call ["_storeTaskData", ["STAGING_REQUIRES_AT", _requiresAT]];
            _executor call ["_storeTaskData", ["STAGING_REQUIRES_AA", _requiresAA]];
            _executor call ["_storeTaskData", ["STAGING_ACCUMULATED_POWER", 0]];

            ["GTN", 3, format["Staging point created at %1 for objective %2 (power needed: %3)", 
                _stagingPos, _objId, round _requiredPower]] call FLO_fnc_log;

            _ctx set ["status", "SUCCESS"];
            true
        }]];
        
        // prim_assign_groups_to_staging
        // Capability-aware group assignment - prioritizes groups with required capabilities
        _self call ["_registerHandler", ["prim_assign_groups_to_staging", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _maxGroups = _params param [1, 8]; // Max groups to ever assign
            private _cmdr = _ctx get "commander";
            private _executor = _ctx get "executor";

            // Get staging data from executor shared data
            private _completedData = _executor get "_completedTaskData";
            private _stagingPos = _completedData get "STAGING_POSITION";
            private _requiredPower = _completedData getOrDefault ["STAGING_REQUIRED_POWER", 100];
            private _requiresAT = _completedData getOrDefault ["STAGING_REQUIRES_AT", false];
            private _requiresAA = _completedData getOrDefault ["STAGING_REQUIRES_AA", false];
            private _currentGroups = _completedData getOrDefault ["STAGING_GROUPS", []];
            private _accumulatedPower = _completedData getOrDefault ["STAGING_ACCUMULATED_POWER", 0];

            // === GET CAPABILITY ANALYZER ===
            private _analyzer = FLO_GTN_CapabilityAnalyzer;
            if (isNil "_analyzer") exitWith {
                ["GTN", 2, "Staging failed - Capability Analyzer not available"] call FLO_fnc_log;
                _ctx set ["status", "FAILED"];
                false
            };

            // === CHECK IF WE ALREADY HAVE ENOUGH POWER ===
            if (_accumulatedPower >= _requiredPower && count _currentGroups > 0) exitWith {
                ["GTN", 3, format["Staging complete: Have %1/%2 power with %3 groups",
                    round _accumulatedPower, round _requiredPower, count _currentGroups]] call FLO_fnc_log;
                _ctx set ["status", "SUCCESS"];
                true
            };

            // === FIND MORE GROUPS TO ASSIGN ===
            // Get all available ground forces
            private _feasibility = _analyzer call ["_canExecuteMission", ["ASSAULT", _stagingPos, _requiredPower]];
            private _availableAssets = _feasibility get "availableAssets";

            // Filter out already assigned groups
            _availableAssets = _availableAssets - _currentGroups;

            if (count _availableAssets == 0) exitWith {
                if (count _currentGroups > 0) then {
                    ["GTN", 3, format["No more groups available - proceeding with %1 groups (%2/%3 power)",
                        count _currentGroups, round _accumulatedPower, round _requiredPower]] call FLO_fnc_log;
                    _ctx set ["status", "SUCCESS"];
                } else {
                    ["GTN", 2, "Staging failed - no groups available"] call FLO_fnc_log;
                    _ctx set ["status", "FAILED"];
                };
                count _currentGroups > 0
            };

            // === SCORE AND SELECT GROUPS ===
            private _scoredGroups = [];
            {
                private _gId = _x;
                private _gAnalysis = _analyzer call ["_analyzeGroup", [_gId]];
                if (isNil "_gAnalysis") then { continue };

                private _power = _gAnalysis get "totalCombatPower";
                private _score = _power;

                // Bonus for required capabilities
                if (_requiresAT && (_gAnalysis get "canEngageArmor")) then {
                    _score = _score * 1.5;
                };
                if (_requiresAA && (_gAnalysis get "canEngageAir")) then {
                    _score = _score * 1.5;
                };

                _scoredGroups pushBack [_gId, _score, _power];
            } forEach _availableAssets;

            // Sort by score descending
            _scoredGroups = [_scoredGroups, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;

            // Select groups until we meet power requirement or hit limit
            private _newGroups = [];
            private _newPower = _accumulatedPower;
            {
                if (count _currentGroups + count _newGroups >= _maxGroups) exitWith {};
                if (_newPower >= _requiredPower) exitWith {};

                _x params ["_gId", "_score", "_power"];
                _newGroups pushBack _gId;
                _newPower = _newPower + _power;
            } forEach _scoredGroups;

            if (count _newGroups == 0) exitWith {
                ["GTN", 3, format["No suitable groups found for staging (have %1/%2 power)",
                    round _accumulatedPower, round _requiredPower]] call FLO_fnc_log;
                if (count _currentGroups > 0) then {
                    _ctx set ["status", "SUCCESS"];
                } else {
                    _ctx set ["status", "FAILED"];
                };
                count _currentGroups > 0
            };

            // Order new groups to staging
            {
                _cmdr call ["_orderGroupMove", [_x, _stagingPos, "AWARE"]];
            } forEach _newGroups;

            // Update accumulated groups and power
            private _allGroups = _currentGroups + _newGroups;
            _executor call ["_storeTaskData", ["STAGING_GROUPS", _allGroups]];
            _executor call ["_storeTaskData", ["STAGING_ACCUMULATED_POWER", _newPower]];
            _executor call ["_storeTaskData", ["STAGING_ASSIGNED_COUNT", count _allGroups]];

            ["GTN", 3, format["Assigned %1 new groups to staging (total: %2 groups, %3/%4 power)",
                count _newGroups, count _allGroups, round _newPower, round _requiredPower]] call FLO_fnc_log;

            _ctx set ["status", "SUCCESS"];
            true
        }]];

        // prim_wait_for_staging
        // Waits for groups to arrive and validates power requirements are met
        _self call ["_registerHandler", ["prim_wait_for_staging", {
            params ["_ctx"];
            private _cmdr = _ctx get "commander";
            private _executor = _ctx get "executor";

            // Get staging info from executor shared data
            private _completedData = _executor get "_completedTaskData";
            private _stagingPos = _completedData get "STAGING_POSITION";
            private _groups = _completedData getOrDefault ["STAGING_GROUPS", []];
            private _requiredPower = _completedData getOrDefault ["STAGING_REQUIRED_POWER", 100];
            private _accumulatedPower = _completedData getOrDefault ["STAGING_ACCUMULATED_POWER", 0];

            if (count _groups == 0) exitWith {
                // No groups - fail
                ["GTN", 2, "Staging wait failed - no groups assigned"] call FLO_fnc_log;
                _ctx set ["status", "FAILED"];
                false
            };

            // Check if groups have arrived
            private _arrived = _cmdr call ["_checkGroupsArrived", [_groups, _stagingPos, 300]];

            // Check timeout
            private _waitStart = _completedData getOrDefault ["STAGING_WAIT_START", -1];
            if (_waitStart < 0) then {
                _executor call ["_storeTaskData", ["STAGING_WAIT_START", diag_tickTime]];
                _waitStart = diag_tickTime;
            };
            private _waitedTime = diag_tickTime - _waitStart;
            private _timedOut = _waitedTime > 300; // 5 minutes

            if (_arrived) then {
                // Groups arrived - check if we have enough power
                if (_accumulatedPower >= _requiredPower) then {
                    ["GTN", 3, format["Staging complete: %1 groups arrived with %2/%3 power",
                        count _groups, round _accumulatedPower, round _requiredPower]] call FLO_fnc_log;
                    _ctx set ["status", "SUCCESS"];
                } else {
                    if (_timedOut) then {
                        // Timeout - proceed with what we have
                        ["GTN", 2, format["Staging timeout - proceeding with %1/%2 power",
                            round _accumulatedPower, round _requiredPower]] call FLO_fnc_log;
                        _ctx set ["status", "SUCCESS"];
                    } else {
                        // Not enough power yet - CHECK FOR REINFORCEMENTS
                        private _lastReinfCheck = _completedData getOrDefault ["STAGING_LAST_REINF_CHECK", -1];
                        if (diag_tickTime - _lastReinfCheck > 30) then {
                            _executor call ["_storeTaskData", ["STAGING_LAST_REINF_CHECK", diag_tickTime]];
                            
                            // Calculate how many groups we need based on power deficit
                            private _powerDeficit = _requiredPower - _accumulatedPower;
                            
                            // Get track pool and calculate average power using capability analyzer
                            private _taskNode = _ctx get "taskNode";
                            private _track = _taskNode get "_trackRef";
                            private _poolSize = if (!isNil "_track") then { count (_track get "groupPool") } else { 20 };
                            
                            private _avgPowerPerGroup = 800; // Default fallback
                            if (!isNil "_track" && _poolSize > 0) then {
                                private _analyzer = FLO_GTN_CapabilityAnalyzer;
                                private _pool = _track get "groupPool";
                                private _totalPower = 0;
                                private _sampleSize = _poolSize min 5; // Sample up to 5 groups
                                for "_i" from 0 to (_sampleSize - 1) do {
                                    private _gid = _pool select _i;
                                    private _gAnalysis = _analyzer call ["_analyzeGroup", [_gid]];
                                    if (!isNil "_gAnalysis") then {
                                        _totalPower = _totalPower + (_gAnalysis get "totalCombatPower");
                                    };
                                };
                                if (_sampleSize > 0 && _totalPower > 0) then {
                                    _avgPowerPerGroup = _totalPower / _sampleSize;
                                };
                            };
                            
                            private _groupsNeeded = ceil(_powerDeficit / _avgPowerPerGroup) max 1;
                            private _requestCount = _groupsNeeded min _poolSize; // Request what we need up to pool size
                            
                            ["GTN", 3, format["Staging reinforcement: Need %1 power, pool has %2 groups (avg %3 power/group), requesting %4", 
                                round _powerDeficit, _poolSize, round _avgPowerPerGroup, _requestCount]] call FLO_fnc_log;
                            
                            private _availableGroupIds = if (!isNil "_track") then {
                                _cmdr call ["_getGroupsFromTrack", [_track, _requestCount]]
                            } else {
                                _cmdr call ["_getAvailableGroups", [_requestCount, _stagingPos]]
                            };
                            
                            if (count _availableGroupIds > 0) then {
                                _groups = _executor get "_completedTaskData" getOrDefault ["STAGING_GROUPS", []]; // Refresh local groups list
                                private _analyzer = FLO_GTN_CapabilityAnalyzer;
                                
                                {
                                    private _gid = _x;
                                    // Assign new group
                                    _cmdr call ["_orderGroupMove", [_gid, _stagingPos, "AWARE"]];
                                    _groups pushBackUnique _gid;
                                    
                                    // Add its power
                                    private _gAnalysis = _analyzer call ["_analyzeGroup", [_gid]];
                                    if (!isNil "_gAnalysis") then {
                                        _accumulatedPower = _accumulatedPower + (_gAnalysis get "totalCombatPower");
                                    };
                                    ["GTN", 3, format["Staging Reinforcement: Commander assigned group %1", _gid]] call FLO_fnc_log;
                                } forEach _availableGroupIds;
                                
                                // Update shared data
                                _executor call ["_storeTaskData", ["STAGING_GROUPS", _groups]];
                                _executor call ["_storeTaskData", ["STAGING_ACCUMULATED_POWER", _accumulatedPower]];
                                
                                ["GTN", 3, format["Staging: Added %1 groups, now at %2/%3 power", 
                                    count _availableGroupIds, round _accumulatedPower, round _requiredPower]] call FLO_fnc_log;
                            } else {
                                ["GTN", 2, "Staging: No more groups available in track pool for reinforcement"] call FLO_fnc_log;
                            };
                        };

                        ["GTN", 3, format["Staging: %1 groups arrived but only %2/%3 power - waiting for reinforcements",
                            count _groups, round _accumulatedPower, round _requiredPower]] call FLO_fnc_log;
                        _ctx set ["status", "RUNNING"];
                    };
                };
            } else {
                // Groups still moving
                if (_timedOut) then {
                    ["GTN", 2, format["Staging wait timeout - proceeding with %1 groups (%2/%3 power)",
                        count _groups, round _accumulatedPower, round _requiredPower]] call FLO_fnc_log;
                    _ctx set ["status", "SUCCESS"];
                } else {
                    ["GTN", 3, format["Waiting for staging: %1s/%2s (%3/%4 power)",
                        round _waitedTime, 300, round _accumulatedPower, round _requiredPower]] call FLO_fnc_log;
                    _ctx set ["status", "RUNNING"];
                };
            };

            true
        }]];

        // prim_attack_objective
        // Capability-aware attack that blocks for force buildup until recommended power is met
        _self call ["_registerHandler", ["prim_attack_objective", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _cmdr = _ctx get "commander";
            private _executor = _ctx get "executor";

            // Get objective position
            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith {
                ["GTN", 2, format["Attack failed - no position for objective: %1", _objId]] call FLO_fnc_log;
                _ctx set ["status", "FAILED"];
                false
            };

            // === USE CAPABILITY ANALYZER TO ASSESS OBJECTIVE ===
            private _analyzer = FLO_GTN_CapabilityAnalyzer;
            if (isNil "_analyzer") exitWith {
                ["GTN", 2, "Attack failed - Capability Analyzer not available"] call FLO_fnc_log;
                _ctx set ["status", "FAILED"];
                false
            };

            private _ws = _cmdr get "_worldState";
            private _objAnalysis = _analyzer call ["_analyzeObjective", [_objId, _ws]];
            private _requiredPower = if (!isNil "_objAnalysis") then {
                _objAnalysis get "recommendedAttackForce"
            } else { 100 }; // Fallback if analysis fails

            private _requiresAT = if (!isNil "_objAnalysis") then { _objAnalysis get "hasArmor" } else { false };
            private _requiresAA = if (!isNil "_objAnalysis") then { _objAnalysis get "hasAA" } else { false };

            ["GTN", 3, format["Objective %1 analysis: Required Power=%2, NeedsAT=%3, NeedsAA=%4",
                _objId, round _requiredPower, _requiresAT, _requiresAA]] call FLO_fnc_log;

            // === CHECK IF ASSAULT IS FEASIBLE ===
            private _feasibility = _analyzer call ["_canExecuteMission", ["ASSAULT", _objPos, _requiredPower]];
            private _availablePower = _feasibility get "powerAvailable";
            private _isFeasible = _feasibility get "feasible";

            // === FORCE BUILDUP LOGIC ===
            private _completedData = _executor get "_completedTaskData";
            private _buildupStart = _completedData getOrDefault ["ATTACK_BUILDUP_START", -1];
            private _buildupTimeout = 300; // 5 minutes max wait

            if (!_isFeasible) then {
                // Not enough power - check if we should wait or timeout
                if (_buildupStart < 0) then {
                    // First time - start buildup timer
                    _executor call ["_storeTaskData", ["ATTACK_BUILDUP_START", diag_tickTime]];
                    _buildupStart = diag_tickTime;
                    ["GTN", 3, format["Attack on %1 waiting for force buildup: Have %2/%3 power",
                        _objId, round _availablePower, round _requiredPower]] call FLO_fnc_log;
                };

                private _waitedTime = diag_tickTime - _buildupStart;
                if (_waitedTime < _buildupTimeout) then {
                    // Still waiting for buildup
                    ["GTN", 4, format["Force buildup: %1s/%2s - Power %3/%4",
                        round _waitedTime, _buildupTimeout, round _availablePower, round _requiredPower]] call FLO_fnc_log;
                    _ctx set ["status", "RUNNING"];
                } else {
                    // Timeout - proceed anyway with what we have
                    ["GTN", 2, format["Attack on %1 proceeding after timeout with %2/%3 power",
                        _objId, round _availablePower, round _requiredPower]] call FLO_fnc_log;
                    _isFeasible = true; // Force proceed
                };
            };

            // If still not feasible (and not timed out), keep waiting
            if (!_isFeasible) exitWith { true };

            // === SELECT GROUPS USING CAPABILITY REQUIREMENTS ===
            // Clear buildup timer
            _executor call ["_storeTaskData", ["ATTACK_BUILDUP_START", -1]];

            // Get attack groups - first check for staged groups from earlier primitive
            private _groups = _completedData getOrDefault ["STAGING_GROUPS", []];

            // If no staged groups, check primitiveData (for direct assignment)
            if (count _groups < 1) then {
                private _taskNode = _ctx get "taskNode";
                private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
                _groups = _primData getOrDefault ["assignedGroups", []];
            };

            // If still no groups, use capability-aware selection
            if (count _groups < 1) then {
                private _availableAssets = _feasibility get "availableAssets";

                // Score and sort groups by how well they match requirements
                private _scoredGroups = [];
                {
                    private _gId = _x;
                    private _gAnalysis = _analyzer call ["_analyzeGroup", [_gId]];
                    if (isNil "_gAnalysis") then { continue };

                    private _power = _gAnalysis get "totalCombatPower";
                    private _score = _power;

                    // Bonus for required capabilities
                    if (_requiresAT && (_gAnalysis get "canEngageArmor")) then {
                        _score = _score * 1.5;
                    };
                    if (_requiresAA && (_gAnalysis get "canEngageAir")) then {
                        _score = _score * 1.5;
                    };

                    _scoredGroups pushBack [_gId, _score, _power];
                } forEach _availableAssets;

                // Sort by score descending
                _scoredGroups = [_scoredGroups, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;

                // Select groups until we meet power requirement or hit limit
                private _selectedPower = 0;
                private _maxGroups = 8;
                {
                    if (count _groups >= _maxGroups) exitWith {};
                    if (_selectedPower >= _requiredPower) exitWith {};

                    _x params ["_gId", "_score", "_power"];
                    _groups pushBack _gId;
                    _selectedPower = _selectedPower + _power;
                } forEach _scoredGroups;

                ["GTN", 3, format["Selected %1 groups with %2 power for attack on %3",
                    count _groups, round _selectedPower, _objId]] call FLO_fnc_log;
            } else {
                ["GTN", 3, format["Using %1 pre-staged groups for attack", count _groups]] call FLO_fnc_log;
            };

            if (count _groups < 1) exitWith {
                ["GTN", 2, format["Attack on %1 aborted - no groups available", _objId]] call FLO_fnc_log;
                _ctx set ["status", "FAILED"];
                false
            };

            ["GTN", 3, format["Attacking %1 at %2 with %3 groups", _objId, _objPos, count _groups]] call FLO_fnc_log;

            // Reveal intel to attacking groups so they can engage enemies
            {
                private _gId = _x;
                private _groups = FLO_virtualGroups get "_groups";
                private _gData = _groups get _gId;
                if (!isNil "_gData") then {
                    private _realGroup = _gData get "realGroup";
                    if (!isNull _realGroup) then {
                        _analyzer call ["_revealObjectiveIntelToUnits", [_objId, _realGroup]];
                    };
                };
            } forEach _groups;

            // Order attack
            {
                _cmdr call ["_orderGroupAttack", [_x, _objPos]];
            } forEach _groups;

            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["objectiveId", _objId];
            _primData set ["attackGroups", _groups];
            _primData set ["requiredPower", _requiredPower];
            _primData set ["actualPower", _availablePower];
            _taskNode set ["primitiveData", _primData];

            _ctx set ["status", "SUCCESS"];
            true
        }]];

        // prim_call_artillery
        _self call ["_registerHandler", ["prim_call_artillery", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _missionType = _params param [1, "PREPARATORY"];
            private _rounds = _params param [2, 8];
            private _cmdr = _ctx get "commander";

            // Get objective position
            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith {
                ["GTN", 2, format["Artillery failed - no position for %1", _objId]] call FLO_fnc_log;
                false
            };

            // Request fire mission via GTN Commander
            private _result = _cmdr call ["_requestArtillery", [_objPos, _missionType, _rounds]];

            if (_result) then {
                ["GTN", 3, format["Artillery mission fired at %1", _objId]] call FLO_fnc_log;
                _ctx set ["status", "SUCCESS"];
            };

            _result
        }]];

        // prim_call_cas
        _self call ["_registerHandler", ["prim_call_cas", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _missionType = _params param [1, "CAS"];
            private _cmdr = _ctx get "commander";

            // Get objective position
            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith {
                ["GTN", 2, format["CAS failed - no position for %1", _objId]] call FLO_fnc_log;
                false
            };

            // Request CAS via GTN Commander
            private _result = _cmdr call ["_requestCAS", [_objPos, _missionType]];

            if (_result) then {
                ["GTN", 3, format["CAS mission dispatched to %1", _objId]] call FLO_fnc_log;
                _ctx set ["status", "SUCCESS"];
            };

            _result
        }]];

        // prim_assign_groups_to_defense
        _self call ["_registerHandler", ["prim_assign_groups_to_defense", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _count = _params param [1, 2];
            private _cmdr = _ctx get "commander";

            // Get objective position
            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith { false };

            // Get groups from track pool
            private _taskNode = _ctx get "taskNode";
            private _track = _taskNode get "_trackRef";
            private _available = if (!isNil "_track") then {
                _cmdr call ["_getGroupsFromTrack", [_track, _count]]
            } else {
                _cmdr call ["_getAvailableGroups", [_count]]
            };

            if (count _available < 1) exitWith { false };

            // Order to defend
            {
                _cmdr call ["_orderGroupDefend", [_x, _objPos]];
            } forEach _available;

            ["GTN", 3, format["Assigned %1 groups to defend %2", count _available, _objId]] call FLO_fnc_log;
            _ctx set ["status", "SUCCESS"];
            true
        }]];

        // prim_set_defense_posture
        _self call ["_registerHandler", ["prim_set_defense_posture", {
            params ["_ctx"];
            // Immediate completion - posture is set by defend order
            _ctx set ["status", "SUCCESS"];
            true
        }]];

        // prim_move_to_position
        _self call ["_registerHandler", ["prim_move_to_position", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _mode = _params param [1, "AWARE"];
            private _cmdr = _ctx get "commander";

            // Get objective position
            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith { false };

            // Get groups from track pool
            private _taskNode = _ctx get "taskNode";
            private _track = _taskNode get "_trackRef";
            private _available = if (!isNil "_track") then {
                _cmdr call ["_getGroupsFromTrack", [_track, 2]]
            } else {
                _cmdr call ["_getAvailableGroups", [2]]
            };

            if (count _available < 1) exitWith { false };

            // Order move
            {
                _cmdr call ["_orderGroupMove", [_x, _objPos, _mode]];
            } forEach _available;

            true
        }]];

        // prim_select_priority_objective
        _self call ["_registerHandler", ["prim_select_priority_objective", {
            params ["_ctx"];
            private _cmdr = _ctx get "commander";
            private _executor = _ctx get "executor";

            // Get highest priority enemy objective
            private _objId = _cmdr call ["_selectPriorityObjective", []];

            if (isNil "_objId" || _objId == "") exitWith {
                ["GTN", 2, "No priority objective found"] call FLO_fnc_log;
                false
            };

            ["GTN", 3, format["Selected priority objective: %1", _objId]] call FLO_fnc_log;

            // Store in executor's shared data for param resolution
            _executor call ["_storeTaskData", ["SELECTED_OBJECTIVE", _objId]];

            // Also store in task node for local reference
            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["selectedObjective", _objId];
            _taskNode set ["primitiveData", _primData];

            _ctx set ["status", "SUCCESS"];
            true
        }]];

        // prim_identify_weak_sector
        _self call ["_registerHandler", ["prim_identify_weak_sector", {
            params ["_ctx"];
            private _cmdr = _ctx get "commander";
            private _executor = _ctx get "executor";
            private _ws = _cmdr get "_worldState";

            // Find sector with lowest friendly force count
            private _objectives = _ws call ["_getObjectives", []];
            private _weakest = "";
            private _lowestCount = 999;

            {
                private _obj = _objectives get _x;
                if ((_obj get "owner") == east) then {
                    private _friendly = _obj get "friendlyCount";
                    if (_friendly < _lowestCount) then {
                        _lowestCount = _friendly;
                        _weakest = _x;
                    };
                };
            } forEach (keys _objectives);

            ["GTN", 3, format["Identified weak sector: %1 (friendly count: %2)", _weakest, _lowestCount]] call FLO_fnc_log;

            // Store in executor's shared data for param resolution
            _executor call ["_storeTaskData", ["WEAK_SECTOR", _weakest]];

            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["weakSector", _weakest];
            _taskNode set ["primitiveData", _primData];

            _ctx set ["status", "SUCCESS"];
            true
        }]];

        // prim_move_forces_to_sector
        _self call ["_registerHandler", ["prim_move_forces_to_sector", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _cmdr = _ctx get "commander";

            // Get the weak sector from previous task
            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            private _sectorId = _primData getOrDefault ["weakSector", _params param [0, ""]];

            private _objPos = [_sectorId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith { false };

            // Get groups from track pool
            private _track = _taskNode get "_trackRef";
            private _available = if (!isNil "_track") then {
                _cmdr call ["_getGroupsFromTrack", [_track, 2]]
            } else {
                _cmdr call ["_getAvailableGroups", [2]]
            };
            if (count _available < 1) exitWith { false };

            {
                _cmdr call ["_orderGroupMove", [_x, _objPos, "AWARE"]];
            } forEach _available;

            _primData set ["arrived", false];
            _taskNode set ["primitiveData", _primData];
            true
        }]];

        // prim_attack_vulnerable_objective
        _self call ["_registerHandler", ["prim_attack_vulnerable_objective", {
            params ["_ctx"];
            private _cmdr = _ctx get "commander";
            private _ws = _cmdr get "_worldState";

            // Get vulnerable objectives
            private _vulnObjs = _ws call ["_getVulnerableObjectives", []];
            if (count (keys _vulnObjs) == 0) exitWith { false };

            // Select first vulnerable objective
            private _objId = (keys _vulnObjs) select 0;
            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith { false };

            // Get groups from track pool
            private _taskNode = _ctx get "taskNode";
            private _track = _taskNode get "_trackRef";
            private _available = if (!isNil "_track") then {
                _cmdr call ["_getGroupsFromTrack", [_track, 4]]
            } else {
                _cmdr call ["_getAvailableGroups", [4]]
            };
            if (count _available < 2) exitWith { false };

            {
                _cmdr call ["_orderGroupAttack", [_x, _objPos]];
            } forEach _available;

            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["objectiveId", _objId];
            _taskNode set ["primitiveData", _primData];

            true
        }]];

        // prim_call_defensive_fires
        _self call ["_registerHandler", ["prim_call_defensive_fires", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _cmdr = _ctx get "commander";

            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith {
                ["GTN", 2, format["Defensive fires failed - no position for %1", _objId]] call FLO_fnc_log;
                _ctx set ["status", "FAILED"];
                false
            };

            // Call for defensive artillery
            private _result = _cmdr call ["_requestArtillery", [_objPos, "DEFENSIVE", 6]];
            
            if (!_result) then {
                ["GTN", 2, format["Defensive fires failed - artillery unavailable for %1", _objId]] call FLO_fnc_log;
            };

            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["missionFired", _result];
            _taskNode set ["primitiveData", _primData];

            _ctx set ["status", if (_result) then {"SUCCESS"} else {"FAILED"}];
            _result
        }]];

        // prim_establish_defense
        _self call ["_registerHandler", ["prim_establish_defense", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _cmdr = _ctx get "commander";

            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith { false };

            // Get groups from track pool
            private _taskNode = _ctx get "taskNode";
            private _track = _taskNode get "_trackRef";
            private _available = if (!isNil "_track") then {
                _cmdr call ["_getGroupsFromTrack", [_track, 2]]
            } else {
                _cmdr call ["_getAvailableGroups", [2]]
            };
            if (count _available < 1) exitWith { false };

            {
                _cmdr call ["_orderGroupDefend", [_x, _objPos]];
            } forEach _available;

            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["established", true];
            _taskNode set ["primitiveData", _primData];

            _ctx set ["status", "SUCCESS"];
            true
        }]];

        _self call ["_registerHandler", ["prim_send_recon_patrol", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _cmdr = _ctx get "commander";
            private _gtnCmdr = _self get "_gtnCommander";

            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith { false };

            private _available = _cmdr call ["_getAvailableGroups", [1]];
            private _groups = FLO_virtualGroups get "_groups";
            private _infantry = _available select {
                private _gData = _groups get _x;
                (_gData get "groupType") in ["infantry", "recon"]
            };
            if (count _infantry < 1) exitWith { false };

            private _reconGroup = _infantry select 0;
            // Use random direction and safer distance (800m+)
            private _reconPos = _objPos getPos [500, random 90];

            _cmdr call ["_orderGroupMove", [_reconGroup, _reconPos, "STEALTH"]];

            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["patrolDispatched", true];
            _primData set ["reconGroup", _reconGroup];
            _primData set ["objectiveId", _objId];
            _taskNode set ["primitiveData", _primData];

            ["GTN", 3, format["Recon patrol dispatched to %1 (Dist: 500m)", _objId]] call FLO_fnc_log;
            _ctx set ["status", "SUCCESS"];

            // Use capability analyzer to get REAL intel about the objective
            [_gtnCmdr, _objId, _reconGroup, _reconPos] spawn {
                params ["_gtnCmdr", "_objId", "_reconGroup", "_reconPos"];
                
                // Simple wait for travel time (approx 2 mins for 500m)
                sleep 120;
                
                if (isNil "_gtnCmdr") exitWith {};
                
                // Reveal objective units to the recon group
                private _gData = FLO_virtualGroups getOrDefault ["_groups", createHashMap] getOrDefault [_reconGroup, createHashMap];
                private _realGroup = _gData getOrDefault ["group", grpNull]; // Try to get real group if spawned
                
                if (!isNull _realGroup) then {
                    private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
                    private _targets = _objPos nearEntities [["Man", "LandVehicle", "Tank"], 1000];
                    {
                        if (side _x != west) then {
                            _realGroup reveal [_x, 4];
                        };
                    } forEach _targets;
                    ["GTN", 3, format["Recon Group %1 revealed %2 targets at %3", _reconGroup, count _targets, _objId]] call FLO_fnc_log;
                };
                if (isNil "_gtnCmdr") exitWith {};
                private _ws = _gtnCmdr get "_worldState";
                if (isNil "_ws") exitWith {};

                // Use the capability analyzer to get actual objective data
                private _analyzer = FLO_GTN_CapabilityAnalyzer;
                if (isNil "_analyzer") exitWith {};

                private _objAnalysis = _analyzer call ["_analyzeObjective", [_objId, _ws]];
                if (isNil "_objAnalysis") exitWith {};

                // Convert analyzer data to intel format
                private _garrisonCount = count (_objAnalysis get "garrison");
                private _totalPower = _objAnalysis get "totalDefensePower";
                private _posture = switch true do {
                    case (_totalPower > 500): { "HEAVY" };
                    case (_totalPower > 200): { "MEDIUM" };
                    case (_totalPower > 0): { "LIGHT" };
                    default { "NONE" };
                };

                private _intel = createHashMapFromArray [
                    ["intelQuality", 0.9],
                    ["confirmedStrength", _garrisonCount],
                    ["totalCombatPower", _totalPower],
                    ["hasArmor", _objAnalysis get "hasArmor"],
                    ["hasAA", _objAnalysis get "hasAA"],
                    ["hasStatic", _objAnalysis get "hasStatic"],
                    ["defensePosture", _posture],
                    ["fortificationLevel", _objAnalysis get "fortificationLevel"],
                    ["recommendedForce", _objAnalysis get "recommendedAttackForce"]
                ];
                _ws call ["_updateObjectiveIntel", [_objId, _intel]];

                ["GTN", 3, format["Recon intel gathered for %1: %2 groups, power %3, posture %4",
                    _objId, _garrisonCount, _totalPower, _posture]] call FLO_fnc_log;
            };

            true
        }]];

        _self call ["_registerHandler", ["prim_wait_for_recon", {
            params ["_ctx"];
            // Recon intel gathering happens async - auto-complete this wait
            // The intel will be updated when patrol/aircraft arrives
            _ctx set ["status", "SUCCESS"];
            true
        }]];

        _self call ["_registerHandler", ["prim_request_air_recon", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _cmdr = _ctx get "commander";
            private _gtnCmdr = _self get "_gtnCommander";

            // Check if we've already dispatched and are waiting for intel
            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            private _dispatched = _primData getOrDefault ["dispatched", false];
            private _reconComplete = _primData getOrDefault ["reconComplete", false];

            // Phase 2: Already dispatched, check if intel is ready
            if (_dispatched) exitWith {
                if (_reconComplete) then {
                    ["GTN", 3, format["Air recon for %1 complete - intel gathered", _objId]] call FLO_fnc_log;
                    _ctx set ["status", "SUCCESS"];
                } else {
                    _ctx set ["status", "RUNNING"];
                };
                true
            };

            // Phase 1: Dispatch aircraft
            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith {
                ["GTN", 2, format["Air recon failed - no position for %1", _objId]] call FLO_fnc_log;
                _ctx set ["status", "FAILED"];
                false
            };

            // Request an actual air asset to fly over
            private _mgr = call FLO_fnc_gtnAirAssetManager;
            private _asset = _mgr call ["_requestAirAsset", [_objPos, "RECON"]];

            if (_asset isEqualTo objNull) exitWith {
                ["GTN", 2, "Air recon failed - no available air assets"] call FLO_fnc_log;
                false
            };

            private _aircraft = _asset select 0;
            private _groupId = _asset select 1;
            
            // Get the real group from group data
            private _groups = FLO_virtualGroups get "_groups";
            private _gData = _groups get _groupId;
            private _grp = _gData get "realGroup";

            ["GTN", 3, format["Air recon dispatched: %1 flying to %2", typeOf _aircraft, _objId]] call FLO_fnc_log;

            // Mark as dispatched immediately
            _primData set ["dispatched", true];
            _primData set ["reconComplete", false];
            _primData set ["objectiveId", _objId];
            _primData set ["aircraftGroupId", _groupId];
            _taskNode set ["primitiveData", _primData];

            // Set aircraft to fly over objective at high altitude
            _aircraft flyInHeight 400;

            // Wait a frame for spawn to fully complete before setting waypoints
            // This ensures crew is in vehicle and group is properly initialized
            [_grp, _objPos, _gtnCmdr, _objId, _groupId, _mgr, _aircraft, _taskNode] spawn {
                params ["_grp", "_objPos", "_gtnCmdr", "_objId", "_groupId", "_mgr", "_aircraft", "_taskNode"];
                
                sleep 1; // Allow spawn to complete
                
                if (isNull _grp) exitWith {
                    ["GTN", 2, "Air recon failed - group is null after spawn delay"] call FLO_fnc_log;
                };

                // Clear waypoints
                [_grp] call CBA_fnc_clearWaypoints;

                _grp setBehaviour "AWARE";
                _grp setCombatMode "GREEN";  // Don't engage
                _grp setSpeedMode "NORMAL";

                // Flyover waypoint
                private _wp1 = _grp addWaypoint [_objPos, 100];
                _wp1 setWaypointType "MOVE";
                _wp1 setWaypointSpeed "FULL";
                _wp1 setWaypointCombatMode "GREEN";
                // _grp setCurrentWaypoint [_grp, 1];
                
                ["GTN", 3, format["Air recon waypoint set for %1", _groupId]] call FLO_fnc_log;
                
                // Track update time
                _taskNode set ["lastUpdate", diag_tickTime];
            };

            // Spawn handler for when aircraft arrives and gathers intel
            [_gtnCmdr, _objId, _objPos, _groupId, _mgr, _aircraft, _taskNode] spawn {
                params ["_gtnCmdr", "_objId", "_objPos", "_groupId", "_mgr", "_aircraft", "_taskNode"];

                // Wait for aircraft to get close to objective (or timeout)
                private _startTime = diag_tickTime;
                private _timeout = 180;  // 3 minutes max

                waitUntil {
                    sleep 5;
                    isNull _aircraft ||
                    !alive _aircraft ||
                    (_aircraft distance2D _objPos < 500) ||
                    (diag_tickTime - _startTime > _timeout)
                };

                if (isNull _aircraft || !alive _aircraft) exitWith {
                    ["GTN", 2, "Air recon aircraft lost"] call FLO_fnc_log;
                    _mgr call ["_releaseAirAsset", [_groupId]];
                };

                ["GTN", 3, format["Air recon aircraft over %1 - gathering intel", _objId]] call FLO_fnc_log;

                // Gather intel now that aircraft is over objective
                if (isNil "_gtnCmdr") exitWith { _mgr call ["_releaseAirAsset", [_groupId]]; };
                private _ws = _gtnCmdr get "_worldState";
                if (isNil "_ws") exitWith { _mgr call ["_releaseAirAsset", [_groupId]]; };

                private _detectedUnits = [];
                private _scanDuration = 15;
                private _scanEnd = diag_tickTime + _scanDuration;
                
                // Full Reveal to simulate advanced sensors (Radar/Thermal)
                // This overcomes AI blindness by forcing knowledge of nearby enemy units
                // We set it to 4 for incoming CAS Aircraft to allow them to see targets. This is a very specific behavior.
                // Aircraft do not attack targets that are not revealed to them at the knowsAbout Level of 1.5.
                // This is a problem because 4 is very rare for most AI. Most AI will never have a level of knowsAbout 4.
                // This is why we use a nearEntities call to reveal targets to the aircraft.
                private _nearEntities = _objPos nearEntities [["Man", "AllVehicles"], 1500];
                private _enemySide = west; // OPFOR commander scouting BLUFOR positions
                private _enemyEntities = _nearEntities select { side _x == _enemySide || side group _x == _enemySide };
                
                // Reveal enemies to aircraft CREW so nearTargets can detect them
                // nearTargets returns what the CREW sees, not the vehicle itself
                private _crew = crew _aircraft;
                {
                    private _enemy = _x;
                    {
                        _x reveal [_enemy, 4];
                    } forEach _crew;
                } forEach _enemyEntities;

                ["GTN", 3, format["Air Sensors revealed %1 BLUFOR targets to %2 crew members", count _enemyEntities, count _crew]] call FLO_fnc_log;
                
                while {diag_tickTime < _scanEnd && alive _aircraft} do {
                    // nearTargets returns what CREW sees, not vehicle
                    // [[pos, type, side, subjectiveCost, object, positionAccuracy], ...]
                    private _targets = _aircraft nearTargets 2000;
                    
                    {
                        _x params ["_pos", "_type", "_side", "_cost", "_obj", "_accuracy"];
                        
                        // Detect enemy targets that are actual units
                        if (!isNull _obj && {_obj isKindOf "AllVehicles" || _obj isKindOf "Man"}) then {
                            if (side _obj == _enemySide || side group _obj == _enemySide) then {
                                _detectedUnits pushBackUnique _obj;
                            };
                        };
                    } forEach _targets;
                    
                    sleep 2;
                };

                // Analyze what we found using Capability Analyzer
                private _analysis = FLO_GTN_CapabilityAnalyzer call ["_analyzeObservedForces", [_detectedUnits]];
                
                // Add intel quality (Air recon is good but misses indoor units)
                _analysis set ["intelQuality", 0.7];
                _analysis set ["fortificationLevel", 0]; 
                _analysis set ["recommendedForce", 0]; 

                _ws call ["_updateObjectiveIntel", [_objId, _analysis]];

                ["GTN", 3, format["Air Recon for %1: Saw %2 units. Power: %3. AA: %4. Posture: %5", 
                     _objId, 
                     count _detectedUnits, 
                     _analysis get "totalCombatPower", 
                     _analysis get "hasAA",
                     _analysis get "defensePosture"
                 ]] call FLO_fnc_log;

                // Mark recon as complete AFTER intel is gathered
                private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
                _primData set ["reconComplete", true];
                _taskNode set ["primitiveData", _primData];
                ["GTN", 3, "Air recon intel gathering complete - reconComplete flag set"] call FLO_fnc_log;

                // Loiter briefly then RTB
                sleep 30;
                _mgr call ["_releaseAirAsset", [_groupId]];
                ["GTN", 3, format["Air recon complete - aircraft RTB"]] call FLO_fnc_log;
            };

            // Return RUNNING - the spawn block will set reconComplete when done
            _ctx set ["status", "RUNNING"];
            true
        }]];

        _self call ["_registerHandler", ["prim_use_existing_intel", {
            params ["_ctx"];
            _ctx set ["status", "SUCCESS"];
            true
        }]];

        // prim_select_target_concentration
        _self call ["_registerHandler", ["prim_select_target_concentration", {
            params ["_ctx"];
            private _cmdr = _ctx get "commander";
            private _executor = _ctx get "executor";
            private _ws = _cmdr get "_worldState";
            
            private _intel = _ws call ["_getEnemyIntel", []];
            private _concentrations = _intel getOrDefault ["concentrations", []];
            
            if (count _concentrations == 0) exitWith {
                ["GTN", 3, "No enemy concentrations found for interdiction"] call FLO_fnc_log;
                false
            };
            
            // Find highest strength concentration not recently engaged and not too close to friendlies?
            // For now, just highest strength.
            private _bestTarget = [];
            private _maxStrength = -1;
            
            {
                private _str = _x get "strength";
                private _pos = _x get "position";
                
                // Check safety distance from friendlies (300m)
                private _nearestFriendly = _ws call ["_getNearestFriendlyDistance", [_pos]];
                
                if (_nearestFriendly > 300) then {
                     if (_str > _maxStrength) then {
                         _maxStrength = _str;
                         _bestTarget = _pos;
                     };
                };
            } forEach _concentrations;
            
            if (count _bestTarget == 0) exitWith {
                ["GTN", 3, "No valid targets found (all too close to friendlies or empty)"] call FLO_fnc_log;
                false
            };
            
            ["GTN", 3, format["Selected interdiction target at %1 (Strength: %2)", _bestTarget, _maxStrength]] call FLO_fnc_log;
            
            // Store coordinate
            _executor call ["_storeTaskData", ["SELECTED_CONCENTRATION", _bestTarget]];
            
            _ctx set ["status", "SUCCESS"];
            true
        }]];
        
        // prim_call_artillery_coord
        _self call ["_registerHandler", ["prim_call_artillery_coord", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _targetPos = _params param [0, [0,0,0]];
            
            if (_targetPos isEqualTo [0,0,0]) exitWith { false };
            
            // 4 rounds, standard accuracy
            private _result = FLO_GTNArtilleryManager call ["_requestFireMission", [_targetPos, 4, 100]];
            
            if (_result) then {
                ["GTN", 3, format["Artillery interdiction fired at %1", _targetPos]] call FLO_fnc_log;
                _ctx set ["status", "SUCCESS"];
                
                // Mark success in primitive data
                private _taskNode = _ctx get "taskNode";
                private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
                _primData set ["missionFired", true];
                _taskNode set ["primitiveData", _primData];
            };
            
            _result
        }]];

        // prim_call_cas_coord
        _self call ["_registerHandler", ["prim_call_cas_coord", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _targetPos = _params param [0, [0,0,0]];
            private _cmdr = _ctx get "commander";
            
            if (_targetPos isEqualTo [0,0,0]) exitWith { false };

            // Request CAS via GTN Commander
            private _result = _cmdr call ["_requestCAS", [_targetPos, "CAS"]];

            if (_result) then {
                ["GTN", 3, format["CAS interdiction mission dispatched to %1", _targetPos]] call FLO_fnc_log;
                _ctx set ["status", "SUCCESS"];
                
                private _taskNode = _ctx get "taskNode";
                private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
                _primData set ["missionComplete", true];
                _taskNode set ["primitiveData", _primData];
            };

            _result
        }]];

        // prim_assault_coord
        _self call ["_registerHandler", ["prim_assault_coord", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _targetPos = _params param [0, [0,0,0]];
            private _cmdr = _ctx get "commander";
            
            if (_targetPos isEqualTo [0,0,0]) exitWith { false };
            
            // Get groups from track pool
            private _taskNode = _ctx get "taskNode";
            private _track = _taskNode get "_trackRef";
            private _available = if (!isNil "_track") then {
                _cmdr call ["_getGroupsFromTrack", [_track, 3]]
            } else {
                _cmdr call ["_getAvailableGroups", [3, _targetPos]]
            };
            if (count _available < 1) exitWith { 
                ["GTN", 3, "Assault cancelled - no forces available"] call FLO_fnc_log;
                false 
            };
            
            {
                _cmdr call ["_orderGroupAttack", [_x, _targetPos]];
            } forEach _available;
            
            ["GTN", 3, format["Assault ordered on coordinate %1 with %2 groups", _targetPos, count _available]] call FLO_fnc_log;
            
            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["arrived", true];
            _taskNode set ["primitiveData", _primData];
            
            _ctx set ["status", "SUCCESS"];
            true
        }]];

        // prim_select_garrison_objective
        // Selects garrison objective using World State analysis:
        // - Exposed flanks (adjacent to enemy objectives)
        // - Recent attack history
        // - Current force ratio at objective
        // - Strategic value in the objective graph
        _self call ["_registerHandler", ["prim_select_garrison_objective", {
            params ["_ctx"];
            private _executor = _ctx get "executor";
            private _gtnCmdr = _self get "_gtnCommander";
            private _ws = _gtnCmdr get "_worldState";
            
            // Get our objectives from World State
            private _friendlyObjs = _ws call ["_getFriendlyObjectives", []];
            if (count (keys _friendlyObjs) == 0) exitWith {
                _ctx set ["status", "FAILED"];
                false
            };
            
            // Analyze each objective for garrison priority
            private _scoredObjs = [];
            {
                private _objId = _x;
                private _objData = _friendlyObjs get _objId;
                private _pos = _objData get "position";
                
                // Get threat analysis from capability analyzer
                private _analysis = FLO_GTN_CapabilityAnalyzer call ["_analyzeObjective", [_objId, _ws]];
                private _threatLevel = _analysis get "threatLevel";
                
                // Check exposed flanks (linked to enemy objectives)
                private _linkedObjs = _objData get "linkedObjectives";
                private _exposedFlanks = { (FLO_Objectives get _x get "owner") == west } count _linkedObjs;
                
                // Force ratio from World State
                private _friendlyCount = _objData get "friendlyCount";
                private _enemyCount = _objData get "enemyCount";
                private _forceDeficit = (_enemyCount * 1.5) - _friendlyCount;
                
                // Score: threat + flanks + deficit + priority
                private _basePriority = _objData get "priority";
                private _score = (_threatLevel * 10) + (_exposedFlanks * 30) + (_forceDeficit max 0) * 10 + (_basePriority / 2);
                
                _scoredObjs pushBack [_objId, _pos, _score, _exposedFlanks, _threatLevel];
                
            } forEach (keys _friendlyObjs);
            
            // Select highest need
            _scoredObjs = [_scoredObjs, [], {_x select 2}, "DESCEND"] call BIS_fnc_sortBy;
            private _selected = _scoredObjs select 0;
            _selected params ["_objId", "_objPos", "_score", "_flanks", "_threat"];
            
            _executor call ["_storeTaskData", ["_GARRISON_OBJECTIVE", _objId]];
            _executor call ["_storeTaskData", ["GARRISON_POSITION", _objPos]];
            _executor call ["_storeTaskData", ["GARRISON_ENEMY_DIST", 1500]]; // Assume frontline if flanks exposed
            
            ["GTN", 3, format["Garrison select: %1 (score:%2 flanks:%3 threat:%4)", 
                _objId, round _score, _flanks, _threat]] call FLO_fnc_log;
            
            _ctx set ["status", "SUCCESS"];
            true
        }]];

        // prim_assign_garrison_groups
        // Assigns groups to garrison based on threat analysis
        _self call ["_registerHandler", ["prim_assign_garrison_groups", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _cmdr = _ctx get "commander";
            private _executor = _ctx get "executor";
            private _gtnCmdr = _self get "_gtnCommander";
            
            // Get objective ID from stored task data
            private _objId = _executor call ["_getTaskData", ["_GARRISON_OBJECTIVE"]];
            private _objData = FLO_Objectives get _objId;
            private _targetPos = _objData get "position";
            private _enemyDist = _executor call ["_getTaskData", ["GARRISON_ENEMY_DIST"]];
            
            // Analyze threat using capability analyzer
            private _ws = _gtnCmdr get "_worldState";
            private _analysis = FLO_GTN_CapabilityAnalyzer call ["_analyzeObjective", [_objId, _ws]];
            
            private _requiresAT = _analysis get "requiresAT";
            private _requiresAA = _analysis get "requiresAA";
            private _threatLevel = _analysis get "threatLevel";
            private _groupsNeeded = (ceil (_threatLevel / 2)) max 1 min 4;
            
            // Frontline objectives get more garrison
            if (_enemyDist < 1500) then { _groupsNeeded = _groupsNeeded + 1 };
            
            // Get available groups
            private _available = _cmdr call ["_getAvailableGroups", [_groupsNeeded * 2, _targetPos]];
            if (count _available == 0) exitWith {
                ["GTN", 3, "No groups available for garrison"] call FLO_fnc_log;
                _ctx set ["status", "FAILED"];
                false
            };
            
            // Prioritize by type based on threat
            private _toAssign = [];
            
            if (_requiresAT) then {
                private _atGroups = _available select {
                    (_cmdr call ["_getGroupType", [_x]]) in ["mechanized", "armor"]
                };
                { _toAssign pushBackUnique _x } forEach (_atGroups select [0, 1]);
            };
            
            // Fill remaining slots
            {
                if (count _toAssign >= _groupsNeeded) then { break };
                _toAssign pushBackUnique _x;
            } forEach _available;
            
            // Order groups to defend
            { _cmdr call ["_orderGroupDefend", [_x, _targetPos]] } forEach _toAssign;
            
            ["GTN", 3, format["Garrison: %1 groups to %2 (AT:%3 AA:%4)", 
                count _toAssign, _objId, _requiresAT, _requiresAA]] call FLO_fnc_log;
            
            _ctx set ["status", "SUCCESS"];
            true
        }]];
    }]
]];

// Initialize handlers
_executor call ["_initialize", []];

["GTN", 3, "GTN Executor initialized"] call FLO_fnc_log;

_executor
