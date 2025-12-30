/*
 * Function: FLO_fnc_gtnGoalLibrary
 * Author: Frontline Operations Development Group
 * 
 * Description:
 * Goal Task Network Goal Library - Defines all goals, methods, and primitives.
 * Goals are hierarchical: Strategic → Operational → Tactical → Primitive
 * Each goal has preconditions and decomposition methods with conditions.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Goal Library HashMap Object <HASHMAP>
 *
 * Example:
 * private _goalLib = call FLO_fnc_gtnGoalLibrary;
 * private _goal = _goalLib call ["_getGoal", ["capture_objective"]];
 */

["GTN", 3, "Initializing GTN Goal Library"] call FLO_fnc_log;

// Goal type constants
#define GOAL_STRATEGIC  "STRATEGIC"
#define GOAL_OPERATIONAL "OPERATIONAL"
#define GOAL_TACTICAL   "TACTICAL"
#define GOAL_PRIMITIVE  "PRIMITIVE"

private _goalLibrary = createHashMapObject [[
    // Storage for all goals
    ["_goals", createHashMap],
    
    // Storage for primitive action definitions
    ["_primitives", createHashMap],
    
    // === GOAL REGISTRATION ===
    
    ["_registerGoal", {
        params ["_goalDef"];
        private _id = _goalDef get "id";
        private _goals = _self get "_goals";
        _goals set [_id, _goalDef];
        _self set ["_goals", _goals];
        ["GTN", 4, format["Registered goal: %1", _id]] call FLO_fnc_log;
    }],
    
    ["_registerPrimitive", {
        params ["_primDef"];
        private _id = _primDef get "id";
        private _prims = _self get "_primitives";
        _prims set [_id, _primDef];
        _self set ["_primitives", _prims];
        ["GTN", 4, format["Registered primitive: %1", _id]] call FLO_fnc_log;
    }],
    
    // === GOAL RETRIEVAL ===
    
    ["_getGoal", {
        params ["_goalId"];
        (_self get "_goals") getOrDefault [_goalId, nil]
    }],
    
    ["_getPrimitive", {
        params ["_primitiveId"];
        (_self get "_primitives") getOrDefault [_primitiveId, nil]
    }],
    
    ["_isPrimitive", {
        params ["_taskId"];
        !isNil {(_self get "_primitives") get _taskId}
    }],
    
    ["_isGoal", {
        params ["_taskId"];
        !isNil {(_self get "_goals") get _taskId}
    }],
    
    // Get all goals of a specific type
    ["_getGoalsByType", {
        params ["_type"];
        private _result = [];
        private _goals = _self get "_goals";
        
        {
            private _goal = _goals get _x;
            if ((_goal get "type") == _type) then {
                _result pushBack _goal;
            };
        } forEach (keys _goals);
        
        _result
    }],
    
    // === INITIALIZATION - Register all goals ===
    
    ["_initialize", {
        // Register strategic goals
        _self call ["_registerStrategicGoals", []];
        
        // Register operational goals
        _self call ["_registerOperationalGoals", []];
        
        // Register tactical goals
        _self call ["_registerTacticalGoals", []];
        
        // Register primitive actions
        _self call ["_registerPrimitives", []];
        
        ["GTN", 3, format["Goal Library initialized with %1 goals and %2 primitives", 
            count (keys (_self get "_goals")),
            count (keys (_self get "_primitives"))
        ]] call FLO_fnc_log;
    }],
    
    // === STRATEGIC GOALS ===
    
    ["_registerStrategicGoals", {
        // CONTROL_AO - Main mission goal
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "control_ao"],
            ["type", GOAL_STRATEGIC],
            ["description", "Maintain control of the area of operations"],
            ["preconditions", {
                params ["_ws", "_params"];
                true  // Always applicable
            }],
            ["methods", [
                // Method 1: Offensive - capture enemy objectives
                createHashMapFromArray [
                    ["id", "offensive_posture"],
                    ["conditions", {
                        params ["_ws", "_params"];
                        private _forces = _ws call ["_getForces", []];
                        private _situation = _ws call ["_getTacticalSituation", []];
                        // Use offensive when we have momentum and available forces
                        (_situation get "momentum") >= 0 && 
                        {(_forces get "availableGroups") >= 4}
                    }],
                    ["subtasks", [
                        ["capture_priority_objective", []],
                        ["maintain_force_ratio", []]
                    ]]
                ],
                // Method 2: Defensive - protect our objectives
                createHashMapFromArray [
                    ["id", "defensive_posture"],
                    ["conditions", {
                        params ["_ws", "_params"];
                        true  // Fallback method
                    }],
                    ["subtasks", [
                        ["protect_critical_assets", []],
                        ["maintain_force_ratio", []]
                    ]]
                ]
            ]]
        ]]];

        // MAINTAIN_FORCE_RATIO - Keep forces balanced
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "maintain_force_ratio"],
            ["type", GOAL_STRATEGIC],
            ["description", "Maintain favorable force ratio against enemy"],
            ["preconditions", { true }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "reinforce_weak_sectors"],
                    ["conditions", {
                        params ["_ws", "_params"];
                        private _forces = _ws call ["_getForces", []];
                        (_forces get "availableGroups") > 0
                    }],
                    ["subtasks", [
                        ["reinforce_sector", []]
                    ]]
                ]
            ]]
        ]]];

        // PROTECT_CRITICAL_ASSETS - Defend our objectives
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "protect_critical_assets"],
            ["type", GOAL_STRATEGIC],
            ["description", "Protect high-value objectives from enemy attack"],
            ["preconditions", { true }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "active_defense"],
                    ["conditions", {
                        params ["_ws", "_params"];
                        private _underAttack = _ws call ["_getObjectivesUnderAttack", []];
                        count (keys _underAttack) > 0
                    }],
                    ["subtasks", [
                        ["defend_objective", ["_HIGHEST_PRIORITY_UNDER_ATTACK"]]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "garrison_defense"],
                    ["conditions", { true }],
                    ["subtasks", [
                        ["establish_garrison", []]
                    ]]
                ]
            ]]
        ]]];
    }],

    // === OPERATIONAL GOALS ===

    ["_registerOperationalGoals", {
        // CAPTURE_PRIORITY_OBJECTIVE - Attack highest priority enemy objective
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "capture_priority_objective"],
            ["type", GOAL_OPERATIONAL],
            ["description", "Capture the highest priority enemy-held objective"],
            ["preconditions", {
                params ["_ws", "_params"];
                private _enemyObjs = _ws call ["_getEnemyObjectives", []];
                count (keys _enemyObjs) > 0
            }],
            ["methods", [
                // Method 1: Direct assault with superiority
                createHashMapFromArray [
                    ["id", "direct_assault"],
                    ["conditions", {
                        params ["_ws", "_params"];
                        private _forces = _ws call ["_getForces", []];
                        // Need substantial available forces
                        (_forces get "availableGroups") >= 6
                    }],
                    ["subtasks", [
                        ["select_objective", []],
                        ["assault_objective", ["_SELECTED_OBJECTIVE"]]
                    ]]
                ],
                // Method 2: Prepared assault with fire support
                createHashMapFromArray [
                    ["id", "prepared_assault"],
                    ["conditions", {
                        params ["_ws", "_params"];
                        private _forces = _ws call ["_getForces", []];
                        private _artyAvail = _ws call ["_isAssetAvailable", ["artillery"]];
                        (_forces get "availableGroups") >= 3 && _artyAvail
                    }],
                    ["subtasks", [
                        ["select_objective", []],
                        ["stage_assault_force", ["_SELECTED_OBJECTIVE"]],
                        ["preparatory_fires", ["_SELECTED_OBJECTIVE"]],
                        ["assault_objective", ["_SELECTED_OBJECTIVE"]]
                    ]]
                ],
                // Method 3: Opportunistic attack on vulnerable objective
                createHashMapFromArray [
                    ["id", "opportunistic_attack"],
                    ["conditions", {
                        params ["_ws", "_params"];
                        private _vulnObjs = _ws call ["_getVulnerableObjectives", []];
                        count (keys _vulnObjs) > 0
                    }],
                    ["subtasks", [
                        ["prim_attack_vulnerable_objective", []]
                    ]]
                ]
            ]]
        ]]];

        // DEFEND_OBJECTIVE - Defend a specific objective
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "defend_objective"],
            ["type", GOAL_OPERATIONAL],
            ["description", "Defend a specific objective against enemy attack"],
            ["preconditions", {
                params ["_ws", "_params"];
                _params params [["_objId", ""]];
                _objId != "" || {count (keys (_ws call ["_getObjectivesUnderAttack", []])) > 0}
            }],
            ["methods", [
                // Method 1: Immediate reinforcement
                createHashMapFromArray [
                    ["id", "immediate_reinforcement"],
                    ["conditions", {
                        params ["_ws", "_params"];
                        private _forces = _ws call ["_getForces", []];
                        (_forces get "availableGroups") >= 2
                    }],
                    ["subtasks", [
                        ["dispatch_qrf", ["_PARAM_0"]],
                        ["establish_defense", ["_PARAM_0"]]
                    ]]
                ],
                // Method 2: Defense with fire support
                createHashMapFromArray [
                    ["id", "defense_with_fires"],
                    ["conditions", {
                        params ["_ws", "_params"];
                        _ws call ["_isAssetAvailable", ["artillery"]]
                    }],
                    ["subtasks", [
                        ["prim_call_defensive_fires", ["_PARAM_0"]],
                        ["prim_establish_defense", ["_PARAM_0"]]
                    ]]
                ]
            ]]
        ]]];

        // REINFORCE_SECTOR - Send forces to weak area
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "reinforce_sector"],
            ["type", GOAL_OPERATIONAL],
            ["description", "Reinforce a sector that needs additional forces"],
            ["preconditions", {
                params ["_ws", "_params"];
                private _forces = _ws call ["_getForces", []];
                (_forces get "availableGroups") > 0
            }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "send_reinforcements"],
                    ["conditions", { true }],
                    ["subtasks", [
                        ["prim_identify_weak_sector", []],
                        ["prim_move_forces_to_sector", ["_WEAK_SECTOR"]]
                    ]]
                ]
            ]]
        ]]];
    }],

    // === TACTICAL GOALS ===

    ["_registerTacticalGoals", {
        // STAGE_ASSAULT_FORCE - Gather forces at staging point
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "stage_assault_force"],
            ["type", GOAL_TACTICAL],
            ["description", "Stage assault forces at a staging point before attack"],
            ["preconditions", {
                params ["_ws", "_params"];
                _params params [["_objId", ""]];
                _objId != ""
            }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "standard_staging"],
                    ["conditions", { true }],
                    ["subtasks", [
                        ["prim_select_staging_point", ["_PARAM_0"]],
                        ["prim_assign_groups_to_staging", ["_PARAM_0", 4]],
                        ["prim_wait_for_staging", ["_PARAM_0"]]
                    ]]
                ]
            ]]
        ]]];

        // ASSAULT_OBJECTIVE - Execute attack on objective
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "assault_objective"],
            ["type", GOAL_TACTICAL],
            ["description", "Execute assault on an objective"],
            ["preconditions", {
                params ["_ws", "_params"];
                _params params [["_objId", ""]];
                _objId != ""
            }],
            ["methods", [
                // Combined arms assault
                createHashMapFromArray [
                    ["id", "combined_arms_assault"],
                    ["conditions", {
                        params ["_ws", "_params"];
                        _ws call ["_isAssetAvailable", ["cas"]]
                    }],
                    ["subtasks", [
                        ["prim_call_cas", ["_PARAM_0"]],
                        ["prim_attack_objective", ["_PARAM_0"]]
                    ]]
                ],
                // Infantry assault
                createHashMapFromArray [
                    ["id", "infantry_assault"],
                    ["conditions", { true }],
                    ["subtasks", [
                        ["prim_attack_objective", ["_PARAM_0"]]
                    ]]
                ]
            ]]
        ]]];

        // PREPARATORY_FIRES - Call artillery before assault
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "preparatory_fires"],
            ["type", GOAL_TACTICAL],
            ["description", "Call preparatory artillery fires on objective"],
            ["preconditions", {
                params ["_ws", "_params"];
                _ws call ["_isAssetAvailable", ["artillery"]]
            }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "standard_prep_fires"],
                    ["conditions", { true }],
                    ["subtasks", [
                        ["prim_call_artillery", ["_PARAM_0", "PREPARATORY", 8]]
                    ]]
                ]
            ]]
        ]]];

        // ESTABLISH_DEFENSE - Set up defensive position
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "establish_defense"],
            ["type", GOAL_TACTICAL],
            ["description", "Establish defensive position at objective"],
            ["preconditions", { true }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "standard_defense"],
                    ["conditions", { true }],
                    ["subtasks", [
                        ["prim_assign_groups_to_defense", ["_PARAM_0", 2]],
                        ["prim_set_defense_posture", ["_PARAM_0"]]
                    ]]
                ]
            ]]
        ]]];

        // DISPATCH_QRF - Send quick reaction force
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "dispatch_qrf"],
            ["type", GOAL_TACTICAL],
            ["description", "Dispatch quick reaction force to location"],
            ["preconditions", {
                params ["_ws", "_params"];
                private _forces = _ws call ["_getForces", []];
                (_forces get "availableGroups") >= 1
            }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "immediate_qrf"],
                    ["conditions", { true }],
                    ["subtasks", [
                        ["prim_assign_groups_to_defense", ["_PARAM_0", 2]],
                        ["prim_move_to_position", ["_PARAM_0", "COMBAT"]]
                    ]]
                ]
            ]]
        ]]];

        // SELECT_OBJECTIVE - Choose best objective to attack
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "select_objective"],
            ["type", GOAL_TACTICAL],
            ["description", "Select the best objective to attack"],
            ["preconditions", { true }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "priority_selection"],
                    ["conditions", { true }],
                    ["subtasks", [
                        ["prim_select_priority_objective", []]
                    ]]
                ]
            ]]
        ]]];
    }],

    // === PRIMITIVE ACTIONS ===

    ["_registerPrimitives", {
        // These are leaf nodes - actual executable actions

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_select_staging_point"],
            ["description", "Calculate staging point for objective"],
            ["handler", "GTN_selectStagingPoint"],
            ["timeout", 5],
            ["completionCheck", { true }]  // Immediate
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_assign_groups_to_staging"],
            ["description", "Assign groups to move to staging point"],
            ["handler", "GTN_assignGroupsToStaging"],
            ["timeout", 300],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                // Check if groups have arrived at staging
                private _arrived = _taskData getOrDefault ["groupsArrived", 0];
                private _assigned = _taskData getOrDefault ["groupsAssigned", 0];
                _arrived >= _assigned
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_wait_for_staging"],
            ["description", "Wait for forces to assemble at staging"],
            ["handler", "GTN_waitForStaging"],
            ["timeout", 600],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                private _minForce = _taskData getOrDefault ["minForce", 3];
                private _assembled = _taskData getOrDefault ["assembled", 0];
                _assembled >= _minForce
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_attack_objective"],
            ["description", "Order groups to attack objective"],
            ["handler", "GTN_attackObjective"],
            ["timeout", 1800],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                private _objId = _taskData get "objectiveId";
                private _objectives = _ws call ["_getObjectives", []];
                private _obj = _objectives getOrDefault [_objId, nil];
                if (isNil "_obj") exitWith { false };
                (_obj get "owner") == east  // Objective captured
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_call_artillery"],
            ["description", "Call artillery fire mission"],
            ["handler", "GTN_callArtillery"],
            ["timeout", 120],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                private _fired = _taskData getOrDefault ["missionFired", false];
                _fired
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_call_cas"],
            ["description", "Call close air support"],
            ["handler", "GTN_callCAS"],
            ["timeout", 300],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                private _completed = _taskData getOrDefault ["missionComplete", false];
                _completed
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_assign_groups_to_defense"],
            ["description", "Assign groups to defend position"],
            ["handler", "GTN_assignGroupsToDefense"],
            ["timeout", 300],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                private _arrived = _taskData getOrDefault ["groupsArrived", 0];
                _arrived >= 1
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_set_defense_posture"],
            ["description", "Set groups to defensive posture"],
            ["handler", "GTN_setDefensePosture"],
            ["timeout", 30],
            ["completionCheck", { true }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_move_to_position"],
            ["description", "Move groups to a position"],
            ["handler", "GTN_moveToPosition"],
            ["timeout", 600],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                private _arrived = _taskData getOrDefault ["arrived", false];
                _arrived
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_select_priority_objective"],
            ["description", "Select highest priority objective to attack"],
            ["handler", "GTN_selectPriorityObjective"],
            ["timeout", 5],
            ["completionCheck", { true }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_identify_weak_sector"],
            ["description", "Identify sector needing reinforcement"],
            ["handler", "GTN_identifyWeakSector"],
            ["timeout", 5],
            ["completionCheck", { true }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_move_forces_to_sector"],
            ["description", "Move forces to reinforce sector"],
            ["handler", "GTN_moveForcesToSector"],
            ["timeout", 600],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                _taskData getOrDefault ["arrived", false]
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_attack_vulnerable_objective"],
            ["description", "Attack a vulnerable enemy objective"],
            ["handler", "GTN_attackVulnerableObjective"],
            ["timeout", 1800],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                private _objId = _taskData get "objectiveId";
                private _objectives = _ws call ["_getObjectives", []];
                private _obj = _objectives getOrDefault [_objId, nil];
                if (isNil "_obj") exitWith { false };
                (_obj get "owner") == east
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_call_defensive_fires"],
            ["description", "Call defensive artillery fire"],
            ["handler", "GTN_callDefensiveFires"],
            ["timeout", 120],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                _taskData getOrDefault ["missionFired", false]
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_establish_defense"],
            ["description", "Establish defensive position"],
            ["handler", "GTN_establishDefense"],
            ["timeout", 300],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                _taskData getOrDefault ["established", false]
            }]
        ]]];
    }]
]];

// Initialize the library
_goalLibrary call ["_initialize", []];

["GTN", 3, "GTN Goal Library created"] call FLO_fnc_log;

_goalLibrary
