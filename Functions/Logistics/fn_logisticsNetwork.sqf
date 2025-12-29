/*
    Function: FLO_fnc_logisticsNetwork

    Description:
    OOP-based OPFOR logistics system that monitors and replaces destroyed
    virtual groups using OPFOR resources. Integrates with FLO_OPFOR_Resources
    and FLO_VirtualTransport for intelligent reinforcement spawning.

    Features:
    - Tracks initial group composition and maintains force strength
    - Spawns reinforcements from map edges for realism
    - Uses virtual transport for mechanized/air assault groups
    - Prioritizes objectives under BLUFOR pressure
    - Resource-gated replacement (uses OPFOR_Resources)

    Group Costs (resources):
    - infantry: 4
    - motorized: 9
    - mechanized: 12
    - armor: 16
    - helicopter: 19
    - air/jet: 24
    - artillery: 14

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
            ["artillery", 14]
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
                _self set ["_lastUpdate", time];

                ["LOGISTICS", 2, format["Restored from save: %1 total replacements",
                    (_self get "_stats") getOrDefault ["totalReplacements", 0]]] call FLO_fnc_log;
            } else {
                // Fresh start - wait and capture initial composition
                _self set ["_stats", createHashMapFromArray [
                    ["totalReplacements", 0],
                    ["resourcesSpent", 0],
                    ["byType", createHashMap]
                ]];
                _self set ["_lastUpdate", time];
            };

            // Start the main loop
            _self call ["_startMainLoop", []];
        }],

        // ========================================
        // PRIVATE METHODS
        // ========================================

        // Capture initial group composition
        ["_captureInitialComposition", {
            if (isNil "FLO_virtualGroups") exitWith { createHashMap };

            private _allGroups = FLO_virtualGroups get "_groups";
            private _composition = createHashMap;

            {
                private _groupType = _y getOrDefault ["groupType", "infantry"];
                private _side = _y getOrDefault ["side", east];

                // Only count OPFOR groups
                if (_side isEqualTo east) then {
                    _composition set [_groupType, (_composition getOrDefault [_groupType, 0]) + 1];
                };
            } forEach _allGroups;

            _composition
        }],

        // Get current group composition
        ["_getCurrentComposition", {
            if (isNil "FLO_virtualGroups") exitWith { createHashMap };

            private _allGroups = FLO_virtualGroups get "_groups";
            private _composition = createHashMap;

            {
                private _groupType = _y getOrDefault ["groupType", "infantry"];
                private _side = _y getOrDefault ["side", east];

                if (_side isEqualTo east) then {
                    _composition set [_groupType, (_composition getOrDefault [_groupType, 0]) + 1];
                };
            } forEach _allGroups;

            _composition
        }],

        // Find best spawn position (map edge or rear objective)
        ["_findSpawnPosition", {
            params [["_useMapEdge", true]];

            // Try map edge first
            if (_useMapEdge && !isNil "FLO_VirtualTransport") then {
                private _edgePos = FLO_VirtualTransport call ["_getBestEdgeSpawnPos", []];
                if !(_edgePos isEqualTo [0,0,0]) exitWith { _edgePos };
            };

            // Fallback: Find OPFOR objective farthest from players
            if (isNil "FLO_Objectives") exitWith { [0,0,0] };

            private _opforObjs = (keys FLO_Objectives) select {
                ((FLO_Objectives get _x) getOrDefault ["owner", east]) isEqualTo east
            };

            if (count _opforObjs == 0) exitWith { [0,0,0] };

            // Sort by distance from players (farthest first)
            private _sorted = [_opforObjs, [], {
                private _pos = (FLO_Objectives get _x) getOrDefault ["position", [0,0,0]];
                private _totalDist = 0;
                { _totalDist = _totalDist + (_pos distance2D _x); } forEach allPlayers;
                -_totalDist
            }, "ASCEND"] call BIS_fnc_sortBy;

            (FLO_Objectives get (_sorted select 0)) getOrDefault ["position", [0,0,0]]
        }],

        // Find objectives that need reinforcement (under BLUFOR pressure)
        ["_findReinforcementTargets", {
            if (isNil "FLO_Objectives") exitWith { [] };

            private _detectRange = _self get "BLUFOR_DETECT_RANGE";

            private _opforObjs = (keys FLO_Objectives) select {
                ((FLO_Objectives get _x) getOrDefault ["owner", east]) isEqualTo east
            };

            // Filter to objectives with nearby BLUFOR
            _opforObjs select {
                private _pos = (FLO_Objectives get _x) getOrDefault ["position", [0,0,0]];
                private _nearbyBlufor = allPlayers select {
                    side _x == west && {_x distance2D _pos < _detectRange}
                };
                count _nearbyBlufor > 0
            }
        }],

        // Create a replacement group
        ["_createReplacement", {
            params ["_groupType", "_spawnPos", "_targetObjId"];

            if (isNil "FLO_virtualGroups") exitWith { "" };

            private _targetPos = if (_targetObjId != "" && !isNil "FLO_Objectives") then {
                (FLO_Objectives getOrDefault [_targetObjId, createHashMap]) getOrDefault ["position", _spawnPos]
            } else { _spawnPos };

            // Build waypoints
            private _wps = [[_targetPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 20]];

            // Get unit count for this type
            private _unitCount = if (!isNil "FLO_fnc_getGroupTypeCount") then {
                [_groupType] call FLO_fnc_getGroupTypeCount
            } else { 6 };

            // Create the virtual group
            private _newGroupId = [_spawnPos, _groupType, nil, _targetObjId, _unitCount] call FLO_fnc_createVirtualGroup;

            if (_newGroupId != "") then {
                // Mark as reinforcing
                private _groups = FLO_virtualGroups get "_groups";
                private _groupData = _groups getOrDefault [_newGroupId, nil];
                if (!isNil "_groupData") then {
                    _groupData set ["isReinforcing", true];
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
                    {!isNil "FLO_OPFOR_Resources"}
                };

                // Small delay to let groups spawn
                sleep 10;

                // Capture initial composition if not loaded from save
                if (isNil {FLO_Logistics_Network get "_initialComposition"}) then {
                    private _comp = FLO_Logistics_Network call ["_captureInitialComposition", []];
                    FLO_Logistics_Network set ["_initialComposition", _comp];
                    ["LOGISTICS", 2, format["Captured initial composition: %1", _comp]] call FLO_fnc_log;
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
            if (isNil "FLO_OPFOR_Resources") exitWith {};

            // Find reinforcement targets
            private _targets = _self call ["_findReinforcementTargets", []];
            if (count _targets == 0) then {
                // No objectives under pressure, skip this cycle
                ["LOGISTICS", 3, format["Need %1 replacements but no objectives under pressure", count _needed]] call FLO_fnc_log;
                // Still allow replacement to random OPFOR objective
                private _opforObjs = (keys FLO_Objectives) select {
                    ((FLO_Objectives get _x) getOrDefault ["owner", east]) isEqualTo east
                };
                if (count _opforObjs > 0) then {
                    _targets = [selectRandom _opforObjs];
                };
            };

            if (count _targets == 0) exitWith {};

            // Process replacements
            private _replaced = 0;
            {
                private _groupType = _x;
                private _cost = _groupCosts getOrDefault [_groupType, 4];

                // Check if we can afford
                if !(FLO_OPFOR_Resources call ["canAfford", [_cost, "reinforcement"]]) then {
                    continue;
                };

                // Find spawn and target
                private _spawnPos = _self call ["_findSpawnPosition", [true]];
                if (_spawnPos isEqualTo [0,0,0]) then { continue };

                private _targetObj = selectRandom _targets;

                // Try to spend resources
                if (FLO_OPFOR_Resources call ["spendResources", [_cost, "reinforcement"]]) then {
                    private _newId = _self call ["_createReplacement", [_groupType, _spawnPos, _targetObj]];

                    if (_newId != "") then {
                        _self call ["_recordReplacement", [_groupType, _cost]];
                        _replaced = _replaced + 1;

                        ["LOGISTICS", 2, format["Created %1 reinforcement -> %2 (cost: %3)",
                            _groupType, _targetObj, _cost]] call FLO_fnc_log;
                    };
                };
            } forEach _needed;

            if (_replaced > 0) then {
                private _stats = _self get "_stats";
                ["LOGISTICS", 2, format["Replacement cycle: %1 created | Total: %2 | Spent: %3",
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
            ["LOGISTICS", 2, format["Logistics network %1", if (_enabled) then {"enabled"} else {"disabled"}]] call FLO_fnc_log;
        }],

        // Serialize state for saving
        ["serialize", {
            createHashMapFromArray [
                ["initialComposition", _self get "_initialComposition"],
                ["stats", _self get "_stats"]
            ]
        }]
    ];

    FLO_Logistics_Network = createHashMapObject [_logisticsClass];
    ["LOGISTICS", 2, "Logistics Network initialized"] call FLO_fnc_log;
};