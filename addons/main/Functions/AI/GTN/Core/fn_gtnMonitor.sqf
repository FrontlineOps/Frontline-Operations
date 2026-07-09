/*
 * Function: FLO_fnc_gtnMonitor
 * Author: Frontline Operations Development Group
 * 
 * Description:
 * Goal Task Network Monitor - Monitors plan execution and triggers replanning.
 * Detects significant world state changes, task failures, and opportunities.
 * Implements replan throttling to prevent excessive replanning.
 *
 * Arguments:
 * 0: Planner Reference <HASHMAP> - The GTN planner object
 * 1: World State Reference <HASHMAP> - The world state object
 *
 * Return Value:
 * Monitor HashMap Object <HASHMAP>
 *
 * Example:
 * private _monitor = [_planner, _worldState] call FLO_fnc_gtnMonitor;
 * _monitor call ["_checkReplanTriggers", []];
 */

params [["_planner", nil], ["_worldState", nil]];

if (isNil "_planner" || isNil "_worldState") exitWith {
    ["GTN", 1, "Monitor requires planner and world state"] call FLO_fnc_log;
    nil
};

["GTN", 3, "Initializing GTN Monitor"] call FLO_fnc_log;

private _monitor = createHashMapObject [[
    // References
    ["_planner", _planner],
    ["_worldState", _worldState],
    
    // Snapshot of world state at plan creation
    ["_planSnapshot", nil],
    
    // Current goal being pursued
    ["_currentGoal", ""],
    ["_currentGoalParams", []],
    
    // Replan throttling
    ["_lastReplanTime", 0],
    ["_minReplanInterval", 60],  // Minimum seconds between replans
    ["_replanCooldown", 30],     // Cooldown after failed replan
    
    // Trigger thresholds
    ["_casualtyThreshold", 0.2],      // 20% force loss triggers replan
    ["_objectiveChangeWeight", 10],   // Weight for objective ownership changes
    ["_assetChangeWeight", 5],        // Weight for asset availability changes
    ["_changeThreshold", 15],         // Total change score to trigger replan
    
    // Statistics
    ["_stats", createHashMapFromArray [
        ["checksPerformed", 0],
        ["replansTriggered", 0],
        ["opportunitiesDetected", 0],
        ["failuresDetected", 0]
    ]],
    
    // === SNAPSHOT MANAGEMENT ===
    
    // Take snapshot of current world state
    ["_takeSnapshot", {
        private _ws = _self get "_worldState";
        private _snapshot = _ws call ["_getSnapshot", []];
        _self set ["_planSnapshot", _snapshot];
        _snapshot
    }],
    
    // === REPLAN TRIGGER CHECKS ===
    
    // Main check function - returns true if replan needed
    ["_checkReplanTriggers", {
        private _stats = _self get "_stats";
        _stats set ["checksPerformed", (_stats get "checksPerformed") + 1];
        
        // Check throttling
        if (!(_self call ["_canReplan", []])) exitWith { false };
        
        private _ws = _self get "_worldState";
        private _snapshot = _self get "_planSnapshot";
        
        // Update world state
        _ws call ["_update", []];
        
        // Check various triggers
        private _triggers = [];
        
        // 1. Significant casualties
        if (_self call ["_checkCasualtyTrigger", []]) then {
            _triggers pushBack "CASUALTIES";
        };
        
        // 2. Objective status changes
        if (_self call ["_checkObjectiveTrigger", []]) then {
            _triggers pushBack "OBJECTIVE_CHANGE";
        };
        
        // 3. Asset availability changes
        if (_self call ["_checkAssetTrigger", []]) then {
            _triggers pushBack "ASSET_CHANGE";
        };
        
        // 4. Plan failure
        if (_self call ["_checkPlanFailure", []]) then {
            _triggers pushBack "PLAN_FAILURE";
        };
        
        // 5. Opportunity detected
        if (_self call ["_checkOpportunity", []]) then {
            _triggers pushBack "OPPORTUNITY";
        };
        
        if (_triggers isNotEqualTo []) then {
            ["GTN", 3, format["Replan triggers: %1", _triggers]] call FLO_fnc_log;
            _stats set ["replansTriggered", (_stats get "replansTriggered") + 1];
            true
        } else {
            false
        }
    }],
    
    // Check if enough time has passed since last replan
    ["_canReplan", {
        private _now = diag_tickTime;
        private _lastReplan = _self get "_lastReplanTime";
        private _minInterval = _self get "_minReplanInterval";
        
        _now - _lastReplan >= _minInterval
    }],
    
    // Check for significant casualties
    ["_checkCasualtyTrigger", {
        private _snapshot = _self get "_planSnapshot";
        if (isNil "_snapshot") exitWith { false };
        
        private _ws = _self get "_worldState";
        private _threshold = _self get "_casualtyThreshold";
        
        private _oldForces = _snapshot get "forces";
        private _newForces = _ws call ["_getForces", []];
        
        private _oldTotal = _oldForces get "totalGroups";
        private _newTotal = _newForces get "totalGroups";
        
        if (_oldTotal <= 0) exitWith { false };
        
        private _lossRatio = (_oldTotal - _newTotal) / _oldTotal;
        _lossRatio >= _threshold
    }],
    
    // Check for objective ownership changes
    ["_checkObjectiveTrigger", {
        private _snapshot = _self get "_planSnapshot";
        if (isNil "_snapshot") exitWith { false };
        
        private _ws = _self get "_worldState";
        
        private _oldObjs = _snapshot get "objectives";
        private _newObjs = _ws call ["_getObjectives", []];
        
        private _changed = false;
        {
            private _oldObj = _oldObjs getOrDefault [_x, nil];
            private _newObj = _newObjs getOrDefault [_x, nil];

            if (isNil "_oldObj" || isNil "_newObj") then { continue };

            // Owner changed
            if ((_oldObj get "owner") != (_newObj get "owner")) exitWith {
                _changed = true;
            };
        } forEach (keys _newObjs);

        _changed
    }],

    // Check for asset availability changes
    ["_checkAssetTrigger", {
        private _snapshot = _self get "_planSnapshot";
        if (isNil "_snapshot") exitWith { false };

        private _ws = _self get "_worldState";

        private _oldAssets = _snapshot get "assets";
        private _newAssets = _ws get "_supportAssets";

        // Check if key assets became available or unavailable
        private _artyChanged = (_oldAssets get "artilleryAvailable") != (_newAssets get "artilleryAvailable");
        private _casChanged = (_oldAssets get "casAvailable") != (_newAssets get "casAvailable");

        _artyChanged || _casChanged
    }],

    // Check if current plan has failed
    ["_checkPlanFailure", {
        private _planner = _self get "_planner";
        private _status = _planner call ["_getPlanStatus", []];

        if (_status == "FAILED") then {
            private _stats = _self get "_stats";
            _stats set ["failuresDetected", (_stats get "failuresDetected") + 1];
            true
        } else {
            false
        }
    }],

    // Check for opportunities (undefended objectives, weakened enemy)
    ["_checkOpportunity", {
        private _ws = _self get "_worldState";

        // Check for vulnerable objectives
        private _vulnObjs = _ws call ["_getVulnerableObjectives", []];

        if ((keys _vulnObjs) isNotEqualTo []) then {
            private _stats = _self get "_stats";
            _stats set ["opportunitiesDetected", (_stats get "opportunitiesDetected") + 1];
            true
        } else {
            false
        }
    }],

    // === REPLAN EXECUTION ===

    // Trigger a replan
    ["_triggerReplan", {
        private _planner = _self get "_planner";
        private _goal = _self get "_currentGoal";
        private _params = _self get "_currentGoalParams";

        if (_goal == "") exitWith {
            ["GTN", 1, "Cannot trigger GTN replan - current goal is unset"] call FLO_fnc_log;
            nil
        };

        ["GTN", 3, format["Triggering replan for goal: %1", _goal]] call FLO_fnc_log;

        // Record replan time
        _self set ["_lastReplanTime", diag_tickTime];

        // Take new snapshot
        _self call ["_takeSnapshot", []];

        // Replan
        _planner call ["_replan", [_goal, _params]]
    }],

    // Set the current goal being pursued
    ["_setCurrentGoal", {
        params ["_goalId", ["_params", []]];
        _self set ["_currentGoal", _goalId];
        _self set ["_currentGoalParams", _params];

        // Take initial snapshot
        _self call ["_takeSnapshot", []];
    }],

    // === CONFIGURATION ===

    ["_setThresholds", {
        params [
            ["_casualty", nil],
            ["_minInterval", nil],
            ["_changeThreshold", nil]
        ];

        if (!isNil "_casualty") then { _self set ["_casualtyThreshold", _casualty] };
        if (!isNil "_minInterval") then { _self set ["_minReplanInterval", _minInterval] };
        if (!isNil "_changeThreshold") then { _self set ["_changeThreshold", _changeThreshold] };
    }],

    // === QUERY METHODS ===

    ["_getStats", {
        _self get "_stats"
    }],

    ["_getCurrentGoal", {
        _self get "_currentGoal"
    }],

    // Debug output
    ["_debugPrint", {
        private _stats = _self get "_stats";
        private _goal = _self get "_currentGoal";
        private _lastReplan = _self get "_lastReplanTime";
        private _now = diag_tickTime;

        format[
            "GTN Monitor:\n  Goal: %1\n  Last Replan: %2s ago\n  Checks: %3, Replans: %4, Opportunities: %5, Failures: %6",
            _goal,
            round(_now - _lastReplan),
            _stats get "checksPerformed",
            _stats get "replansTriggered",
            _stats get "opportunitiesDetected",
            _stats get "failuresDetected"
        ]
    }]
]];

["GTN", 3, "GTN Monitor initialized"] call FLO_fnc_log;

_monitor
