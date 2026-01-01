/*
 * Function: FLO_fnc_gtnPlanner
 * Author: Frontline Operations Development Group
 * 
 * Description:
 * Goal Task Network HTN Planner - Decomposes goals into executable plans.
 * Uses hierarchical task decomposition with method selection based on world state.
 * Supports partial planning and replanning when conditions change.
 *
 * Arguments:
 * 0: Goal Library <HASHMAP> - The goal library object
 * 1: World State <HASHMAP> - The world state object
 *
 * Return Value:
 * Planner HashMap Object <HASHMAP>
 *
 * Example:
 * private _planner = [_goalLib, _worldState] call FLO_fnc_gtnPlanner;
 * private _plan = _planner call ["_plan", ["control_ao", []]];
 */

params [["_goalLibrary", nil], ["_worldState", nil]];

if (isNil "_goalLibrary" || isNil "_worldState") exitWith {
    ["GTN", 1, "Planner requires goal library and world state"] call FLO_fnc_log;
    nil
};

["GTN", 3, "Initializing GTN Planner"] call FLO_fnc_log;

private _planner = createHashMapObject [[
    // References
    ["_goalLibrary", _goalLibrary],
    ["_worldState", _worldState],

    // Current plan (list of plan nodes)
    ["_currentPlan", []],

    // Plan execution state
    ["_planStatus", "PENDING"],
    ["_currentTaskIndex", 0],
    
    // Planning depth limit
    ["_maxDepth", 10],
    
    // Planning statistics
    ["_planningStats", createHashMapFromArray [
        ["plansGenerated", 0],
        ["replans", 0],
        ["tasksExecuted", 0],
        ["tasksFailed", 0]
    ]],
    
    // === PLAN NODE CREATION ===
    
    // Create a plan node for a task
    ["_createPlanNode", {
        params ["_taskId", "_params", ["_depth", 0]];
        
        createHashMapFromArray [
            ["taskId", _taskId],
            ["params", _params],
            ["depth", _depth],
            ["status", "PENDING"],
            ["startTime", -1],
            ["endTime", -1],
            ["result", nil],
            ["children", []],
            ["methodUsed", ""]
        ]
    }],
    
    // === CORE PLANNING ===
    
    // Main planning entry point - decompose a goal into a plan
    ["_plan", {
        params ["_goalId", ["_params", []]];
        
        private _goalLib = _self get "_goalLibrary";
        private _ws = _self get "_worldState";
        
        // Update world state before planning
        _ws call ["_update", []];
        
        ["GTN", 3, format["Planning for goal: %1", _goalId]] call FLO_fnc_log;
        
        // Create root node
        private _rootNode = _self call ["_createPlanNode", [_goalId, _params, 0]];
        
        // Decompose recursively
        ["GTN", 3, format["Decomposing goal: %1", _goalId]] call FLO_fnc_log;
        private _plan = _self call ["_decompose", [_rootNode]];

        if (isNil "_plan") exitWith {
            ["GTN", 2, format["Failed to decompose plan for goal: %1 - check preconditions and methods", _goalId]] call FLO_fnc_log;
            nil
        };

        ["GTN", 3, format["Decomposition complete for: %1", _goalId]] call FLO_fnc_log;

        // Flatten plan to executable sequence
        private _flatPlan = _self call ["_flattenPlan", [_plan]];
        
        _self set ["_currentPlan", _flatPlan];
        _self set ["_planStatus", "PENDING"];
        _self set ["_currentTaskIndex", 0];
        
        // Update stats
        private _stats = _self get "_planningStats";
        _stats set ["plansGenerated", (_stats get "plansGenerated") + 1];
        
        ["GTN", 3, format["Plan created with %1 tasks", count _flatPlan]] call FLO_fnc_log;
        
        _flatPlan
    }],
    
    // Recursive decomposition of a task
    ["_decompose", {
        params ["_node"];

        private _taskId = _node get "taskId";
        private _params = _node get "params";
        private _depth = _node get "depth";
        private _maxDepth = _self get "_maxDepth";

        ["GTN", 3, format["Decomposing task: %1 at depth %2", _taskId, _depth]] call FLO_fnc_log;

        // Depth check
        if (_depth > _maxDepth) exitWith {
            ["GTN", 3, format["Max planning depth exceeded for: %1", _taskId]] call FLO_fnc_log;
            nil
        };

        private _goalLib = _self get "_goalLibrary";
        private _ws = _self get "_worldState";

        // Check if this is a primitive
        if (_goalLib call ["_isPrimitive", [_taskId]]) exitWith {
            // Primitives are leaf nodes - return as-is
            ["GTN", 3, format["Found primitive: %1", _taskId]] call FLO_fnc_log;
            _node set ["isPrimitive", true];
            _node
        };

        // Get goal definition
        private _goal = _goalLib call ["_getGoal", [_taskId]];
        if (isNil "_goal") exitWith {
            ["GTN", 3, format["Unknown goal (not registered): %1", _taskId]] call FLO_fnc_log;
            nil
        };

        // Check preconditions
        private _preconditions = _goal get "preconditions";
        if (!([_ws, _params] call _preconditions)) exitWith {
            ["GTN", 3, format["Preconditions failed for: %1", _taskId]] call FLO_fnc_log;
            nil
        };
        
        // Find best method using scoring system
        private _methods = _goal get "methods";
        private _selectedMethod = nil;
        private _bestScore = -1;

        {
            private _method = _x;
            private _methodId = _method get "id";
            private _score = 0;

            // Check if method has scoring function, otherwise use conditions
            private _scoreFunc = _method getOrDefault ["score", nil];
            if (!isNil "_scoreFunc") then {
                _score = [_ws, _params, _self] call _scoreFunc;
            } else {
                private _conditions = _method get "conditions";
                _score = if ([_ws, _params] call _conditions) then { 1 } else { -1 };
            };

            if (_score > _bestScore) then {
                _bestScore = _score;
                _selectedMethod = _method;
            };
        } forEach _methods;

        if (isNil "_selectedMethod" || _bestScore < 0) exitWith {
            ["GTN", 2, format["No viable method for: %1 (best score: %2)", _taskId, _bestScore]] call FLO_fnc_log;
            nil
        };

        private _methodId = _selectedMethod get "id";
        _node set ["methodUsed", _methodId];
        _node set ["methodScore", _bestScore];
        ["GTN", 3, format["Selected method '%1' for '%2' (score: %3)", _methodId, _taskId, _bestScore]] call FLO_fnc_log;

        // Decompose subtasks
        private _subtasks = _selectedMethod get "subtasks";
        private _children = [];

        {
            _x params ["_subtaskId", "_subtaskParams"];

            // Resolve parameter references
            private _resolvedParams = _self call ["_resolveParams", [_subtaskParams, _params, _node]];

            // Create child node
            private _childNode = _self call ["_createPlanNode", [_subtaskId, _resolvedParams, _depth + 1]];

            // Recursively decompose
            private _decomposedChild = _self call ["_decompose", [_childNode]];

            if (isNil "_decomposedChild") exitWith {
                _children = nil;
            };

            _children pushBack _decomposedChild;
        } forEach _subtasks;

        if (isNil "_children") exitWith {
            ["GTN", 2, format["Failed to decompose subtasks for: %1", _taskId]] call FLO_fnc_log;
            nil
        };

        _node set ["children", _children];
        _node set ["isPrimitive", false];

        _node
    }],

    // Resolve parameter references in subtask params
    ["_resolveParams", {
        params ["_subtaskParams", "_parentParams", "_node"];

        private _resolved = [];

        {
            private _param = _x;

            if (_param isEqualType "" && {_param find "_PARAM_" == 0}) then {
                // Reference to parent param by index
                private _idx = parseNumber (_param select [7]);
                if (_idx < count _parentParams) then {
                    _resolved pushBack (_parentParams select _idx);
                } else {
                    _resolved pushBack nil;
                };
            } else {
                if (_param isEqualType "" && {_param find "_SELECTED_" == 0}) then {
                    // Reference to a selected value (set during execution)
                    _resolved pushBack _param;  // Keep as placeholder
                } else {
                    _resolved pushBack _param;
                };
            };
        } forEach _subtaskParams;

        _resolved
    }],

    // Flatten hierarchical plan to executable sequence
    ["_flattenPlan", {
        params ["_node"];

        private _result = [];

        if (_node getOrDefault ["isPrimitive", false]) then {
            _result pushBack _node;
        } else {
            private _children = _node get "children";
            {
                private _childFlat = _self call ["_flattenPlan", [_x]];
                _result append _childFlat;
            } forEach _children;
        };

        _result
    }],

    // === PLAN EXECUTION ===

    // Execute next task in plan
    ["_executeNext", {
        private _plan = _self get "_currentPlan";
        private _idx = _self get "_currentTaskIndex";

        if (_idx >= count _plan) exitWith {
            _self set ["_planStatus", "SUCCESS"];
            ["GTN", 3, "Plan execution complete"] call FLO_fnc_log;
            true
        };

        private _task = _plan select _idx;
        private _taskId = _task get "taskId";
        private _params = _task get "params";

        // Get primitive definition
        private _goalLib = _self get "_goalLibrary";
        private _primDef = _goalLib call ["_getPrimitive", [_taskId]];

        if (isNil "_primDef") exitWith {
            ["GTN", 1, format["Primitive not found: %1", _taskId]] call FLO_fnc_log;
            _self set ["_planStatus", "FAILED"];
            false
        };

        // Mark as running
        _task set ["status", "RUNNING"];
        _task set ["startTime", diag_tickTime];
        _self set ["_planStatus", "RUNNING"];

        // Execute handler
        private _handler = _primDef get "handler";
        ["GTN", 4, format["Executing primitive: %1 with handler: %2", _taskId, _handler]] call FLO_fnc_log;

        // Initialize primitiveData only if not already set (don't overwrite executor data)
        if (isNil {_task get "primitiveData"}) then {
            _task set ["primitiveData", createHashMap];
        };

        true
    }],

    // Check if current task is complete
    // Params: [executor] - executor object to check status from
    ["_checkCurrentTask", {
        params [["_executor", nil]];

        private _plan = _self get "_currentPlan";
        private _idx = _self get "_currentTaskIndex";

        if (_idx >= count _plan) exitWith { true };

        private _task = _plan select _idx;
        private _taskId = _task get "taskId";
        private _status = _task get "status";

        // If task is already complete from previous cycle, advance
        if (_status == "SUCCESS") exitWith {
            _self set ["_currentTaskIndex", _idx + 1];
            true
        };

        if (_status == "FAILED") exitWith {
            true  // Task is complete (failed), let commander handle it
        };

        // Task must be RUNNING to check executor
        if (_status != "RUNNING") exitWith { false };

        // First check executor's context status (set by handler)
        private _execStatus = "RUNNING";
        if (!isNil "_executor") then {
            _execStatus = _executor call ["_checkExecution", [_taskId]];
        };

        // If executor says SUCCESS or FAILED, use that
        if (_execStatus == "SUCCESS") exitWith {
            _task set ["status", "SUCCESS"];
            _task set ["endTime", diag_tickTime];
            _self set ["_currentTaskIndex", _idx + 1];

            private _stats = _self get "_planningStats";
            _stats set ["tasksExecuted", (_stats get "tasksExecuted") + 1];

            ["GTN", 3, format["Task complete: %1", _taskId]] call FLO_fnc_log;
            true
        };

        if (_execStatus == "FAILED") exitWith {
            _task set ["status", "FAILED"];
            _task set ["endTime", diag_tickTime];

            private _stats = _self get "_planningStats";
            _stats set ["tasksFailed", (_stats get "tasksFailed") + 1];

            ["GTN", 2, format["Task failed (executor): %1", _taskId]] call FLO_fnc_log;
            true
        };

        // Executor says RUNNING - check timeout
        private _goalLib = _self get "_goalLibrary";
        private _primDef = _goalLib call ["_getPrimitive", [_taskId]];

        private _timeout = _primDef get "timeout";
        private _startTime = _task get "startTime";

        if (diag_tickTime - _startTime > _timeout) then {
            _task set ["status", "FAILED"];
            _task set ["endTime", diag_tickTime];

            private _stats = _self get "_planningStats";
            _stats set ["tasksFailed", (_stats get "tasksFailed") + 1];

            ["GTN", 2, format["Task timeout: %1", _taskId]] call FLO_fnc_log;
            true
        } else {
            false
        }
    }],

    // === REPLANNING ===

    // Check if replan is needed
    ["_needsReplan", {
        params [["_oldSnapshot", nil]];

        private _ws = _self get "_worldState";
        _ws call ["_hasSignificantChange", [_oldSnapshot]]
    }],

    // Trigger replan
    ["_replan", {
        params ["_goalId", ["_params", []]];

        ["GTN", 3, format["Replanning for goal: %1", _goalId]] call FLO_fnc_log;

        private _stats = _self get "_planningStats";
        _stats set ["replans", (_stats get "replans") + 1];

        _self call ["_plan", [_goalId, _params]]
    }],

    // === QUERY METHODS ===

    ["_getPlanStatus", {
        _self get "_planStatus"
    }],

    ["_getCurrentPlan", {
        _self get "_currentPlan"
    }],

    ["_getCurrentTask", {
        private _plan = _self get "_currentPlan";
        private _idx = _self get "_currentTaskIndex";

        if (_idx >= count _plan) exitWith { nil };
        _plan select _idx
    }],

    ["_getStats", {
        _self get "_planningStats"
    }],

    // Debug output
    ["_debugPrint", {
        private _plan = _self get "_currentPlan";
        private _status = _self get "_planStatus";
        private _idx = _self get "_currentTaskIndex";

        private _taskList = "";
        {
            private _marker = if (_forEachIndex == _idx) then { ">" } else { " " };
            private _taskStatus = _x get "status";
            _taskList = _taskList + format["\n  %1 [%2] %3 (%4)", _marker, _forEachIndex, _x get "taskId", _taskStatus];
        } forEach _plan;

        format["GTN Plan [%1]:%2", _status, _taskList]
    }]
]];

["GTN", 3, "GTN Planner initialized"] call FLO_fnc_log;

_planner
