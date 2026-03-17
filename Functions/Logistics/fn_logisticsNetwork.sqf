/*
    Function: FLO_fnc_logisticsNetwork

    Description:
    OOP-based logistics system that monitors and replaces destroyed
    virtual groups using side-scoped resources. Integrates with
    FLO_SideResources and FLO_VirtualTransport for reinforcement spawning.

    Features:
    - Tracks initial group composition and maintains force strength
    - Spawns reinforcements from map edges for realism
    - Uses virtual transport for mechanized/air assault groups
    - Prioritizes objectives under player-side pressure
    - Resource-gated replacement (uses SideResources)
    - Static AA replacements with dedicated rear-area deployment logic

    Group Costs (resources):
    - infantry: 4
    - motorized: 9
    - mechanized: 12
    - armor: 16
    - helicopter: 19
    - air/jet: 24
    - artillery: 14
    - static_aa: 18

    Parameter(s):
        None (self-initializing)

    Returns:
        Creates FLO_Logistics_Networks side-context map

    Public Methods:
        getStats: Returns replacement statistics
        forceCheck: Manually trigger replacement check
        serialize: Returns HashMap for saving
*/

if (!isServer) exitWith {};

private _fnc_sideKey = {
    params ["_side"];
    private _ctx = [_side] call FLO_fnc_gtnSideContext;
    _ctx get "sideKey"
};

if (isNil "FLO_Logistics_Networks" || {count (keys FLO_Logistics_Networks) == 0}) then {
    private _logisticsClass = [
        ["#type", "LogisticsNetwork"],

        // ========================================
        // CLASS CONSTANTS
        // ========================================

        // Resource cost per group type
        ["GROUP_COSTS", createHashMapFromArray [
            ["infantry", 4],
            ["motorized", 9],
            ["mechanized", 12],
            ["armor", 16],
            ["helicopter", 19],
            ["air", 24],
            ["jet", 24],
            ["artillery", 14],
            ["static_aa", 18]
        ]],

        ["CHECK_INTERVAL", 300],      // 5 minutes between checks
        ["BLUFOR_DETECT_RANGE", 2000], // Range to detect BLUFOR pressure
        ["DISPATCH_MIN_INTERVAL", 300], // 5 minutes
        ["DISPATCH_MAX_INTERVAL", 600], // 10 minutes
        ["DISPATCH_BATCH_MIN", 1],      // Spawn only a few groups per dispatch
        ["DISPATCH_BATCH_MAX", 3],

        // ========================================
        // STATE PROPERTIES
        // ========================================
        ["_initialComposition", nil],
        ["_lastUpdate", 0],
        ["_stats", nil],  // Track replacements made
        ["_enabled", true],
        ["_lastReinforcementTarget", ""],
        ["_reinforcementTargetCycle", []],
        ["_reinforcementCycleIndex", 0],
        ["_sideContext", sideUnknown],
        ["_managedSide", east],
        ["_managedSideKey", "EAST"],
        ["_enemySide", west],
        ["_edgeSpawnRotation", ["NORTH", "SOUTH", "EAST", "WEST"]],
        ["_edgeSpawnIndex", 0],
        ["_lastSpawnEdge", ""],
        ["_reinforcementQueue", []],
        ["_nextDispatchAt", 0],

        // ========================================
        // CONSTRUCTOR
        // ========================================
        ["#create", {
            params [["_sideContext", sideUnknown], ["_savedStateOverride", nil]];

            if (_sideContext in [east, west]) then {
                _self set ["_sideContext", _sideContext];
                _self call ["_setManagedSide", [_sideContext]];
            } else {
                _self call ["_refreshManagedSide", []];
            };

            private _savedState = _savedStateOverride;

            if (!isNil "_savedState" && {_savedState isEqualType createHashMap}) then {
                // Restore from save
                _self set ["_initialComposition", _savedState getOrDefault ["initialComposition", createHashMap]];
                _self set ["_stats", _savedState getOrDefault ["stats", createHashMapFromArray [
                    ["totalReplacements", 0],
                    ["resourcesSpent", 0],
                    ["byType", createHashMap]
                ]]];
                _self set ["_lastReinforcementTarget", _savedState getOrDefault ["lastReinforcementTarget", ""]];
                _self set ["_reinforcementTargetCycle", _savedState getOrDefault ["reinforcementTargetCycle", []]];
                _self set ["_reinforcementCycleIndex", _savedState getOrDefault ["reinforcementCycleIndex", 0]];
                _self set ["_edgeSpawnIndex", _savedState getOrDefault ["edgeSpawnIndex", 0]];
                _self set ["_lastSpawnEdge", _savedState getOrDefault ["lastSpawnEdge", ""]];
                _self set ["_reinforcementQueue", _savedState getOrDefault ["reinforcementQueue", []]];
                private _savedNextDispatchAt = _savedState getOrDefault ["nextDispatchAt", -1];
                private _maxAllowedDelay = _self get "DISPATCH_MAX_INTERVAL";
                if (_savedNextDispatchAt > time && {(_savedNextDispatchAt - time) <= _maxAllowedDelay}) then {
                    _self set ["_nextDispatchAt", _savedNextDispatchAt];
                } else {
                    _self set ["_nextDispatchAt", time + ((_self get "DISPATCH_MIN_INTERVAL") + random ((_self get "DISPATCH_MAX_INTERVAL") - (_self get "DISPATCH_MIN_INTERVAL")))];
                };
                _self set ["_lastUpdate", time];

                ["LOGISTICS", 3, format["Restored from save: %1 total replacements",
                    (_self get "_stats") getOrDefault ["totalReplacements", 0]]] call FLO_fnc_log;
            } else {
                // Fresh start - wait and capture initial composition
                _self set ["_stats", createHashMapFromArray [
                    ["totalReplacements", 0],
                    ["resourcesSpent", 0],
                    ["byType", createHashMap]
                ]];
                _self set ["_lastReinforcementTarget", ""];
                _self set ["_reinforcementTargetCycle", []];
                _self set ["_reinforcementCycleIndex", 0];
                _self set ["_edgeSpawnIndex", 0];
                _self set ["_lastSpawnEdge", ""];
                _self set ["_reinforcementQueue", []];
                _self set ["_nextDispatchAt", time + ((_self get "DISPATCH_MIN_INTERVAL") + random ((_self get "DISPATCH_MAX_INTERVAL") - (_self get "DISPATCH_MIN_INTERVAL")))];
                _self set ["_lastUpdate", time];
            };

            // Start the main loop
            _self call ["_startMainLoop", []];
        }],

        // ========================================
        // PRIVATE METHODS
        // ========================================

        ["_setManagedSide", {
            params ["_managedSide"];
            private _ctx = [_managedSide] call FLO_fnc_gtnSideContext;
            _self set ["_managedSide", _ctx get "ownSide"];
            _self set ["_managedSideKey", _ctx get "sideKey"];
            _self set ["_enemySide", _ctx get "enemySide"];
        }],

        // Managed side is the AI/opposition side (opposite of active player side)
        ["_refreshManagedSide", {
            private _context = _self get "_sideContext";
            if (_context in [east, west]) exitWith {
                _self call ["_setManagedSide", [_context]];
            };

            private _playerSide = missionNamespace getVariable ["FLO_ActivePlayerSide", sideUnknown];
            private _managedSide = if (_playerSide isEqualTo east) then { west } else { east };
            _self call ["_setManagedSide", [_managedSide]];
        }],

        ["_getManagedResourceObject", {
            if (isNil "FLO_SideResources") exitWith { nil };
            private _sideKey = _self get "_managedSideKey";
            FLO_SideResources get _sideKey
        }],

        ["_objectiveHasStaticAA", {
            params ["_objectiveId"];
            private _managedSide = _self get "_managedSide";
            private _groups = FLO_virtualGroups get "_groups";

            (values _groups findIf {
                private _gData = _x;
                (_gData get "groupType") isEqualTo "static_aa"
                && {(_gData get "side") isEqualTo _managedSide}
                && {(_gData get "unitCount") > 0}
                && {(_gData get "homeObjective") isEqualTo _objectiveId}
            }) != -1
        }],

        // Static AA should deploy in rear/midline, not at frontline objectives.
        ["_getRearAATargets", {
            if (isNil "FLO_Objectives") exitWith { [] };

            private _managedSide = _self get "_managedSide";
            private _enemySide = _self get "_enemySide";
            private _objectives = keys FLO_Objectives;

            private _enemyObjectives = _objectives select {
                ((FLO_Objectives get _x) get "owner") isEqualTo _enemySide
            };
            if (count _enemyObjectives == 0) exitWith { [] };

            private _minEnemyDistance = 1500;
            private _maxEnemyDistance = 3000;
            private _targets = [];

            {
                private _objId = _x;
                private _objData = FLO_Objectives get _objId;
                if ((_objData get "owner") != _managedSide) then { continue };
                if (_self call ["_objectiveHasStaticAA", [_objId]]) then { continue };

                private _objPos = _objData get "position";
                private _nearestEnemyDist = 1e12;

                {
                    private _enemyPos = (FLO_Objectives get _x) get "position";
                    private _dist = _objPos distance2D _enemyPos;
                    if (_dist < _nearestEnemyDist) then { _nearestEnemyDist = _dist; };
                } forEach _enemyObjectives;

                if (_nearestEnemyDist >= _minEnemyDistance && {_nearestEnemyDist <= _maxEnemyDistance}) then {
                    _targets pushBack _objId;
                };
            } forEach _objectives;

            _targets
        }],

        // Capture initial group composition
        ["_captureInitialComposition", {
            if (isNil "FLO_virtualGroups") exitWith { createHashMap };
            private _managedSide = _self get "_managedSide";

            private _allGroups = FLO_virtualGroups get "_groups";
            private _composition = createHashMap;

            {
                private _groupType = _y getOrDefault ["groupType", "infantry"];
                private _side = _y getOrDefault ["side", east];

                if (_side isEqualTo _managedSide) then {
                    _composition set [_groupType, (_composition getOrDefault [_groupType, 0]) + 1];
                };
            } forEach _allGroups;

            _composition
        }],

        // Get current group composition
        ["_getCurrentComposition", {
            if (isNil "FLO_virtualGroups") exitWith { createHashMap };
            private _managedSide = _self get "_managedSide";

            private _allGroups = FLO_virtualGroups get "_groups";
            private _composition = createHashMap;

            {
                private _groupType = _y getOrDefault ["groupType", "infantry"];
                private _side = _y getOrDefault ["side", east];

                if (_side isEqualTo _managedSide) then {
                    _composition set [_groupType, (_composition getOrDefault [_groupType, 0]) + 1];
                };
            } forEach _allGroups;

            _composition
        }],

        // Pick best target using priority and variety logic
        ["_pickBestTarget", {
            params ["_candidates", ["_groupType", "infantry"], ["_spawnPos", []]];
            if (count _candidates == 0) exitWith { "" };
            
            // Variety Filter: Avoid last target if possible
            private _lastTarget = _self get "_lastReinforcementTarget";
            private _available = +_candidates;

            if (_groupType isEqualTo "static_aa") then {
                _available = _available select { !(_self call ["_objectiveHasStaticAA", [_x]]) };
            };
            if (count _available == 0) exitWith { "" };

            // Static AA keeps priority-based targeting.
            if (_groupType isEqualTo "static_aa") exitWith {
                if (count _available > 1 && {_lastTarget in _available}) then {
                    _available = _available - [_lastTarget];
                };

                private _bestScore = -1;
                private _bestCandidates = [];
                {
                    private _objId = _x;
                    private _objData = FLO_Objectives get _objId;
                    private _score = _objData get "priority";
                    private _enemySide = _self get "_enemySide";
                    private _objPos = _objData get "position";
                    private _nearestEnemyDist = 1e12;

                    {
                        private _enemyData = FLO_Objectives get _x;
                        if ((_enemyData get "owner") != _enemySide) then { continue };
                        private _dist = _objPos distance2D (_enemyData get "position");
                        if (_dist < _nearestEnemyDist) then { _nearestEnemyDist = _dist; };
                    } forEach (keys FLO_Objectives);

                    _score = _score + ((_nearestEnemyDist min 6000) * 0.15);

                    if (_score > _bestScore) then {
                        _bestScore = _score;
                        _bestCandidates = [_objId];
                    } else {
                        if (_score == _bestScore) then {
                            _bestCandidates pushBack _objId;
                        };
                    };
                } forEach _available;

                selectRandom _bestCandidates
            };

            // Maneuver reinforcements: nearest-target rotation queue (max 6), skip last selected.
            private _anchorPos = if (_spawnPos isEqualType [] && {count _spawnPos >= 2}) then {
                _spawnPos
            } else {
                private _objPos = (FLO_Objectives get (_available select 0)) get "position";
                _objPos
            };

            private _scored = [];
            {
                private _objPos = (FLO_Objectives get _x) get "position";
                _scored pushBack [(_objPos distance2D _anchorPos), _x];
            } forEach _available;
            _scored sort true;

            private _ordered = _scored apply { _x select 1 };
            if (count _ordered > 6) then {
                _ordered resize 6;
            };

            private _cycle = _self get "_reinforcementTargetCycle";
            if ((count _cycle) != (count _ordered) || {str _cycle != str _ordered}) then {
                _cycle = +_ordered;
                _self set ["_reinforcementTargetCycle", _cycle];
                _self set ["_reinforcementCycleIndex", 0];
            };

            if (count _cycle == 0) exitWith { "" };

            private _idx = _self get "_reinforcementCycleIndex";
            if (_idx >= count _cycle) then {
                _idx = 0;
            };

            private _selected = _cycle select _idx;
            if ((count _cycle) > 1 && {_selected isEqualTo _lastTarget}) then {
                _idx = (_idx + 1) mod (count _cycle);
                _selected = _cycle select _idx;
            };

            _self set ["_reinforcementCycleIndex", (_idx + 1) mod (count _cycle)];
            _selected
        }],

        ["_nextPreferredSpawnEdge", {
            private _edges = _self get "_edgeSpawnRotation";
            if (count _edges == 0) exitWith { "" };

            private _idx = _self get "_edgeSpawnIndex";
            if (_idx >= count _edges) then {
                _idx = 0;
            };

            private _edge = _edges select _idx;
            _self set ["_edgeSpawnIndex", (_idx + 1) mod (count _edges)];
            _self set ["_lastSpawnEdge", _edge];
            _edge
        }],

        // Find best spawn position (map edge or rear objective)
        ["_findSpawnPosition", {
            params [["_useMapEdge", true]];
            private _managedSide = _self get "_managedSide";

            // Try map edge first using transport system
            if (_useMapEdge) then {
                private _preferredEdge = _self call ["_nextPreferredSpawnEdge", []];
                private _edgePos = [_preferredEdge] call FLO_fnc_transportGetBestEdgeSpawnPos;
                if (_edgePos isEqualTo [0,0,0]) then {
                    _edgePos = [] call FLO_fnc_transportGetBestEdgeSpawnPos;
                };
                if !(_edgePos isEqualTo [0,0,0]) exitWith { _edgePos };
            };

            // Fallback: Find OPFOR objective farthest from players
            if (isNil "FLO_Objectives") exitWith { [0,0,0] };

            private _opforObjs = (keys FLO_Objectives) select {
                ((FLO_Objectives get _x) getOrDefault ["owner", east]) isEqualTo _managedSide
            };

            if (count _opforObjs == 0) exitWith { [] };

            // Select by max total distance from players (single pass).
            private _bestObjId = "";
            private _bestScore = -1e12;
            {
                private _objId = _x;
                private _pos = (FLO_Objectives get _objId) get "position";
                private _totalDist = 0;
                { _totalDist = _totalDist + (_pos distance2D _x); } forEach allPlayers;
                if (_totalDist > _bestScore) then {
                    _bestScore = _totalDist;
                    _bestObjId = _objId;
                };
            } forEach _opforObjs;

            if (_bestObjId == "") exitWith { [] };
            (FLO_Objectives get _bestObjId) get "position"
        }],

        // Find objectives that need reinforcement (under enemy pressure)
        ["_findReinforcementTargets", {
            if (isNil "FLO_Objectives") exitWith { [] };

            private _detectRange = _self get "BLUFOR_DETECT_RANGE";
            private _managedSide = _self get "_managedSide";
            private _enemySide = _self get "_enemySide";

            private _opforObjs = (keys FLO_Objectives) select {
                ((FLO_Objectives get _x) getOrDefault ["owner", east]) isEqualTo _managedSide
            };

            // Filter to objectives with nearby opposing forces
            _opforObjs select {
                private _pos = (FLO_Objectives get _x) get "position";
                private _nearUnits = _pos nearEntities [["Man", "Car", "Tank", "LandVehicle", "Air", "Ship"], _detectRange];
                private _enemyNearby = _nearUnits findIf {
                    alive _x && {
                        private _uSide = side _x;
                        if (isPlayer _x) then {
                            _uSide = side group _x;
                        };
                        _uSide isEqualTo _enemySide
                    }
                };
                if (_enemyNearby == -1) then {
                    _enemyNearby = allPlayers findIf {
                        alive _x &&
                        {(_x distance2D _pos) <= _detectRange} &&
                        {(side group _x) isEqualTo _enemySide}
                    };
                };
                _enemyNearby != -1
            }
        }],

        // Create a replacement group
        ["_createReplacement", {
            params ["_groupType", "_spawnPos", "_targetObjId", ["_sourceObjId", ""]];

            if (isNil "FLO_virtualGroups") exitWith { "" };
            private _managedSide = _self get "_managedSide";

            // Validate spawn position
            if !(_spawnPos isEqualType [] && {count _spawnPos >= 2} && {((_spawnPos select 0) > 100) || ((_spawnPos select 1) > 100)}) exitWith {
                ["LOGISTICS", 1, format["Invalid spawn position %1 for %2 reinforcement", _spawnPos, _groupType]] call FLO_fnc_log;
                ""
            };

            // Get and validate target position
            private _targetPos = if (_targetObjId != "" && !isNil "FLO_Objectives") then {
                private _objData = FLO_Objectives getOrDefault [_targetObjId, createHashMap];
                // Double-check that objective is still managed-side owned
                private _owner = _objData getOrDefault ["owner", east];
                if !(_owner isEqualTo _managedSide) exitWith {
                    ["LOGISTICS", 2, format["Target objective %1 no longer owned by managed side", _targetObjId]] call FLO_fnc_log;
                    []
                };
                _objData get "position"
            } else { _spawnPos };

            // Validate target position
            if !(_targetPos isEqualType [] && {count _targetPos >= 2} && {((_targetPos select 0) > 100) || ((_targetPos select 1) > 100)}) exitWith {
                ["LOGISTICS", 1, format["Invalid target position %1 for %2 reinforcement to %3", _targetPos, _groupType, _targetObjId]] call FLO_fnc_log;
                ""
            };

            // Get unit count for this type
            private _unitCount = if (!isNil "FLO_fnc_getGroupTypeCount") then {
                [_groupType, _managedSide] call FLO_fnc_getGroupTypeCount
            } else { 6 };

            // Create the virtual group
            private _newGroupId = [_spawnPos, _groupType, nil, _targetObjId, _unitCount, _managedSide] call FLO_fnc_createVirtualGroup;

            if (_newGroupId != "") then {
                // Mark as reinforcing
                private _groups = FLO_virtualGroups get "_groups";
                private _groupData = _groups getOrDefault [_newGroupId, nil];
                private _wps = [[_targetPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 20]];

                if (!isNil "_groupData") then {
                    _groupData set ["isReinforcing", true];
                    _groupData set ["onMission", true];
                    _groupData set ["currentOrder", "REINFORCE"];

                    if (_groupType isEqualTo "static_aa") then {
                        if (_sourceObjId == "") then {
                            _sourceObjId = [_spawnPos, _managedSide] call FLO_fnc_getNearestObjective;
                        };

                        _groupData set ["forceVirtual", true];
                        _groupData set ["alwaysActive", false];
                        _groupData set ["noWaypoints", false];
                        _groupData set ["currentOrder", "AA_DEPLOY"];
                        _groupData set ["aaDeployState", "MOVING"];
                        _groupData set ["aaDeployTargetPos", _targetPos];
                        _groupData set ["aaDeployTargetObjective", _targetObjId];
                        _groupData set ["isStrategicAA", true];
                        _groupData set ["onMission", true];
                        _groupData set ["homeObjective", _targetObjId];

                        private _path = if (_sourceObjId != "" && {_targetObjId != ""} && {_sourceObjId != _targetObjId}) then {
                            [_sourceObjId, _targetObjId] call FLO_fnc_getObjectivePath
                        } else { [] };

                        _wps = [];
                        {
                            _wps pushBack [_x, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 80];
                        } forEach _path;
                        _wps pushBack [_targetPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 80];
                    };
                };

                // Set waypoints
                if (!isNil "FLO_fnc_updateVirtualGroupWaypoints") then {
                    private _usesRoadRouting = !(_groupType in ["helicopter", "air", "jet", "boat", "naval", "submarine"]);
                    private _allowTrails = _groupType in ["infantry"];
                    [_newGroupId, _wps, _usesRoadRouting, _allowTrails] call FLO_fnc_updateVirtualGroupWaypoints;
                };
            };

            _newGroupId
        }],

        // Update statistics
        ["_recordReplacement", {
            params ["_groupType", "_cost"];

            private _stats = _self get "_stats";
            _stats set ["totalReplacements", (_stats getOrDefault ["totalReplacements", 0]) + 1];
            _stats set ["resourcesSpent", (_stats getOrDefault ["resourcesSpent", 0]) + _cost];

            private _byType = _stats getOrDefault ["byType", createHashMap];
            _byType set [_groupType, (_byType getOrDefault [_groupType, 0]) + 1];
            _stats set ["byType", _byType];
        }],

        // Main update loop
        ["_startMainLoop", {
            [_self] spawn {
                params ["_net"];

                // Wait for systems to initialize
                waitUntil {
                    sleep 1;
                    !isNil "FLO_virtualGroups" &&
                    {!isNil "InitializationOG"} &&
                    {InitializationOG} &&
                    {!isNil "FLO_SideResources"}
                };

                // Small delay to let groups spawn
                sleep 10;

                _net call ["_refreshManagedSide", []];
                ["LOGISTICS", 3, format[
                    "Logistics side context resolved: %1",
                    _net get "_managedSideKey"
                ]] call FLO_fnc_log;

                // Capture initial composition if not loaded from save
                if (isNil {_net get "_initialComposition"}) then {
                    private _comp = _net call ["_captureInitialComposition", []];
                    _net set ["_initialComposition", _comp];
                    ["LOGISTICS", 3, format["Captured initial composition: %1", _comp]] call FLO_fnc_log;
                };

                // Main loop
                while {true} do {
                    if (isNil "_net") exitWith {};

                    if (_net get "_enabled") then {
                        _net call ["_checkAndReplace", []];
                    };

                    sleep (_net get "CHECK_INTERVAL");
                };
            };
        }],

        // Core replacement logic
        ["_checkAndReplace", {
            _self call ["_refreshManagedSide", []];
            private _managedSide = _self get "_managedSide";

            private _initialComp = _self get "_initialComposition";
            if (isNil "_initialComp") exitWith {};

            private _currentComp = _self call ["_getCurrentComposition", []];
            private _groupCosts = _self get "GROUP_COSTS";

            // Find what's missing
            private _needed = [];
            {
                private _type = _x;
                private _target = _initialComp getOrDefault [_type, 0];
                private _current = _currentComp getOrDefault [_type, 0];

                if (_current < _target) then {
                    for "_i" from 1 to (_target - _current) do {
                        _needed pushBack _type;
                    };
                };
            } forEach (keys _initialComp);

            if (count _needed == 0) exitWith {
                ["LOGISTICS", 3, "All group types at target strength"] call FLO_fnc_log;
            };

            // Rebuild pending queue from current deficits while preserving existing order.
            private _queue = _self get "_reinforcementQueue";
            private _neededCounts = createHashMap;
            {
                _neededCounts set [_x, (_neededCounts getOrDefault [_x, 0]) + 1];
            } forEach _needed;

            private _rebuiltQueue = [];
            {
                private _remain = _neededCounts getOrDefault [_x, 0];
                if (_remain > 0) then {
                    _rebuiltQueue pushBack _x;
                    _neededCounts set [_x, _remain - 1];
                };
            } forEach _queue;

            {
                private _type = _x;
                private _missingCount = _neededCounts get _type;
                for "_i" from 1 to _missingCount do {
                    _rebuiltQueue pushBack _type;
                };
            } forEach (keys _neededCounts);

            _queue = _rebuiltQueue;
            _self set ["_reinforcementQueue", _queue];

            if (count _queue == 0) exitWith {
                ["LOGISTICS", 3, "No pending reinforcements after queue reconciliation"] call FLO_fnc_log;
            };

            private _nextDispatchAt = _self get "_nextDispatchAt";
            if (time < _nextDispatchAt) exitWith {
                ["LOGISTICS", 3, format["Reinforcement queue pending: %1 groups | next dispatch in %2s",
                    count _queue,
                    round (_nextDispatchAt - time)
                ]] call FLO_fnc_log;
                _self set ["_lastUpdate", time];
            };

            // Check resources only when dispatch window opens.
            private _resources = _self call ["_getManagedResourceObject", []];
            if (isNil "_resources") exitWith {};

            // Find reinforcement targets - managed-side objectives under player pressure
            private _targets = _self call ["_findReinforcementTargets", []];
            if (count _targets == 0) then {
                // No objectives under pressure - find managed-side objectives NOT near any player
                // This allows reinforcing rear objectives to maintain strength
                ["LOGISTICS", 3, format["Queue dispatch: no objectives under pressure - checking rear objectives (%1 pending)", count _queue]] call FLO_fnc_log;

                private _opforObjs = (keys FLO_Objectives) select {
                    private _objData = FLO_Objectives get _x;
                    private _owner = _objData getOrDefault ["owner", east];
                    private _pos = _objData get "position";

                    _owner isEqualTo _managedSide &&
                    {
                        // Not near any player (rear objectives only)
                        private _nearPlayer = false;
                        { if (_x distance2D _pos < 3000) exitWith { _nearPlayer = true }; } forEach allPlayers;
                        !_nearPlayer
                    }
                };

                if (count _opforObjs > 0) then {
                    _targets = [selectRandom _opforObjs];
                };
            };

            if (count _targets == 0) then {
                ["LOGISTICS", 3, "No pressure/rear objective targets for maneuver reinforcement dispatch"] call FLO_fnc_log;
            };

            private _batchMin = _self get "DISPATCH_BATCH_MIN";
            private _batchMax = _self get "DISPATCH_BATCH_MAX";
            private _batchSize = _batchMin + floor random ((_batchMax - _batchMin) + 1);
            if (_batchSize > count _queue) then {
                _batchSize = count _queue;
            };

            private _replaced = 0;
            private _attempted = 0;

            for "_i" from 1 to _batchSize do {
                if (count _queue == 0) exitWith {};

                private _groupType = _queue deleteAt 0;
                _attempted = _attempted + 1;

                private _cost = _groupCosts getOrDefault [_groupType, 4];
                private _targetPool = if (_groupType isEqualTo "static_aa") then {
                    _self call ["_getRearAATargets", []]
                } else {
                    _targets
                };

                if (count _targetPool == 0) then {
                    _queue pushBack _groupType;
                    continue;
                };

                // Check if we can afford
                if !(_resources call ["canAfford", [_cost, "reinforcement"]]) then {
                    _queue pushBack _groupType;
                    continue;
                };

                // Find spawn and target
                private _useMapEdge = !(_groupType isEqualTo "static_aa");
                private _spawnPos = _self call ["_findSpawnPosition", [_useMapEdge]];
                if (_spawnPos isEqualTo [0,0,0]) then {
                    _queue pushBack _groupType;
                    continue;
                };

                // Select target with priority logic
                private _targetObj = _self call ["_pickBestTarget", [_targetPool, _groupType, _spawnPos]];
                if (_targetObj == "") then {
                    _queue pushBack _groupType;
                    continue;
                };

                // Update last target to ensure variety for next selection
                _self set ["_lastReinforcementTarget", _targetObj];

                // Try to spend resources
                if (_resources call ["spendResources", [_cost, "reinforcement"]]) then {
                    private _sourceObjId = if (_groupType isEqualTo "static_aa") then {
                        [_spawnPos, _managedSide] call FLO_fnc_getNearestObjective
                    } else { "" };
                    private _newId = _self call ["_createReplacement", [_groupType, _spawnPos, _targetObj, _sourceObjId]];

                    if (_newId != "") then {
                        _self call ["_recordReplacement", [_groupType, _cost]];
                        _replaced = _replaced + 1;

                        ["LOGISTICS", 3, format["Created %1 reinforcement -> %2 (cost: %3)",
                            _groupType, _targetObj, _cost]] call FLO_fnc_log;
                    };
                };
            };

            _self set ["_reinforcementQueue", _queue];

            private _nextInterval = (_self get "DISPATCH_MIN_INTERVAL") + random ((_self get "DISPATCH_MAX_INTERVAL") - (_self get "DISPATCH_MIN_INTERVAL"));
            _self set ["_nextDispatchAt", time + _nextInterval];

            ["LOGISTICS", 3, format["Dispatch window complete: attempted=%1 created=%2 queueRemaining=%3 nextIn=%4s",
                _attempted,
                _replaced,
                count _queue,
                round _nextInterval
            ]] call FLO_fnc_log;

            if (_replaced > 0) then {
                private _stats = _self get "_stats";
                ["LOGISTICS", 3, format["Replacement totals: %1 created | Total: %2 | Spent: %3",
                    _replaced,
                    _stats getOrDefault ["totalReplacements", 0],
                    _stats getOrDefault ["resourcesSpent", 0]]] call FLO_fnc_log;
            };

            _self set ["_lastUpdate", time];
        }],

        // ========================================
        // PUBLIC METHODS
        // ========================================

        // Get replacement statistics
        ["getStats", {
            _self get "_stats"
        }],

        // Manually trigger a replacement check
        ["forceCheck", {
            _self call ["_checkAndReplace", []];
        }],

        // Enable/disable the system
        ["setEnabled", {
            params ["_enabled"];
            _self set ["_enabled", _enabled];
            ["LOGISTICS", 3, format["Logistics network %1", if (_enabled) then {"enabled"} else {"disabled"}]] call FLO_fnc_log;
        }],

        // Serialize state for saving
        ["serialize", {
            createHashMapFromArray [
                ["initialComposition", _self get "_initialComposition"],
                ["stats", _self get "_stats"],
                ["lastReinforcementTarget", _self get "_lastReinforcementTarget"],
                ["reinforcementTargetCycle", _self get "_reinforcementTargetCycle"],
                ["reinforcementCycleIndex", _self get "_reinforcementCycleIndex"],
                ["reinforcementQueue", _self get "_reinforcementQueue"],
                ["nextDispatchAt", _self get "_nextDispatchAt"],
                ["edgeSpawnIndex", _self get "_edgeSpawnIndex"],
                ["lastSpawnEdge", _self get "_lastSpawnEdge"]
            ]
        }]
    ];

    FLO_Logistics_Networks = createHashMap;

    private _savedBySide = createHashMap;
    if (!isNil "FLO_SavedGameData" && {FLO_SavedGameData isEqualType createHashMap}) then {
        private _savedMap = FLO_SavedGameData getOrDefault ["logisticsNetworkBySide", createHashMap];
        if (_savedMap isEqualType createHashMap) then {
            _savedBySide = _savedMap;
        };
    };

    {
        private _side = _x;
        private _sideKey = [_side] call _fnc_sideKey;

        private _savedPayload = nil;
        if (_sideKey in _savedBySide) then {
            _savedPayload = _savedBySide get _sideKey;
        };

        private _net = createHashMapObject [_logisticsClass, [_side, _savedPayload]];
        FLO_Logistics_Networks set [_sideKey, _net];
    } forEach [east, west];

    ["LOGISTICS", 2, "Logistics Networks initialized for EAST/WEST contexts"] call FLO_fnc_log;
};
