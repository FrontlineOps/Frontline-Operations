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
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "control_ao"],
            ["type", GOAL_STRATEGIC],
            ["description", "Maintain control of the area of operations"],
            ["preconditions", { true }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "offensive_posture"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _forces = _ws call ["_getForces", []];
                        private _situation = _ws call ["_getTacticalSituation", []];
                        private _intel = _ws call ["_getEnemyIntel", []];
                        private _available = _forces get "availableGroups";
                        private _total = _forces get "totalGroups";
                        private _underAttack = _ws call ["_getObjectivesUnderAttack", []];
                        private _attackCount = count (keys _underAttack);

                        if (_available < 3) exitWith { -1 };
                        if (_attackCount >= 2) exitWith { -1 };

                        private _score = 40;

                        private _momentum = _situation get "momentum";
                        _score = _score + (_momentum * 0.4);

                        if (_attackCount > 0) then { _score = _score - 35 };

                        private _threatLevel = _intel getOrDefault ["threatLevel", 0];
                        _score = _score - (_threatLevel * 3);

                        private _reserveRatio = if (_total > 0) then { _available / _total } else { 0 };
                        if (_reserveRatio < 0.3) then { _score = _score - 20 };
                        if (_reserveRatio >= 0.5) then { _score = _score + 15 };

                        if (_available >= 6) then { _score = _score + 20 };
                        if (_available >= 4) then { _score = _score + 10 };

                        if ((_situation get "initiativeHolder") == "OPFOR") then { _score = _score + 15 };
                        if ((_situation get "initiativeHolder") == "BLUFOR") then { _score = _score - 15 };

                        _score
                    }],
                    ["subtasks", [
                        ["capture_priority_objective", []],
                        ["maintain_force_ratio", []]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "defensive_posture"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _forces = _ws call ["_getForces", []];
                        private _situation = _ws call ["_getTacticalSituation", []];
                        private _intel = _ws call ["_getEnemyIntel", []];
                        private _available = _forces get "availableGroups";
                        private _total = _forces get "totalGroups";
                        private _underAttack = _ws call ["_getObjectivesUnderAttack", []];
                        private _attackCount = count (keys _underAttack);

                        private _score = 25;

                        private _momentum = _situation get "momentum";
                        if (_momentum < 0) then { _score = _score + (abs _momentum * 0.5) };

                        _score = _score + (_attackCount * 25);

                        private _threatLevel = _intel getOrDefault ["threatLevel", 0];
                        _score = _score + (_threatLevel * 2);

                        private _reserveRatio = if (_total > 0) then { _available / _total } else { 0 };
                        if (_reserveRatio < 0.3) then { _score = _score + 15 };

                        if ((_situation get "initiativeHolder") == "BLUFOR") then { _score = _score + 20 };

                        _score
                    }],
                    ["subtasks", [
                        ["protect_critical_assets", []],
                        ["maintain_force_ratio", []]
                    ]]
                ]
            ]]
        ]]];

        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "maintain_force_ratio"],
            ["type", GOAL_STRATEGIC],
            ["description", "Maintain favorable force ratio against enemy"],
            ["preconditions", { true }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "reinforce_weak_sectors"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _forces = _ws call ["_getForces", []];
                        if ((_forces get "availableGroups") < 1) exitWith { -1 };
                        30
                    }],
                    ["subtasks", [
                        ["reinforce_sector", []]
                    ]]
                ]
            ]]
        ]]];

        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "protect_critical_assets"],
            ["type", GOAL_STRATEGIC],
            ["description", "Protect high-value objectives from enemy attack"],
            ["preconditions", { true }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "active_defense"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _underAttack = _ws call ["_getObjectivesUnderAttack", []];
                        if (count (keys _underAttack) == 0) exitWith { -1 };
                        60
                    }],
                    ["subtasks", [
                        ["defend_objective", ["_HIGHEST_PRIORITY_UNDER_ATTACK"]]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "garrison_defense"],
                    ["score", { 25 }],
                    ["subtasks", [
                        ["establish_garrison", []]
                    ]]
                ]
            ]]
        ]]];
    }],

    // === OPERATIONAL GOALS ===

    ["_registerOperationalGoals", {
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "capture_priority_objective"],
            ["type", GOAL_OPERATIONAL],
            ["description", "Capture the highest priority enemy-held objective"],
            ["preconditions", {
                params ["_ws", "_params"];
                count (keys (_ws call ["_getEnemyObjectives", []])) > 0
            }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "prepared_assault"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _forces = _ws call ["_getForces", []];
                        private _assets = _ws call ["_getSupportAssets", []];
                        private _available = _forces get "availableGroups";
                        if (_available < 3) exitWith { -1 };
                        if !(_assets get "artilleryAvailable") exitWith { -1 };

                        private _score = 40;
                        // Scale artillery ammo bonus: +2 per round, capped at +100
                        private _artyBonus = ((_assets get "artilleryAmmo") * 2) min 100;
                        _score = _score + _artyBonus;
                        private _armor = _ws call ["_getArmorGroupCount", []];
                        if (_armor >= 2) then { _score = _score + 15 };
                        private _situation = _ws call ["_getTacticalSituation", []];
                        if ((_situation get "momentum") < 0) then { _score = _score + 10 };
                        _score
                    }],
                    ["subtasks", [
                        ["select_objective", []],
                        ["recon_objective", ["_SELECTED_OBJECTIVE"]],
                        ["stage_assault_force", ["_SELECTED_OBJECTIVE"]],
                        ["preparatory_fires", ["_SELECTED_OBJECTIVE"]],
                        ["assault_objective", ["_SELECTED_OBJECTIVE"]]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "direct_assault"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _forces = _ws call ["_getForces", []];
                        private _available = _forces get "availableGroups";
                        if (_available < 4) exitWith { -1 };

                        private _score = 30;
                        if (_available >= 8) then { _score = _score + 25 };
                        if (_available >= 6) then { _score = _score + 15 };
                        private _situation = _ws call ["_getTacticalSituation", []];
                        if ((_situation get "momentum") > 20) then { _score = _score + 20 };
                        private _vulnObjs = _ws call ["_getVulnerableObjectives", []];
                        if (count (keys _vulnObjs) > 0) then { _score = _score + 15 };
                        _score
                    }],
                    ["subtasks", [
                        ["select_objective", []],
                        ["assault_objective", ["_SELECTED_OBJECTIVE"]]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "opportunistic_attack"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _vulnObjs = _ws call ["_getVulnerableObjectives", []];
                        if (count (keys _vulnObjs) == 0) exitWith { -1 };
                        private _forces = _ws call ["_getForces", []];
                        if ((_forces get "availableGroups") < 2) exitWith { -1 };
                        25
                    }],
                    ["subtasks", [
                        ["prim_attack_vulnerable_objective", []]
                    ]]
                ]
            ]]
        ]]];

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
                createHashMapFromArray [
                    ["id", "defense_with_fires"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _assets = _ws call ["_getSupportAssets", []];
                        if !(_assets get "artilleryAvailable") exitWith { -1 };

                        private _score = 50;
                        // Scale artillery ammo bonus: +1.5 per round, capped at +75 for defense
                        private _artyBonus = ((_assets get "artilleryAmmo") * 1.5) min 75;
                        _score = _score + _artyBonus;
                        private _forces = _ws call ["_getForces", []];
                        if ((_forces get "availableGroups") < 2) then { _score = _score + 20 };
                        _score
                    }],
                    ["subtasks", [
                        ["prim_call_defensive_fires", ["_PARAM_0"]],
                        ["prim_establish_defense", ["_PARAM_0"]]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "immediate_reinforcement"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _forces = _ws call ["_getForces", []];
                        private _available = _forces get "availableGroups";
                        if (_available < 2) exitWith { -1 };

                        private _score = 40;
                        if (_available >= 4) then { _score = _score + 20 };
                        private _armor = _ws call ["_getArmorGroupCount", []];
                        if (_armor >= 1) then { _score = _score + 15 };
                        _score
                    }],
                    ["subtasks", [
                        ["dispatch_qrf", ["_PARAM_0"]],
                        ["establish_defense", ["_PARAM_0"]]
                    ]]
                ]
            ]]
        ]]];

        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "reinforce_sector"],
            ["type", GOAL_OPERATIONAL],
            ["description", "Reinforce a sector that needs additional forces"],
            ["preconditions", {
                params ["_ws", "_params"];
                (_ws call ["_getForces", []] get "availableGroups") > 0
            }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "send_reinforcements"],
                    ["score", { 30 }],
                    ["subtasks", [
                        ["prim_identify_weak_sector", []],
                        ["prim_move_forces_to_sector", ["_WEAK_SECTOR"]]
                    ]]
                ]
            ]]
        ]]];
        
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "interdict_enemy_forces"],
            ["type", GOAL_OPERATIONAL],
            ["description", "Interdict known enemy concentrations"],
            ["preconditions", {
                params ["_ws", "_params"];
                private _intel = _ws call ["_getEnemyIntel", []];
                count (_intel getOrDefault ["concentrations", []]) > 0
            }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "cas_interdiction"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        if !(_ws call ["_isAssetAvailable", ["cas"]]) exitWith { -1 };
                        
                        private _score = 55;
                         // Bonus for high threat level
                        private _intel = _ws call ["_getEnemyIntel", []];
                        private _threat = _intel getOrDefault ["threatLevel", 0];
                        if (_threat > 5) then { _score = _score + 10 };
                        
                        _score
                    }],
                    ["subtasks", [
                        ["prim_select_target_concentration", []],
                        ["prim_call_cas_coord", ["_SELECTED_CONCENTRATION"]]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "infantry_assault"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _forces = _ws call ["_getForces", []];
                        private _available = _forces get "availableGroups";
                        
                        if (_available < 3) exitWith { -1 };
                        
                        private _score = 40;
                        if (_available >= 5) then { _score = _score + 15 };
                        
                        _score
                    }],
                    ["subtasks", [
                        ["prim_select_target_concentration", []],
                        ["prim_assault_coord", ["_SELECTED_CONCENTRATION"]]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "artillery_interdiction"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _assets = _ws call ["_getSupportAssets", []];
                        if !(_assets get "artilleryAvailable") exitWith { -1 };
                        
                        private _score = 45;
                        // Bonus for high threat level
                        private _intel = _ws call ["_getEnemyIntel", []];
                        private _threat = _intel getOrDefault ["threatLevel", 0];
                        if (_threat > 5) then { _score = _score + 15 };
                        
                        // Penalty if friendly forces are very close to enemy (danger close)
                        // This logic should be in the primitive selection really, but score drop helps
                        
                        _score
                    }],
                    ["subtasks", [
                        ["prim_select_target_concentration", []],
                        ["prim_call_artillery_coord", ["_SELECTED_CONCENTRATION"]]
                    ]]
                ]
            ]]
        ]]];
    }],

    // === TACTICAL GOALS ===

    ["_registerTacticalGoals", {
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "recon_objective"],
            ["type", GOAL_TACTICAL],
            ["description", "Conduct reconnaissance on an objective"],
            ["preconditions", {
                params ["_ws", "_params"];
                _params params [["_objId", ""]];
                _objId != ""
            }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "ground_recon"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _forces = _ws call ["_getForces", []];
                        if ((_forces get "infantryGroups") < 1) exitWith { -1 };
                        private _score = 40;
                        private _objId = _params param [0, ""];
                        if (_objId != "" && {!(_ws call ["_isIntelFresh", [_objId, 300]])}) then {
                            _score = _score + 20;
                        };
                        _score
                    }],
                    ["subtasks", [
                        ["prim_send_recon_patrol", ["_PARAM_0"]],
                        ["prim_wait_for_recon", ["_PARAM_0"]]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "air_recon"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        if !(_ws call ["_isAssetAvailable", ["cas"]]) exitWith { -1 };

                        // Air recon is faster and safer than ground patrol
                        private _score = 55;  // Base higher than ground_recon (40)

                        // Bonus if objective is far from friendly forces
                        private _objId = _params param [0, ""];
                        if (_objId != "") then {
                            private _objPos = [_objId] call FLO_fnc_getObjectivePosition;
                            if (!isNil "_objPos") then {
                                private _friendlyDist = _ws call ["_getNearestFriendlyDistance", [_objPos]];
                                if (_friendlyDist > 2000) then { _score = _score + 20 };
                                
                                // CHECK FOR AA THREAT
                                private _intel = _ws call ["_getObjectiveIntel", [_objId]];
                                if (_intel get "hasAA") then {
                                    // Heavy penalty if AA is known
                                    _score = _score - 30;
                                    ["GTN", 3, format["Air recon score penalty for %1 due to known AA", _objId]] call FLO_fnc_log;
                                };
                            };
                        };

                        // Bonus for ordnance availability (aircraft can defend itself if needed)
                        private _assets = _ws call ["_getSupportAssets", []];
                        private _ordnance = _assets getOrDefault ["casOrdnance", 0];
                        if (_ordnance > 4) then { _score = _score + 10 };

                        _score
                    }],
                    ["subtasks", [
                        ["prim_request_air_recon", ["_PARAM_0"]]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "skip_recon"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _objId = _params param [0, ""];
                        if (_objId == "") exitWith { 10 };
                        if (_ws call ["_isIntelFresh", [_objId, 300]]) exitWith { 50 };
                        5
                    }],
                    ["subtasks", [
                        ["prim_use_existing_intel", ["_PARAM_0"]]
                    ]]
                ]
            ]]
        ]]];

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
                    ["score", { 30 }],
                    ["subtasks", [
                        ["prim_select_staging_point", ["_PARAM_0"]],
                        ["prim_assign_groups_to_staging", ["_PARAM_0", 4]],
                        ["prim_wait_for_staging", ["_PARAM_0"]]
                    ]]
                ]
            ]]
        ]]];

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
                createHashMapFromArray [
                    ["id", "combined_arms_assault"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        if !(_ws call ["_isAssetAvailable", ["cas"]]) exitWith { -1 };

                        private _score = 45;
                        // Add ordnance bonus: +3 per missile/bomb, capped at +60
                        private _assets = _ws call ["_getSupportAssets", []];
                        private _ordnance = _assets getOrDefault ["casOrdnance", 0];
                        private _ordBonus = (_ordnance * 3) min 60;
                        _score = _score + _ordBonus;

                        private _objId = _params param [0, ""];
                        if (_objId != "") then {
                            private _analysis = _ws call ["_getObjectiveAnalysis", [_objId]];
                            if (!isNil "_analysis") then {
                                if (_analysis get "hasArmor") then { _score = _score + 25 };
                                if ((_analysis get "fortificationLevel") >= 2) then { _score = _score + 15 };
                            };
                        };
                        _score
                    }],
                    ["subtasks", [
                        ["prim_call_cas", ["_PARAM_0"]],
                        ["prim_attack_objective", ["_PARAM_0"]]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "infantry_assault"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _score = 30;
                        private _forces = _ws call ["_getForces", []];
                        if ((_forces get "availableGroups") >= 6) then { _score = _score + 20 };
                        private _armor = _ws call ["_getArmorGroupCount", []];
                        if (_armor >= 2) then { _score = _score + 15 };
                        _score
                    }],
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
            ["id", "prim_select_target_concentration"],
            ["description", "Select highest threat enemy concentration"],
            ["handler", "GTN_selectTargetConcentration"],
            ["timeout", 5],
            ["completionCheck", { true }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_call_artillery_coord"],
            ["description", "Call artillery on specific coordinate"],
            ["handler", "GTN_callArtilleryCoord"],
            ["timeout", 120],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                _taskData getOrDefault ["missionFired", false]
            }]
        ]]];
        
        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_call_cas_coord"],
            ["description", "Call CAS on specific coordinate"],
            ["handler", "GTN_callCASCoord"],
            ["timeout", 300],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                _taskData getOrDefault ["missionComplete", false]
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_assault_coord"],
            ["description", "Assault specific coordinate"],
            ["handler", "GTN_assaultCoord"],
            ["timeout", 900],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                _taskData getOrDefault ["arrived", false]
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

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_send_recon_patrol"],
            ["description", "Send infantry patrol to recon objective"],
            ["handler", "GTN_sendReconPatrol"],
            ["timeout", 600],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                _taskData getOrDefault ["patrolDispatched", false]
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_wait_for_recon"],
            ["description", "Wait for recon patrol to report"],
            ["handler", "GTN_waitForRecon"],
            ["timeout", 900],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                private _objId = _taskData getOrDefault ["objectiveId", ""];
                if (_objId == "") exitWith { false };
                _ws call ["_isIntelFresh", [_objId, 60]]
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_request_air_recon"],
            ["description", "Request aerial reconnaissance"],
            ["handler", "GTN_requestAirRecon"],
            ["timeout", 300],
            ["completionCheck", {
                params ["_ws", "_taskData"];
                _taskData getOrDefault ["reconComplete", false]
            }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_use_existing_intel"],
            ["description", "Use existing intel without new recon"],
            ["handler", "GTN_useExistingIntel"],
            ["timeout", 5],
            ["completionCheck", { true }]
        ]]];
    }]
]];

// Initialize the library
_goalLibrary call ["_initialize", []];

["GTN", 3, "GTN Goal Library created"] call FLO_fnc_log;

_goalLibrary
