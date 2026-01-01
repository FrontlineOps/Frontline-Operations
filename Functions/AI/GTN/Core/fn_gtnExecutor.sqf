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
    
    // Check execution status
    ["_checkExecution", {
        params ["_taskId"];
        
        private _active = _self get "_activeExecutions";
        private _context = _active getOrDefault [_taskId, nil];
        
        if (isNil "_context") exitWith { "UNKNOWN" };
        
        _context get "status"
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
        _self call ["_registerHandler", ["prim_select_staging_point", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _cmdr = _ctx get "commander";

            // Use GTN Commander's staging position calculation
            private _stagingPos = _cmdr call ["_getStagingPosition", [_objId]];

            if (_stagingPos isEqualTo [0,0,0]) exitWith {
                ["GTN", 2, format["Cannot create staging point - no position for %1", _objId]] call FLO_fnc_log;
                false
            };

            // Store in task node for later use
            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["stagingPosition", _stagingPos];
            _primData set ["targetObjective", _objId];
            _taskNode set ["primitiveData", _primData];

            ["GTN", 3, format["Staging point created at %1 for objective %2", _stagingPos, _objId]] call FLO_fnc_log;

            _ctx set ["status", "SUCCESS"];
            true
        }]];
        
        // prim_assign_groups_to_staging
        _self call ["_registerHandler", ["prim_assign_groups_to_staging", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _count = _params param [1, 4];
            private _cmdr = _ctx get "commander";
            
            // Get available groups
            private _available = _cmdr call ["_getAvailableGroups", [_count]];

            if (count _available < 1) exitWith {
                _ctx set ["status", "FAILED"];
                false
            };

            // Get staging position from previous task
            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            private _stagingPos = _primData getOrDefault ["stagingPosition", [0,0,0]];

            // Order groups to staging
            {
                _cmdr call ["_orderGroupMove", [_x, _stagingPos, "AWARE"]];
            } forEach _available;

            _primData set ["groupsAssigned", count _available];
            _primData set ["groupsArrived", 0];
            _primData set ["assignedGroups", _available];
            _taskNode set ["primitiveData", _primData];

            true
        }]];

        // prim_wait_for_staging
        _self call ["_registerHandler", ["prim_wait_for_staging", {
            params ["_ctx"];
            private _cmdr = _ctx get "commander";
            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];

            // Get staging info from previous tasks
            private _stagingPos = _primData getOrDefault ["stagingPosition", [0,0,0]];
            private _groups = _primData getOrDefault ["assignedGroups", []];

            if (count _groups == 0 || _stagingPos isEqualTo [0,0,0]) exitWith {
                // No groups or position - auto-complete
                _ctx set ["status", "SUCCESS"];
                true
            };

            // Check if groups have arrived
            private _arrived = _cmdr call ["_checkGroupsArrived", [_groups, _stagingPos, 150]];

            if (_arrived) then {
                _primData set ["groupsArrived", count _groups];
                _taskNode set ["primitiveData", _primData];
                _ctx set ["status", "SUCCESS"];
                ["GTN", 3, format["Groups arrived at staging position"]] call FLO_fnc_log;
            } else {
                // Still waiting - check timeout
                private _startTime = _primData getOrDefault ["waitStartTime", diag_tickTime];
                if (isNil {_primData get "waitStartTime"}) then {
                    _primData set ["waitStartTime", diag_tickTime];
                    _taskNode set ["primitiveData", _primData];
                };

                // Timeout after 5 minutes
                if (diag_tickTime - _startTime > 300) then {
                    ["GTN", 2, "Staging wait timeout - proceeding anyway"] call FLO_fnc_log;
                    _ctx set ["status", "SUCCESS"];
                } else {
                    _ctx set ["status", "RUNNING"];
                };
            };

            true
        }]];

        // prim_attack_objective
        _self call ["_registerHandler", ["prim_attack_objective", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _cmdr = _ctx get "commander";

            // Get objective position
            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith {
                ["GTN", 2, format["Attack failed - no position for objective: %1", _objId]] call FLO_fnc_log;
                false
            };

            // Get attack groups (from staging or available) 
            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            private _groups = _primData getOrDefault ["assignedGroups", []];

            if (count _groups < 1) then {
                // Pass objective position so groups are sorted by proximity
                _groups = _cmdr call ["_getAvailableGroups", [4, _objPos]];
            };

            ["GTN", 3, format["Attacking %1 at %2 with %3 groups", _objId, _objPos, count _groups]] call FLO_fnc_log;

            // Order attack
            {
                _cmdr call ["_orderGroupAttack", [_x, _objPos]];
            } forEach _groups;

            _primData set ["objectiveId", _objId];
            _primData set ["attackGroups", _groups];
            _taskNode set ["primitiveData", _primData];

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

            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["missionFired", _result];
            _taskNode set ["primitiveData", _primData];

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

            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["missionComplete", _result];
            _taskNode set ["primitiveData", _primData];

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

            // Get available groups
            private _available = _cmdr call ["_getAvailableGroups", [_count]];

            if (count _available < 1) exitWith { false };

            // Order to defend
            {
                _cmdr call ["_orderGroupDefend", [_x, _objPos]];
            } forEach _available;

            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["groupsArrived", count _available];
            _taskNode set ["primitiveData", _primData];

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

            // Get available groups
            private _available = _cmdr call ["_getAvailableGroups", [2]];

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

            private _available = _cmdr call ["_getAvailableGroups", [2]];
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

            private _available = _cmdr call ["_getAvailableGroups", [4]];
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
            if (isNil "_objPos") exitWith { false };

            // Call for defensive artillery
            private _result = _cmdr call ["_requestArtillery", [_objPos, "DEFENSIVE", 6]];

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

            private _available = _cmdr call ["_getAvailableGroups", [2]];
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
            private _infantry = _available select {
                private _gData = (FLO_virtualGroups get "_groups") getOrDefault [_x, createHashMap];
                (_gData getOrDefault ["type", ""]) in ["infantry", "recon"]
            };
            if (count _infantry < 1) exitWith { false };

            private _reconGroup = _infantry select 0;
            private _reconPos = _objPos getPos [300, 45 + (floor(_objId call BIS_fnc_hashCode) mod 4) * 90];

            _cmdr call ["_orderGroupMove", [_reconGroup, _reconPos, "AWARE"]];

            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["patrolDispatched", true];
            _primData set ["reconGroup", _reconGroup];
            _primData set ["objectiveId", _objId];
            _taskNode set ["primitiveData", _primData];

            // Use capability analyzer to get REAL intel about the objective
            [_gtnCmdr, _objId] spawn {
                params ["_gtnCmdr", "_objId"];
                // Wait for patrol to reach observation position
                sleep 120;
                if (isNil "_gtnCmdr") exitWith {};
                private _ws = _gtnCmdr getOrDefault ["_worldState", nil];
                if (isNil "_ws") exitWith {};

                // Use the capability analyzer to get actual objective data
                private _analyzer = FLO_GTN_CapabilityAnalyzer;
                if (isNil "_analyzer") exitWith {};

                private _objAnalysis = _analyzer call ["_analyzeObjective", [_objId]];
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
            true
        }]];

        _self call ["_registerHandler", ["prim_request_air_recon", {
            params ["_ctx"];
            private _params = _ctx get "params";
            private _objId = _params param [0, ""];
            private _cmdr = _ctx get "commander";
            private _gtnCmdr = _self get "_gtnCommander";

            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") exitWith {
                ["GTN", 2, format["Air recon failed - no position for %1", _objId]] call FLO_fnc_log;
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
            private _grp = group _aircraft;

            ["GTN", 3, format["Air recon dispatched: %1 flying to %2", typeOf _aircraft, _objId]] call FLO_fnc_log;

            // Set aircraft to fly over objective at high altitude
            _aircraft flyInHeight 400;

            // Clear waypoints in REVERSE order to avoid "Cycle as first waypoint has no sense" error
            for "_i" from (count waypoints _grp - 1) to 0 step -1 do {
                deleteWaypoint [_grp, _i];
            };

            _grp setBehaviour "AWARE";
            _grp setCombatMode "GREEN";  // Don't engage
            _grp setSpeedMode "NORMAL";

            // Flyover waypoint
            private _wp1 = _grp addWaypoint [_objPos, 100];
            _wp1 setWaypointType "MOVE";
            _wp1 setWaypointBehaviour "AWARE";
            _wp1 setWaypointCombatMode "GREEN";

            _grp setCurrentWaypoint [_grp, 1];

            // Spawn handler for when aircraft arrives and gathers intel
            [_gtnCmdr, _objId, _objPos, _groupId, _mgr, _aircraft] spawn {
                params ["_gtnCmdr", "_objId", "_objPos", "_groupId", "_mgr", "_aircraft"];

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
                private _ws = _gtnCmdr getOrDefault ["_worldState", nil];
                if (isNil "_ws") exitWith { _mgr call ["_releaseAirAsset", [_groupId]]; };

                private _analyzer = FLO_GTN_CapabilityAnalyzer;
                if (isNil "_analyzer") exitWith { _mgr call ["_releaseAirAsset", [_groupId]]; };

                private _objAnalysis = _analyzer call ["_analyzeObjective", [_objId]];
                if (!isNil "_objAnalysis") then {
                    private _garrisonCount = count (_objAnalysis get "garrison");
                    private _totalPower = _objAnalysis get "totalDefensePower";
                    private _posture = switch true do {
                        case (_totalPower > 500): { "HEAVY" };
                        case (_totalPower > 200): { "MEDIUM" };
                        case (_totalPower > 0): { "LIGHT" };
                        default { "NONE" };
                    };

                    private _intel = createHashMapFromArray [
                        ["intelQuality", 0.8],  // Slightly better than ground recon
                        ["confirmedStrength", _garrisonCount],
                        ["totalCombatPower", _totalPower],
                        ["hasArmor", _objAnalysis get "hasArmor"],
                        ["hasAA", _objAnalysis get "hasAA"],
                        ["hasStatic", _objAnalysis get "hasStatic"],
                        ["defensePosture", _posture],
                        ["reconType", "AIR"]
                    ];
                    _ws call ["_updateObjectiveIntel", [_objId, _intel]];

                    ["GTN", 3, format["Air recon intel for %1: %2 groups, power %3",
                        _objId, _garrisonCount, _totalPower]] call FLO_fnc_log;
                };

                // Loiter briefly then RTB
                sleep 30;
                _mgr call ["_releaseAirAsset", [_groupId]];
                ["GTN", 3, format["Air recon complete - aircraft RTB"]] call FLO_fnc_log;
            };

            private _taskNode = _ctx get "taskNode";
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["reconComplete", true];
            _primData set ["objectiveId", _objId];
            _primData set ["aircraftGroupId", _groupId];
            _taskNode set ["primitiveData", _primData];

            _ctx set ["status", "SUCCESS"];
            true
        }]];

        _self call ["_registerHandler", ["prim_use_existing_intel", {
            params ["_ctx"];
            _ctx set ["status", "SUCCESS"];
            true
        }]];
    }]
]];

// Initialize handlers
_executor call ["_initialize", []];

["GTN", 3, "GTN Executor initialized"] call FLO_fnc_log;

_executor
