/*
 * Function: FLO_fnc_gtnCommander
 * Author: Frontline Operations Development Group
 * 
 * Description:
 * Goal Task Network Commander - Main integration point for GTN-based AI Commander.
 * Creates and manages all GTN subsystems (World State, Goal Library, Planner, Executor, Monitor).
 * Provides the main update loop that drives goal-driven behavior.
 *
 * Arguments:
 * 0: Commander Reference <HASHMAP> - The existing OPFOR commander object
 *
 * Return Value:
 * GTN Commander HashMap Object <HASHMAP>
 *
 * Example:
 * private _gtnCmdr = [_opforCommander] call FLO_fnc_gtnCommander;
 * _gtnCmdr call ["_start", []];
 */

params [["_commander", nil]];

if (isNil "_commander") exitWith {
    ["GTN", 1, "GTN Commander requires commander reference"] call FLO_fnc_log;
    nil
};

["GTN", 2, "Initializing GTN Commander System"] call FLO_fnc_log;

// Create all subsystems
private _worldState = call FLO_fnc_gtnWorldState;
private _goalLibrary = call FLO_fnc_gtnGoalLibrary;
private _planner = [_goalLibrary, _worldState] call FLO_fnc_gtnPlanner;
private _executor = [_commander] call FLO_fnc_gtnExecutor;
private _monitor = [_planner, _worldState] call FLO_fnc_gtnMonitor;
private _capabilityAnalyzer = call FLO_fnc_gtnCapabilityAnalyzer;

// Link world state to commander
_worldState call ["_setCommander", [_commander]];

private _gtnCommander = createHashMapObject [[
    // Subsystem references
    ["_commander", _commander],
    ["_worldState", _worldState],
    ["_goalLibrary", _goalLibrary],
    ["_planner", _planner],
    ["_executor", _executor],
    ["_monitor", _monitor],
    ["_capabilityAnalyzer", _capabilityAnalyzer],
    
    // State (using 0/1 for booleans to avoid parsing issues)
    ["_isRunning", 0],
    ["_updateInterval", (call FLO_fnc_gtnConfig) get "gtnUpdateInterval"],
    ["_lastUpdate", 0],
    
    // Current operation
    ["_currentGoal", "control_ao"],
    ["_currentPlan", []],
    
    // Configuration
    ["_config", createHashMapFromArray [
        ["aggressiveness", 0.5],      // 0-1, affects offensive vs defensive posture
        ["riskTolerance", 0.5],       // 0-1, affects willingness to attack with lower ratios
        ["replanInterval", 60],       // Minimum seconds between replans
        ["casualtyThreshold", 0.2],   // Force loss ratio to trigger replan
        ["debugMode", false]          // Enable verbose logging
    ]],
    
    // Statistics
    ["_stats", createHashMapFromArray [
        ["cyclesRun", 0],
        ["plansCreated", 0],
        ["tasksExecuted", 0],
        ["replans", 0],
        ["startTime", 0]
    ]],
    
    // === MAIN CONTROL ===
    
    // Start the GTN commander
    ["_start", {
        if ((_self get "_isRunning") isEqualTo 1) exitWith {
            ["GTN", 3, "GTN Commander already running"] call FLO_fnc_log;
        };

        _self set ["_isRunning", 1];

        private _stats = _self get "_stats";
        _stats set ["startTime", diag_tickTime];

        // Set initial goal
        private _monitor = _self get "_monitor";
        _monitor call ["_setCurrentGoal", [_self get "_currentGoal", []]];

        // Create initial plan
        _self call ["_createPlan", []];

        ["GTN", 2, "GTN Commander started"] call FLO_fnc_log;
    }],

    // Stop the GTN commander
    ["_stop", {
        _self set ["_isRunning", 0];
        ["GTN", 2, "GTN Commander stopped"] call FLO_fnc_log;
    }],

    // Main update cycle - call this from commander's update loop
    ["_update", {
        if ((_self get "_isRunning") isEqualTo 0) exitWith {};
        
        private _now = diag_tickTime;
        _self set ["_lastUpdate", _now];
        
        private _stats = _self get "_stats";
        _stats set ["cyclesRun", (_stats get "cyclesRun") + 1];
        
        private _config = _self get "_config";
        ["GTN", 3, format["GTN Cycle %1 starting", _stats get "cyclesRun"]] call FLO_fnc_log;

        // Update world state
        private _ws = _self get "_worldState";
        _ws call ["_update", []];

        // Log world state summary
        private _forces = _ws call ["_getForces", []];
        private _situation = _ws call ["_getTacticalSituation", []];
        private _enemyObjs = _ws call ["_getEnemyObjectives", []];
        ["GTN", 3, format["World State: Available=%1, Momentum=%2, EnemyObjs=%3",
            _forces get "availableGroups",
            _situation get "momentum",
            count (keys _enemyObjs)
        ]] call FLO_fnc_log;

        // Check for replan triggers
        private _monitor = _self get "_monitor";
        if (_monitor call ["_checkReplanTriggers", []]) then {
            _self call ["_handleReplan", []];
        };

        // Log current plan status
        private _planner = _self get "_planner";
        private _planStatus = _planner call ["_getPlanStatus", []];
        private _currentPlan = _planner call ["_getCurrentPlan", []];
        ["GTN", 3, format["Plan Status: %1, Tasks: %2", _planStatus, count _currentPlan]] call FLO_fnc_log;

        // Execute current plan
        _self call ["_executePlan", []];

        // Manage force preservation (Retreats & Replenishment)
        _self call ["_manageForcePreservation", []];
    }],
    
    // === PLANNING ===
    
    // Create a new plan for current goal
    ["_createPlan", {
        private _planner = _self get "_planner";
        private _goal = _self get "_currentGoal";

        ["GTN", 3, format["Creating plan for goal: %1", _goal]] call FLO_fnc_log;

        private _planResult = _planner call ["_plan", [_goal, []]];

        // Ensure we have a valid plan array, not nil
        private _plan = if (isNil "_planResult") then { [] } else { _planResult };

        if (count _plan > 0) then {
            _self set ["_currentPlan", _plan];

            private _stats = _self get "_stats";
            _stats set ["plansCreated", (_stats get "plansCreated") + 1];

            ["GTN", 3, format["Plan created with %1 tasks", count _plan]] call FLO_fnc_log;
        } else {
            _self set ["_currentPlan", []];
            ["GTN", 2, "Failed to create plan - no tasks generated"] call FLO_fnc_log;
        };

        _plan
    }],
    
    // Handle replan trigger
    ["_handleReplan", {
        private _monitor = _self get "_monitor";
        
        ["GTN", 3, "Handling replan trigger"] call FLO_fnc_log;
        
        private _stats = _self get "_stats";
        _stats set ["replans", (_stats get "replans") + 1];
        
        // Trigger replan through monitor (handles throttling)
        _monitor call ["_triggerReplan", []];
        
        // Update our plan reference
        private _planner = _self get "_planner";
        _self set ["_currentPlan", _planner call ["_getCurrentPlan", []]];
    }],

    // === PLAN EXECUTION ===

    // Execute current plan step
    ["_executePlan", {
        private _planner = _self get "_planner";
        private _executor = _self get "_executor";

        private _status = _planner call ["_getPlanStatus", []];

        switch (_status) do {
            case "PENDING";
            case "RUNNING": {
                // Unified execution loop for both PENDING and RUNNING states
                private _maxTasksPerCycle = 10;
                private _tasksThisCycle = 0;
                private _continueLoop = true;

                while {_continueLoop && {_tasksThisCycle < _maxTasksPerCycle}} do {
                    private _currentStatus = _planner call ["_getPlanStatus", []];

                    if (_currentStatus == "PENDING") then {
                        // First task - just execute and mark as running
                        private _currentTask = _planner call ["_getCurrentTask", []];
                        if (!isNil "_currentTask") then {
                            private _taskId = _currentTask get "taskId";
                            ["GTN", 3, format["Starting execution: %1", _taskId]] call FLO_fnc_log;
                            private _result = _executor call ["_executePrimitive", [_currentTask]];

                            if (!_result) then {
                                // Primitive failed - abort plan
                                ["GTN", 2, format["Primitive failed: %1 - aborting plan", _taskId]] call FLO_fnc_log;
                                _planner set ["_planStatus", "FAILED"];
                                _continueLoop = false;
                            } else {
                                _planner call ["_executeNext", []];
                                private _stats = _self get "_stats";
                                _stats set ["tasksExecuted", (_stats get "tasksExecuted") + 1];
                                _tasksThisCycle = _tasksThisCycle + 1;
                                
                                // Check if task completed synchronously - if so, advance and reset to PENDING
                                // This allows the loop to treat the next task as a fresh start in the same cycle
                                if (_planner call ["_checkCurrentTask", [_executor]]) then {
                                    ["GTN", 4, format["Task %1 completed synchronously - chaining to next task", _taskId]] call FLO_fnc_log;
                                    _planner set ["_planStatus", "PENDING"];
                                };
                            };
                        } else {
                            ["GTN", 2, "No tasks in plan"] call FLO_fnc_log;
                            _planner set ["_planStatus", "SUCCESS"];
                            _continueLoop = false;
                        };
                    } else {
                        if (_currentStatus == "RUNNING") then {
                            // Check if current task is complete (pass executor for status check)
                            if (_planner call ["_checkCurrentTask", [_executor]]) then {
                                // Task complete - execute next
                                private _currentTask = _planner call ["_getCurrentTask", []];
                                if (!isNil "_currentTask") then {
                                    ["GTN", 3, format["Executing: %1", _currentTask get "taskId"]] call FLO_fnc_log;
                                    private _result = _executor call ["_executePrimitive", [_currentTask]];

                                    if (!_result) then {
                                        // Primitive failed - abort plan
                                        ["GTN", 2, format["Primitive failed: %1 - aborting plan", _currentTask get "taskId"]] call FLO_fnc_log;
                                        _planner set ["_planStatus", "FAILED"];
                                        _continueLoop = false;
                                    } else {
                                        _planner call ["_executeNext", []];
                                        private _stats = _self get "_stats";
                                        _stats set ["tasksExecuted", (_stats get "tasksExecuted") + 1];
                                        _tasksThisCycle = _tasksThisCycle + 1;
                                    };
                                } else {
                                    // No more tasks - plan complete
                                    _continueLoop = false;
                                };
                            } else {
                                // Current task not complete yet
                                _continueLoop = false;
                            };
                        } else {
                            // Plan ended (SUCCESS or FAILED)
                            _continueLoop = false;
                        };
                    };
                };
            };
            case "SUCCESS": {
                // Plan complete - create new plan
                ["GTN", 3, "Plan completed successfully, creating new plan"] call FLO_fnc_log;
                _self call ["_createPlan", []];
            };
            case "FAILED": {
                // Plan failed - will be handled by replan trigger
                ["GTN", 2, "Plan failed, awaiting replan"] call FLO_fnc_log;
            };
        };
    }],

    // === GOAL MANAGEMENT ===

    // Set a new strategic goal
    ["_setGoal", {
        params ["_goalId", ["_params", []]];

        _self set ["_currentGoal", _goalId];

        private _monitor = _self get "_monitor";
        _monitor call ["_setCurrentGoal", [_goalId, _params]];

        // Create new plan for new goal
        _self call ["_createPlan", []];

        ["GTN", 3, format["Goal set to: %1", _goalId]] call FLO_fnc_log;
    }],

    // === CONFIGURATION ===

    ["_configure", {
        params ["_key", "_value"];
        private _config = _self get "_config";
        _config set [_key, _value];

        // Apply relevant config to subsystems
        if (_key == "replanInterval") then {
            private _monitor = _self get "_monitor";
            _monitor call ["_setThresholds", [nil, _value, nil]];
        };

        if (_key == "casualtyThreshold") then {
            private _monitor = _self get "_monitor";
            _monitor call ["_setThresholds", [_value, nil, nil]];
        };
    }],

    // === QUERY METHODS ===

    ["_getWorldState", {
        _self get "_worldState"
    }],

    ["_getPlanner", {
        _self get "_planner"
    }],

    ["_getStats", {
        _self get "_stats"
    }],

    ["_isRunning", {
        _self get "_isRunning"
    }],

    // === TACTICAL METHODS (used by executor handlers) ===

    // Select highest priority enemy objective
    ["_selectPriorityObjective", {
        private _ws = _self get "_worldState";
        private _enemyObjs = _ws call ["_getEnemyObjectives", []];

        if (count (keys _enemyObjs) == 0) exitWith { "" };

        // Find highest priority
        private _bestObj = "";
        private _bestPriority = -1;

        {
            private _obj = _enemyObjs get _x;
            private _priority = _obj getOrDefault ["priority", 50];
            if (_priority > _bestPriority) then {
                _bestPriority = _priority;
                _bestObj = _x;
            };
        } forEach (keys _enemyObjs);

        _bestObj
    }],

    // Groups currently tasked by GTN (prevent AI Commander from using them)
    ["_gtnTaskedGroups", []],

    // Get available groups for tasking from virtualization system
    ["_getAvailableGroups", {
        params [["_count", 4], ["_targetPos", []]];

        private _groups = FLO_virtualGroups get "_groups";
        private _gtnTasked = _self get "_gtnTaskedGroups";
        private _available = [];

        // Find groups that are:
        // 1. Military (not civilian)
        // 2. Not already tasked by GTN
        // 3. In garrison/idle state (currentOrder is empty or "PATROL")
        {
            private _groupId = _x;
            private _gData = _y;

            private _groupType = _gData get "groupType";
            private _currentOrder = _gData get "currentOrder";
            private _side = _gData get "side";

            // Skip non-military or wrong side
            if (_groupType in ["civilian", "ambient"]) then { continue };
            if (_side != east) then { continue };

            // Skip air and artillery assets
            if (_groupType in ["helicopter", "jet", "air", "artillery"]) then { continue };

            // Skip already tasked groups
            if (_groupId in _gtnTasked) then { continue };

            // Skip groups with active orders (unless patrolling or defending)
            if (_currentOrder != "" && {!(_currentOrder in ["PATROL", "GARRISON", "DEFEND", ""])}) then { continue };

            _available pushBack [_groupId, _gData];
        } forEach _groups;

        // Sort by distance to target if position provided
        if (count _targetPos >= 2) then {
            _available = [_available, [], {
                private _gData = _x select 1;
                private _groupPos = _gData get "position";
                _groupPos distance2D _targetPos
            }, "ASCEND"] call BIS_fnc_sortBy;
        };

        // Take requested count and extract just group IDs
        private _result = [];
        private _resultInfo = [];
        {
            if (count _result >= _count) exitWith {};
            _x params ["_groupId", "_gData"];
            _result pushBack _groupId;

            // Collect info for logging
            private _groupType = _gData get "groupType";
            private _vehicleType = _gData getOrDefault ["vehicleType", ""];
            private _unitCount = _gData get "unitCount";
            private _shortId = _groupId select [7, 6]; // Extract numeric part from "vgroup_123456"
            private _typeStr = if (_vehicleType != "") then { _vehicleType } else { _groupType };
            _resultInfo pushBack format["%1[%2](%3)", _shortId, _typeStr, _unitCount];
        } forEach _available;

        ["GTN", 3, format["Found %1 groups (requested %2) near %3: %4", count _result, _count, _targetPos, _resultInfo joinString ", "]] call FLO_fnc_log;

        // Log distances for debugging
        {
            private _gData = _groups get _x;
            private _groupPos = _gData get "position";
            private _dist = if (count _targetPos >= 2) then { _groupPos distance2D _targetPos } else { -1 };
            ["GTN", 4, format["  Group %1 at %2 (dist: %3m)", _x, _groupPos, round _dist]] call FLO_fnc_log;
        } forEach _result;

        _result
    }],

    // Mark groups as tasked by GTN
    ["_taskGroups", {
        params ["_groupIds"];
        private _tasked = _self get "_gtnTaskedGroups";
        { _tasked pushBackUnique _x; } forEach _groupIds;
        _self set ["_gtnTaskedGroups", _tasked];
    }],

    // Release groups from GTN tasking
    ["_releaseGroups", {
        params ["_groupIds"];
        private _tasked = _self get "_gtnTaskedGroups";
        { _tasked = _tasked - [_x]; } forEach _groupIds;
        _self set ["_gtnTaskedGroups", _tasked];
    }],

    // Order group to move using virtualization waypoints
    ["_orderGroupMove", {
        params ["_groupId", "_pos", ["_mode", "AWARE"]];

        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups getOrDefault [_groupId, nil];
        if (isNil "_gData") exitWith {
            ["GTN", 2, format["Cannot order move - group %1 not found", _groupId]] call FLO_fnc_log;
            false
        };

        // Create waypoints for movement
        private _combatMode = switch (_mode) do {
            case "COMBAT": { "RED" };
            case "STEALTH": { "GREEN" };
            default { "YELLOW" };
        };

        private _waypoints = [
            [_pos, "MOVE", _mode, "NORMAL", "WEDGE", _combatMode, 30]
        ];

        [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
        _gData set ["currentOrder", "MOVE"];

        // Mark as tasked
        _self call ["_taskGroups", [[_groupId]]];

        ["GTN", 3, format["Ordered group %1 to move to %2 (%3)", _groupId, _pos, _mode]] call FLO_fnc_log;
        true
    }],

    // Order group to attack using virtualization waypoints
    ["_orderGroupAttack", {
        params ["_groupId", "_pos"];

        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups getOrDefault [_groupId, nil];
        if (isNil "_gData") exitWith {
            ["GTN", 2, format["Cannot order attack - group %1 not found", _groupId]] call FLO_fnc_log;
            false
        };

        // Create attack waypoints
        private _waypoints = [
            [_pos, "MOVE", "COMBAT", "NORMAL", "WEDGE", "RED", 75],
            [_pos, "MOVE", "COMBAT", "NORMAL", "LINE", "RED", 50]
        ];

        [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
        _gData set ["currentOrder", "ATTACK"];

        // Mark as tasked
        _self call ["_taskGroups", [[_groupId]]];

        ["GTN", 3, format["Ordered group %1 to attack %2", _groupId, _pos]] call FLO_fnc_log;
        true
    }],

    // Order group to defend using virtualization waypoints
    ["_orderGroupDefend", {
        params ["_groupId", "_pos"];

        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups getOrDefault [_groupId, nil];
        if (isNil "_gData") exitWith {
            ["GTN", 2, format["Cannot order defend - group %1 not found", _groupId]] call FLO_fnc_log;
            false
        };

        // Create defense waypoints
        private _waypoints = [
            [_pos, "MOVE", "COMBAT", "NORMAL", "WEDGE", "RED", 40],
            [_pos, "GUARD", "COMBAT", "NORMAL", "LINE", "RED", 60]
        ];

        [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
        _gData set ["currentOrder", "DEFEND"];

        // Mark as tasked
        _self call ["_taskGroups", [[_groupId]]];

        ["GTN", 3, format["Ordered group %1 to defend %2", _groupId, _pos]] call FLO_fnc_log;
        true
    }],

    // Request artillery fire using the artillery asset manager
    ["_requestArtillery", {
        params ["_pos", "_missionType", "_rounds"];

        private _manager = call FLO_fnc_gtnArtilleryManager;
        private _success = _manager call ["_requestFireMission", [_pos, _rounds]];

        if (_success) then {
            ["GTN", 3, format["Artillery %1 mission fired at %2 (%3 rounds)", _missionType, _pos, _rounds]] call FLO_fnc_log;
        } else {
            ["GTN", 2, format["Artillery request failed - no available assets"]] call FLO_fnc_log;
        };

        _success
    }],

    // Request CAS using the GTN air support system
    ["_requestCAS", {
        params ["_pos", ["_missionType", "CAS"]];

        // Use the Air Tasking Order system
        private _ato = call FLO_fnc_gtnAirTaskOrder;
        private _altitude = if (_missionType in ["BOMB", "LASER"]) then { 300 } else { 150 };

        _ato call ["_addTask", [_pos, _missionType, "", _altitude]];

        ["GTN", 3, format["CAS mission queued: %1 at %2", _missionType, _pos]] call FLO_fnc_log;

        // Process immediately
        _ato call ["_processTasks", []];

        true
    }],

    // Check if groups have arrived at a position (within threshold)
    ["_checkGroupsArrived", {
        params ["_groupIds", "_pos", ["_threshold", 100]];

        private _groups = FLO_virtualGroups get "_groups";
        private _arrivedCount = 0;
        private _validCount = 0;

        {
            private _gData = _groups get _x;
            if (isNil "_gData") then { continue };
            _validCount = _validCount + 1;

            private _groupPos = _gData get "position";
            if (_groupPos distance2D _pos <= _threshold) then {
                _arrivedCount = _arrivedCount + 1;
            };
        } forEach _groupIds;

        // All surviving groups must arrive (don't wait for dead/deleted groups)
        if (_validCount == 0) exitWith { true };
        _arrivedCount >= _validCount
    }],

    // Identify objective with weakest defense (for opportunistic attacks)
    ["_identifyWeakSector", {
        private _ws = _self get "_worldState";
        private _enemyObjs = _ws call ["_getEnemyObjectives", []];

        if (count (keys _enemyObjs) == 0) exitWith { "" };

        // Find objective with lowest defense strength
        private _weakest = "";
        private _lowestStrength = 1000;

        {
            private _obj = _enemyObjs get _x;
            private _strength = _obj getOrDefault ["defenseStrength", 50];

            // Prefer lower strength
            if (_strength < _lowestStrength) then {
                _lowestStrength = _strength;
                _weakest = _x;
            };
        } forEach (keys _enemyObjs);

        _weakest
    }],

    // Force Preservation Management
    // Handles retreating damaged groups, ordering dismounted pilots RTB, and replenishing forces.
    ["_manageForcePreservation", {
        private _groups = FLO_virtualGroups get "_groups";
        private _replenishInterval = 300; // 5 minutes for replenishment tick

        {
            private _gId = _x;
            private _gData = _groups get _gId;   
            private _currentOrder = _gData get "currentOrder";
            private _state = _gData getOrDefault ["preservationState", "ACTIVE"]; // ACTIVE, RETREATING, REPLENISHING
            private _groupType = _gData get "groupType";

            // === CHECK FOR RETREAT CRITERIA ===
            if (_state == "ACTIVE") then {
                // Dismounted Pilot
                // If group type was air but unit count > 0 and vehicle count == 0 (or all vehicles dead), treat as dismounted
                private _isPilot = false;
                if (_groupType in ["helicopter", "jet", "air"]) then {
                     // Check if they are on foot
                    private _realGroup = _gData get "realGroup";
                    if (!isNull _realGroup) then {
                        private _hasAirVehicle = false;
                        {
                            if (vehicle _x isKindOf "Air" && alive vehicle _x) then { _hasAirVehicle = true; };
                        } forEach units _realGroup;
                         
                        if (!_hasAirVehicle && {count units _realGroup > 0}) then {
                            _isPilot = true;
                        };
                    };
                };

                // Significant Damage (< 50% strength)
                private _unitCount = _gData get "unitCount";
                private _template = _gData getOrDefault ["template", []];
                private _originalCount = count _template;
                
                // If template missing, assume current is original (fallback)
                if (_originalCount == 0) then { _originalCount = _unitCount max 1; };

                private _isDamaged = (_unitCount / _originalCount) < 0.5;

                if (_isPilot || _isDamaged) then {
                    ["GTN", 3, format["Force Preservation: Group %1 (%2) retreating. Pilot: %3, Damage: %4/%5", 
                        _gId, _groupType, _isPilot, _unitCount, _originalCount]] call FLO_fnc_log;
                    
                    // Release from Air Manager so it doesn't crash if this group dies/deletes
                    if (!isNil "FLO_GTNAirAssetManager") then {
                         FLO_GTNAirAssetManager call ["_releaseAirAsset", [_gId]];
                    };
                    
                    _gData set ["preservationState", "RETREATING"];
                    _gData set ["onMission", true]; // Prevent tasking
                    
                    // Find nearest friendly objective
                    private _ws = _self get "_worldState";
                    private _friendlyObjs = _ws call ["_getFriendlyObjectives", []];
                    private _gPos = _gData get "position";
                    private _retreatObj = "";
                    private _bestDist = 999999;
                    
                    {
                        private _objPos = [_x] call FLO_fnc_getObjectivePosition;
                        private _dist = _gPos distance2D _objPos;
                        
                        // Prioritize objectives > 5km away
                        // If we find one > 5km, track the *nearest* of those deep objectives
                        if (_dist > 5000) then {
                            if (_dist < _bestDist) then {
                                _bestDist = _dist;
                                _retreatObj = _x;
                            };
                        };
                    } forEach (keys _friendlyObjs);

                    // Fallback: If no deep objective found, just go to the furthest one available (or nearest if map is small)
                    // Actually, let's just go to the nearest friendly if no >5km option exists, to ensure safety
                    if (_retreatObj == "") then {
                         _bestDist = 999999;
                         {
                            private _objPos = [_x] call FLO_fnc_getObjectivePosition;
                            private _dist = _gPos distance2D _objPos;
                            if (_dist < _bestDist) then {
                                _bestDist = _dist;
                                _retreatObj = _x;
                            };
                        } forEach (keys _friendlyObjs);
                    };

                    if (_retreatObj != "") then {
                        private _retreatPos = [_retreatObj] call FLO_fnc_getObjectivePosition;
                        _gData set ["retreatPos", _retreatPos];
                         
                        // Break Contact Order: Careless (ignore threats), Hold Fire (don't stop to shoot)
                        private _wps = [[_retreatPos, "MOVE", "CARELESS", "FULL", "FILE", "BLUE", 0]];
                        [_gId, _wps, true] call FLO_fnc_updateVirtualGroupWaypoints;
                    };
                };
            };
            
            // === HANDLE RETREATING MOVEMENT ===
            if (_state == "RETREATING") then {
                private _retreatPos = _gData getOrDefault ["retreatPos", []];
                if (count _retreatPos == 0) exitWith { _gData set ["preservationState", "ACTIVE"]; };
                
                private _gPos = _gData get "position";
                if (_gPos distance2D _retreatPos < 150) then {
                    ["GTN", 3, format["Group %1 arrived at safe haven. Beginning replenishment.", _gId]] call FLO_fnc_log;
                    _gData set ["preservationState", "REPLENISHING"];
                    _gData set ["lastReplenishTime", diag_tickTime];
                };
            };

            // === HANDLE REPLENISHMENT ===
            if (_state == "REPLENISHING") then {
                private _lastRep = _gData getOrDefault ["lastReplenishTime", 0];
                
                if (diag_tickTime - _lastRep >= _replenishInterval) then {
                    // Check resources before replenishing
                    // Cost: 5 resources per tick
                    private _cost = 5;
                    private _canAfford = true;
                    
                    if !(FLO_OPFOR_Resources call ["canAfford", [_cost, "reinforcement"]]) then {
                        _canAfford = false;
                        ["GTN", 3, format["Group %1 replenishment paused - insufficient resources", _gId]] call FLO_fnc_log;
                    };
                    
                    if (_canAfford) then {
                        // Dedect cost
                        FLO_OPFOR_Resources call ["spendResources", [_cost, "reinforcement"]];
                    
                        // Trickle replenishment
                        private _unitCount = _gData get "unitCount";
                        private _template = _gData getOrDefault ["template", []];
                        private _originalCount = count _template;
                        
                        if (_originalCount == 0) then { _originalCount = _unitCount max 1; }; // Fallback
                        
                        // Add 10% or 1 man, whichever is greater
                        private _increase = ceil(_originalCount * 0.1) max 1;
                        private _newCount = (_unitCount + _increase) min _originalCount;
                        
                        _gData set ["unitCount", _newCount];
                        _gData set ["strength", _newCount / _originalCount]; // Update strength multiplier
                        _gData set ["lastReplenishTime", diag_tickTime];
                        
                        ["GTN", 3, format["Group %1 replenish tick: %2 -> %3 (Target: %4)", _gId, _unitCount, _newCount, _originalCount]] call FLO_fnc_log;
                        
                        // Apply to real group if active
                        if (_gData get "isActive") then {
                            // Note: Spawning units into live group is complex (loadouts etc). 
                            // For now, we simulate success by healing existing units.
                            // Full respawn happens when revirtualized and activated again.
                            private _realGroup = _gData get "realGroup";
                            { _x setDamage 0; } forEach units _realGroup; 
                        };

                        if (_newCount >= _originalCount) then {
                            // Check if we need to respawn vehicle (Air groups without vehicles)
                            private _needsRespawn = false;
                            if (_groupType in ["helicopter", "jet", "air"]) then {
                                private _realGroup = _gData get "realGroup";
                                if (!isNull _realGroup) then {
                                    // Re-use logic: check if purely infantry
                                    private _hasAirVehicle = false;
                                    { if (vehicle _x isKindOf "Air") then { _hasAirVehicle = true; }; } forEach units _realGroup;
                                    if (!_hasAirVehicle) then { _needsRespawn = true; };
                                };
                            };

                            if (_needsRespawn) then {
                                ["GTN", 3, format["Group %1 fully replenished but needs vehicle. Deactivating to respawn.", _gId]] call FLO_fnc_log;
                                [_gId] call FLO_fnc_deactivateVirtualGroup;
                                _gData set ["preservationState", "ACTIVE"]; 
                                _gData set ["onMission", false];
                                _gData set ["currentOrder", ""];
                            } else {
                                ["GTN", 3, format["Group %1 fully replenished. Returning to duty.", _gId]] call FLO_fnc_log;
                                _gData set ["preservationState", "ACTIVE"];
                                _gData set ["onMission", false];
                                _gData set ["currentOrder", ""]; // Reset order to allow tasking
                                // Also reset their behavior/combat mode if active
                                if (_gData get "isActive") then {
                                    private _realGroup = _gData get "realGroup";
                                    _realGroup setBehaviour "AWARE";
                                    _realGroup setCombatMode "YELLOW";
                                };
                            };
                        };
                    };
                };
            };
            
        } forEach (keys _groups);
    }],

    // Get staging position for an objective (offset from target)
    ["_getStagingPosition", {
        params ["_objId"];

        private _targetPos = [_objId] call FLO_fnc_getObjectivePosition;
        if (isNil "_targetPos") exitWith { nil };

        // Find nearest friendly (OPFOR) objective to stage at
        private _ws = _self get "_worldState";
        private _friendlyObjs = _ws call ["_getFriendlyObjectives", []];

        if (count (keys _friendlyObjs) == 0) exitWith {
            // No friendly objectives - fall back to offset from target
            ["GTN", 2, "No friendly objectives for staging - using offset position"] call FLO_fnc_log;
            private _offset = 500 + random 300;
            private _dir = random 360;
            _targetPos getPos [_offset, _dir]
        };

        // Find closest friendly objective to the target
        private _bestObj = "";
        private _bestDist = 999999;

        {
            private _objData = _friendlyObjs get _x;
            private _objPos = [_x] call FLO_fnc_getObjectivePosition;
            if (isNil "_objPos") then { continue };

            private _dist = _objPos distance2D _targetPos;
            if (_dist < _bestDist) then {
                _bestDist = _dist;
                _bestObj = _x;
            };
        } forEach (keys _friendlyObjs);

        if (_bestObj == "") exitWith {
            ["GTN", 2, "Could not find valid friendly objective for staging"] call FLO_fnc_log;
            nil
        };

        private _stagingPos = [_bestObj] call FLO_fnc_getObjectivePosition;

        ["GTN", 3, format["Staging at friendly objective %1 (%2m from target)", _bestObj, round _bestDist]] call FLO_fnc_log;

        _stagingPos
    }],

    // === DEBUG ===

    ["_debugPrint", {
        private _stats = _self get "_stats";
        private _planner = _self get "_planner";
        private _ws = _self get "_worldState";
        private _monitor = _self get "_monitor";

        private _planDebug = _planner call ["_debugPrint", []];
        private _wsDebug = _ws call ["_debugPrint", []];
        private _monitorDebug = _monitor call ["_debugPrint", []];

        format[
            "=== GTN Commander ===\nRunning: %1\nCycles: %2, Plans: %3, Tasks: %4, Replans: %5\n\n%6\n\n%7\n\n%8",
            _self get "_isRunning",
            _stats get "cyclesRun",
            _stats get "plansCreated",
            _stats get "tasksExecuted",
            _stats get "replans",
            _wsDebug,
            _planDebug,
            _monitorDebug
        ]
    }],

    // Full status dump for debugging
    ["_dumpStatus", {
        private _debug = _self call ["_debugPrint", []];
        ["GTN", 2, _debug] call FLO_fnc_log;
        _debug
    }]
]];

// Link executor back to GTN commander (circular reference needed for handlers)
_executor call ["_setGTNCommander", [_gtnCommander]];

["GTN", 2, "GTN Commander System initialized"] call FLO_fnc_log;

_gtnCommander
