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
        Creates FLO_Logistics_Network global object

    Public Methods:
        getStats: Returns replacement statistics
        forceCheck: Manually trigger replacement check
        serialize: Returns HashMap for saving
*/

if (!isServer) exitWith {};

if (isNil "FLO_Logistics_Network") then {
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

        // ========================================
        // STATE PROPERTIES
        // ========================================
        ["_initialComposition", nil],
        ["_lastUpdate", 0],
        ["_stats", nil],  // Track replacements made
        ["_enabled", true],
        ["_lastReinforcementTarget", ""],
        ["_managedSide", east],
        ["_managedSideKey", "EAST"],
        ["_enemySide", west],

        // ========================================
        // CONSTRUCTOR
        // ========================================
        ["#create", {
            // Check for saved game data
            private _savedState = nil;
            if (!isNil "FLO_SavedGameData") then {
                _savedState = FLO_SavedGameData getOrDefault ["logisticsNetwork", nil];
            };

            if (!isNil "_savedState" && {_savedState isEqualType createHashMap}) then {
                // Restore from save
                _self set ["_initialComposition", _savedState getOrDefault ["initialComposition", createHashMap]];
                _self set ["_stats", _savedState getOrDefault ["stats", createHashMapFromArray [
                    ["totalReplacements", 0],
                    ["resourcesSpent", 0],
                    ["byType", createHashMap]
                ]]];
                _self set ["_lastReinforcementTarget", _savedState getOrDefault ["lastReinforcementTarget", ""]];
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
                _self set ["_lastUpdate", time];
            };

            // Start the main loop
            _self call ["_startMainLoop", []];
        }],

        // ========================================
        // PRIVATE METHODS
        // ========================================

        ["_sideKeyFor", {
            params ["_side"];
            if (_side isEqualTo east) exitWith { "EAST" };
            if (_side isEqualTo west) exitWith { "WEST" };
            "EAST"
        }],

        // Managed side is the AI/opposition side (opposite of active player side)
        ["_refreshManagedSide", {
            private _playerSide = missionNamespace getVariable ["FLO_ActivePlayerSide", sideUnknown];
            private _managedSide = if (_playerSide isEqualTo east) then {
                west
            } else {
                if (_playerSide isEqualTo west) then { east } else { east }
            };
            private _enemySide = if (_managedSide isEqualTo east) then { west } else { east };
            private _sideKey = _self call ["_sideKeyFor", [_managedSide]];

            _self set ["_managedSide", _managedSide];
            _self set ["_managedSideKey", _sideKey];
            _self set ["_enemySide", _enemySide];
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

            (keys _groups findIf {
                private _gData = _groups get _x;
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
            params ["_candidates", ["_groupType", "infantry"]];
            if (count _candidates == 0) exitWith { "" };
            
            // Variety Filter: Avoid last target if possible
            private _lastTarget = _self get "_lastReinforcementTarget";
            private _available = +_candidates;

            if (_groupType isEqualTo "static_aa") then {
                _available = _available select { !(_self call ["_objectiveHasStaticAA", [_x]]) };
            };
            if (count _available == 0) exitWith { "" };
            
            if (count _available > 1 && {_lastTarget in _available}) then {
                _available = _available - [_lastTarget];
            };
            
            //Priority Sorting using FLO_Objectives priority field
            private _bestScore = -1;
            private _bestCandidates = [];
            
            {
                private _objId = _x;
                private _objData = FLO_Objectives get _objId;
                private _score = _objData get "priority";
                
                if (_groupType isEqualTo "static_aa") then {
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
                };
                
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
        }],

        // Find best spawn position (map edge or rear objective)
        ["_findSpawnPosition", {
            params [["_useMapEdge", true]];
            private _managedSide = _self get "_managedSide";

            // Try map edge first using transport system
            if (_useMapEdge) then {
                private _edgePos = [] call FLO_fnc_transportGetBestEdgeSpawnPos;
                if !(_edgePos isEqualTo [0,0,0]) exitWith { _edgePos };
            };

            // Fallback: Find OPFOR objective farthest from players
            if (isNil "FLO_Objectives") exitWith { [0,0,0] };

            private _opforObjs = (keys FLO_Objectives) select {
                ((FLO_Objectives get _x) getOrDefault ["owner", east]) isEqualTo _managedSide
            };

            if (count _opforObjs == 0) exitWith { [] };

            // Sort by distance from players (farthest first)
            private _sorted = [_opforObjs, [], {
                private _pos = (FLO_Objectives get _x) get "position";
                private _totalDist = 0;
                { _totalDist = _totalDist + (_pos distance2D _x); } forEach allPlayers;
                -_totalDist
            }, "ASCEND"] call BIS_fnc_sortBy;

            (FLO_Objectives get (_sorted select 0)) get "position"
        }],

        // Find objectives that need reinforcement (under BLUFOR pressure)
        ["_findReinforcementTargets", {
            if (isNil "FLO_Objectives") exitWith { [] };

            private _detectRange = _self get "BLUFOR_DETECT_RANGE";
            private _managedSide = _self get "_managedSide";
            private _enemySide = _self get "_enemySide";

            private _opforObjs = (keys FLO_Objectives) select {
                ((FLO_Objectives get _x) getOrDefault ["owner", east]) isEqualTo _managedSide
            };

            // Filter to objectives with nearby opposing players
            _opforObjs select {
                private _pos = (FLO_Objectives get _x) get "position";
                private _nearbyBlufor = allPlayers select {
                    side _x == _enemySide && {_x distance2D _pos < _detectRange}
                };
                count _nearbyBlufor > 0
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
                    [_newGroupId, _wps, true] call FLO_fnc_updateVirtualGroupWaypoints;
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
            [] spawn {
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

                FLO_Logistics_Network call ["_refreshManagedSide", []];
                ["LOGISTICS", 3, format[
                    "Managed side resolved: %1",
                    FLO_Logistics_Network get "_managedSideKey"
                ]] call FLO_fnc_log;

                // Capture initial composition if not loaded from save
                if (isNil {FLO_Logistics_Network get "_initialComposition"}) then {
                    private _comp = FLO_Logistics_Network call ["_captureInitialComposition", []];
                    FLO_Logistics_Network set ["_initialComposition", _comp];
                    ["LOGISTICS", 3, format["Captured initial composition: %1", _comp]] call FLO_fnc_log;
                };

                // Main loop
                while {true} do {
                    if (isNil "FLO_Logistics_Network") exitWith {};

                    if (FLO_Logistics_Network get "_enabled") then {
                        FLO_Logistics_Network call ["_checkAndReplace", []];
                    };

                    sleep (FLO_Logistics_Network get "CHECK_INTERVAL");
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

            // Check if we have resources
            private _resources = _self call ["_getManagedResourceObject", []];
            if (isNil "_resources") exitWith {};

            // Find reinforcement targets - managed-side objectives under player pressure
            private _targets = _self call ["_findReinforcementTargets", []];
            if (count _targets == 0) then {
                // No objectives under pressure - find managed-side objectives NOT near any player
                // This allows reinforcing rear objectives to maintain strength
                ["LOGISTICS", 3, format["Need %1 replacements but no objectives under pressure - checking rear objectives", count _needed]] call FLO_fnc_log;

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
                ["LOGISTICS", 3, "No pressure/rear objective targets for maneuver groups this cycle"] call FLO_fnc_log;
            };

            // Process replacements
            private _replaced = 0;
            {
                private _groupType = _x;
                private _cost = _groupCosts getOrDefault [_groupType, 4];
                private _targetPool = if (_groupType isEqualTo "static_aa") then {
                    _self call ["_getRearAATargets", []]
                } else {
                    _targets
                };

                if (count _targetPool == 0) then { continue };

                // Check if we can afford
                if !(_resources call ["canAfford", [_cost, "reinforcement"]]) then {
                    continue;
                };

                // Find spawn and target
                private _useMapEdge = !(_groupType isEqualTo "static_aa");
                private _spawnPos = _self call ["_findSpawnPosition", [_useMapEdge]];
                if (_spawnPos isEqualTo [0,0,0]) then { continue };

                // Select target with priority logic
                private _targetObj = _self call ["_pickBestTarget", [_targetPool, _groupType]];
                
                // Update last target to ensure variety for next selection
                if (_targetObj != "") then {
                     _self set ["_lastReinforcementTarget", _targetObj];
                };
                if (_targetObj == "") then { continue };

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
            } forEach _needed;

            if (_replaced > 0) then {
                private _stats = _self get "_stats";
                ["LOGISTICS", 3, format["Replacement cycle: %1 created | Total: %2 | Spent: %3",
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
                ["lastReinforcementTarget", _self get "_lastReinforcementTarget"]
            ]
        }]
    ];

    FLO_Logistics_Network = createHashMapObject [_logisticsClass];
    ["LOGISTICS", 3, "Logistics Network initialized"] call FLO_fnc_log;
};
