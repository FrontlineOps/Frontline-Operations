/*
 * Function: FLO_fnc_gtnGoalLibrary
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Goal Task Network goal library for the current frontline allocation model.
 * The live GTN path only uses:
 * - protect_critical_assets -> prim_allocate_frontline_defense
 * - capture_priority_objective -> prim_allocate_frontline_attacks
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Goal Library HashMap Object <HASHMAP>
 *
 * Example:
 * private _goalLib = call FLO_fnc_gtnGoalLibrary;
 * private _goal = _goalLib call ["_getGoal", ["capture_priority_objective"]];
 */

["GTN", 3, "Initializing GTN Goal Library"] call FLO_fnc_log;

#define GOAL_STRATEGIC "STRATEGIC"
#define GOAL_OPERATIONAL "OPERATIONAL"

private _goalLibrary = createHashMapObject [[
    ["_goals", createHashMap],
    ["_primitives", createHashMap],

    ["_registerGoal", {
        params ["_goalDef"];
        private _id = _goalDef get "id";
        private _goals = _self get "_goals";
        _goals set [_id, _goalDef];
        _self set ["_goals", _goals];
        ["GTN", 4, format ["Registered goal: %1", _id]] call FLO_fnc_log;
    }],

    ["_registerPrimitive", {
        params ["_primDef"];
        private _id = _primDef get "id";
        private _prims = _self get "_primitives";
        _prims set [_id, _primDef];
        _self set ["_primitives", _prims];
        ["GTN", 4, format ["Registered primitive: %1", _id]] call FLO_fnc_log;
    }],

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
        !isNil { (_self get "_primitives") get _taskId }
    }],

    ["_isGoal", {
        params ["_taskId"];
        !isNil { (_self get "_goals") get _taskId }
    }],

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

    ["_initialize", {
        _self call ["_registerGoals", []];
        _self call ["_registerPrimitives", []];

        ["GTN", 3, format [
            "Goal Library initialized with %1 goals and %2 primitives",
            count (keys (_self get "_goals")),
            count (keys (_self get "_primitives"))
        ]] call FLO_fnc_log;
    }],

    ["_registerGoals", {
        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "protect_critical_assets"],
            ["type", GOAL_STRATEGIC],
            ["description", "Protect threatened friendly objectives with shared frontline defense allocation"],
            ["preconditions", { true }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "active_defense"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _underAttack = _ws call ["_getObjectivesUnderAttack", []];
                        if ((count (keys _underAttack)) == 0) exitWith { -1 };
                        60
                    }],
                    ["subtasks", [
                        ["prim_allocate_frontline_defense", []]
                    ]]
                ],
                createHashMapFromArray [
                    ["id", "holding_defense"],
                    ["score", { 25 }],
                    ["subtasks", [
                        ["prim_allocate_frontline_defense", []]
                    ]]
                ]
            ]]
        ]]];

        _self call ["_registerGoal", [createHashMapFromArray [
            ["id", "capture_priority_objective"],
            ["type", GOAL_OPERATIONAL],
            ["description", "Spend the shared offensive pool across valid frontline attack objectives"],
            ["preconditions", {
                params ["_ws", "_params"];
                count (keys (_ws call ["_getFrontlineEnemyObjectives", []])) > 0
            }],
            ["methods", [
                createHashMapFromArray [
                    ["id", "frontline_allocation"],
                    ["score", {
                        params ["_ws", "_params", "_planner"];
                        private _forces = _ws call ["_getForces", []];
                        private _available = _forces get "availableGroups";
                        if (_available < 1) exitWith { -1 };

                        private _frontlineObjectives = _ws call ["_getFrontlineEnemyObjectives", []];
                        private _score = 30 + ((count (keys _frontlineObjectives)) * 5);
                        if (_available >= 6) then { _score = _score + 10 };
                        if (_available >= 12) then { _score = _score + 15 };
                        if (_available >= 20) then { _score = _score + 20 };

                        private _situation = _ws call ["_getTacticalSituation", []];
                        if ((_situation get "momentum") > 0) then {
                            _score = _score + 10;
                        };

                        _score
                    }],
                    ["subtasks", [
                        ["prim_allocate_frontline_attacks", []]
                    ]]
                ]
            ]]
        ]]];
    }],

    ["_registerPrimitives", {
        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_allocate_frontline_attacks"],
            ["description", "Allocate attack groups across current frontline objectives"],
            ["handler", "GTN_allocateFrontlineAttacks"],
            ["timeout", 30],
            ["completionCheck", { true }]
        ]]];

        _self call ["_registerPrimitive", [createHashMapFromArray [
            ["id", "prim_allocate_frontline_defense"],
            ["description", "Allocate defense groups across threatened objectives"],
            ["handler", "GTN_allocateFrontlineDefense"],
            ["timeout", 30],
            ["completionCheck", { true }]
        ]]];
    }]
]];

_goalLibrary call ["_initialize", []];

["GTN", 3, "GTN Goal Library created"] call FLO_fnc_log;

_goalLibrary
