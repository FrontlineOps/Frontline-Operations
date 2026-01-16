/*
    Function: FLO_fnc_opforResources

    Description:
    OOP-based OPFOR resource management system. Integrates with FLO_Objectives
    for dynamic resource generation based on controlled territory.

    Resource Generation (per 10-minute cycle):
    - Capital: 20 resources (major hub)
    - City: 12 resources (population center)
    - Marine: 10 resources (port logistics)
    - Local: 8 resources (military installation)
    - Village: 4 resources (small settlement)
    - Cluster: 2 resources (rural structures)

    Contested objectives generate 50% reduced resources.

    Spending Types & Modifiers:
    - garrison: 1.0x cost, 10 threshold
    - reinforcement: 1.0x cost, 20 threshold
    - qrf: 1.5x cost, 100 threshold
    - offensiveops: 4.0x cost, 500 threshold
    - air_support: 2.0x cost, 250 threshold
    - artillery: 3.0x cost, 150 threshold
    - transport: 0.5x cost, 15 threshold

    Parameter(s):
        None (self-initializing)

    Returns:
        Creates FLO_OPFOR_Resources global object

    Public Methods:
        getResources: Returns current resource count
        addResources: [amount] - Add resources, returns new total
        spendResources: [amount, type] - Spend with type modifier, returns bool
        canAfford: [amount, type] - Check affordability without spending
        serialize: Returns HashMap for saving
*/

if (!isServer) exitWith {};

if (isNil "FLO_OPFOR_Resources") then {
    private _resourceClass = [
        ["#type", "OPFORResources"],

        // ========================================
        // CLASS CONSTANTS
        // ========================================

        // Resource generation values by objective subtype
        ["RESOURCE_VALUES", createHashMapFromArray [
            ["capital", 10],
            ["city", 6],
            ["marine", 5],
            ["local", 4],
            ["village", 2],
            ["cluster", 1]
        ]],

        // Starting resource values by subtype (one-time calculation)
        ["STARTING_VALUES", createHashMapFromArray [
            ["capital", 50],
            ["city", 30],
            ["marine", 25],
            ["local", 20],
            ["village", 10],
            ["cluster", 5]
        ]],

        // Spending type configuration: [multiplier, threshold, efficiencyLoss]
        ["SPENDING_TYPES", createHashMapFromArray [
            ["garrison", [1.0, 10, 0.05]],
            ["reinforcement", [1.0, 20, 0.03]],
            ["qrf", [1.5, 100, 0.08]],
            ["offensiveops", [4.0, 500, 0.15]],
            ["air_support", [2.0, 250, 0.12]],
            ["artillery", [3.0, 150, 0.07]],
            ["transport", [0.5, 15, 0.02]]
        ]],

        // ========================================
        // STATE PROPERTIES
        // ========================================
        ["_resources", 0],
        ["_lastUpdate", 0],
        ["_efficiencies", nil],  // HashMap of efficiency per spending type

        // ========================================
        // CONSTRUCTOR
        // ========================================
        ["#create", {
            // Check for saved game data first
            private _savedState = nil;
            if (!isNil "FLO_SavedGameData") then {
                _savedState = FLO_SavedGameData getOrDefault ["opforResources", nil];
            };

            if (!isNil "_savedState" && {_savedState isEqualType createHashMap}) then {
                // Restore from save
                _self set ["_resources", _savedState getOrDefault ["resources", 0]];
                _self set ["_lastUpdate", time];
                _self set ["_efficiencies", _savedState getOrDefault ["efficiencies", createHashMap]];

                ["OPFOR_RES", 2, format["Restored from save: %1 resources", _self get "_resources"]] call FLO_fnc_log;
            } else {
                // Fresh start - calculate from objectives
                private _startingResources = _self call ["_calculateStartingResources", []];
                _self set ["_resources", _startingResources];
                _self set ["_lastUpdate", time];
                _self set ["_efficiencies", createHashMap];

                ["OPFOR_RES", 2, format["Fresh start: %1 resources", _startingResources]] call FLO_fnc_log;
            };

            // Start resource generation loop
            _self call ["_startGenerationLoop", []];
        }],

        // ========================================
        // PRIVATE METHODS
        // ========================================

        // Calculate starting resources from OPFOR objectives
        ["_calculateStartingResources", {
            if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) exitWith { 200 };

            private _startingValues = _self get "STARTING_VALUES";
            private _total = 0;

            {
                if ((_y getOrDefault ["owner", east]) isEqualTo east) then {
                    private _subtype = _y getOrDefault ["subtype", "cluster"];
                    _total = _total + (_startingValues getOrDefault [_subtype, 10]);
                };
            } forEach FLO_Objectives;

            _total max 100  // Minimum 100 starting resources
        }],

        // Get efficiency for a spending type (default 1.0)
        ["_getEfficiency", {
            params ["_type"];
            private _efficiencies = _self get "_efficiencies";
            if (isNil "_efficiencies") exitWith { 1.0 };
            _efficiencies getOrDefault [_type, 1.0]
        }],

        // Set efficiency for a spending type
        ["_setEfficiency", {
            params ["_type", "_value"];
            private _efficiencies = _self get "_efficiencies";
            if (isNil "_efficiencies") then {
                _efficiencies = createHashMap;
                _self set ["_efficiencies", _efficiencies];
            };
            _efficiencies set [_type, (_value max 0.2) min 1.0];
        }],

        // Start the background resource generation loop
        ["_startGenerationLoop", {
            [] spawn {
                // Wait for objectives
                waitUntil { sleep 1; !isNil "FLO_Objectives" && {count FLO_Objectives > 0} };

                private _eventCooldown = 0;

                while {true} do {
                    if (isNil "FLO_OPFOR_Resources") exitWith {};

                    private _resourceValues = FLO_OPFOR_Resources get "RESOURCE_VALUES";
                    private _totalGen = 0;
                    private _activeCount = 0;
                    private _contestedCount = 0;
                    private _globalMod = 1.0;

                    // Random events (5% chance each cycle)
                    if (time > _eventCooldown && {random 100 < 5}) then {
                        if (random 1 > 0.3) then {
                            _globalMod = 1.5;
                            ["OPFOR_RES", 2, "Supply optimization event: +50% generation"] call FLO_fnc_log;
                        } else {
                            _globalMod = 0.7;
                            ["OPFOR_RES", 2, "Supply disruption event: -30% generation"] call FLO_fnc_log;
                        };
                        _eventCooldown = time + 1800 + random 1800;
                    };

                    // Calculate generation from OPFOR objectives
                    {
                        private _data = _y;
                        if !((_data getOrDefault ["owner", east]) isEqualTo east) then { continue };

                        private _subtype = _data getOrDefault ["subtype", "cluster"];
                        private _pos = _data get "position";
                        private _baseVal = _resourceValues getOrDefault [_subtype, 2];

                        // Check if contested
                        private _nearBlufor = count ((_pos nearEntities [["Man", "Car", "Tank", "LandVehicle"], 1000]) select {
                            alive _x && {side _x == west}
                        });

                        private _contested = _nearBlufor > 0;
                        private _contestMod = if (_contested) then { 0.5 } else { 1.0 };

                        if (_contested) then { _contestedCount = _contestedCount + 1 };

                        _totalGen = _totalGen + (_baseVal * _globalMod * _contestMod);
                        _activeCount = _activeCount + 1;
                    } forEach FLO_Objectives;

                    // Add generated resources
                    _totalGen = round _totalGen;
                    if (_totalGen > 0) then {
                        FLO_OPFOR_Resources call ["addResources", [_totalGen]];
                    };

                    ["OPFOR_RES", 3, format["Gen: +%1 from %2 obj (%3 contested) | Total: %4",
                        _totalGen, _activeCount, _contestedCount,
                        FLO_OPFOR_Resources call ["getResources", []]]] call FLO_fnc_log;

                    sleep 600;  // 10 minute cycles
                };
            };
        }],

        // ========================================
        // PUBLIC METHODS
        // ========================================

        // Get current resources
        ["getResources", {
            _self get "_resources"
        }],

        // Add resources
        ["addResources", {
            params ["_amount"];
            private _current = _self get "_resources";
            private _new = _current + _amount;
            _self set ["_resources", _new];
            _self set ["_lastUpdate", time];
            _new
        }],

        // Check if can afford without spending
        ["canAfford", {
            params ["_amount", "_type"];

            private _spendingTypes = _self get "SPENDING_TYPES";
            private _typeData = _spendingTypes getOrDefault [_type, [1.0, 30, 0.05]];
            _typeData params ["_multiplier", "_threshold", "_effLoss"];

            private _current = _self get "_resources";
            if (_current < _threshold) exitWith { false };

            private _efficiency = _self call ["_getEfficiency", [_type]];
            private _cost = _amount * _multiplier * (1 / _efficiency);

            _current >= _cost
        }],

        // Spend resources with type-based modifiers
        ["spendResources", {
            params ["_amount", "_type"];

            private _spendingTypes = _self get "SPENDING_TYPES";
            private _typeData = _spendingTypes getOrDefault [_type, [1.0, 30, 0.05]];
            _typeData params ["_multiplier", "_threshold", "_effLoss"];

            private _current = _self get "_resources";

            // Check threshold
            if (_current < _threshold) exitWith {
                ["OPFOR_RES", 3, format["Denied %1: below threshold (%2 < %3)",
                    _type, _current, _threshold]] call FLO_fnc_log;
                false
            };

            // Calculate cost with efficiency
            private _efficiency = _self call ["_getEfficiency", [_type]];
            private _cost = _amount * _multiplier * (1 / _efficiency);

            // Check affordability
            if (_current < _cost) exitWith {
                ["OPFOR_RES", 3, format["Cannot afford %1: cost %2, have %3",
                    _type, round _cost, round _current]] call FLO_fnc_log;
                false
            };

            // Deduct resources
            private _new = _current - _cost;
            _self set ["_resources", _new];
            _self set ["_lastUpdate", time];

            // Reduce efficiency for this type
            private _newEff = _efficiency - _effLoss;
            _self call ["_setEfficiency", [_type, _newEff]];

            // Recover efficiency if resources abundant
            if (_new > _threshold * 2) then {
                {
                    private _currEff = _self call ["_getEfficiency", [_x]];
                    _self call ["_setEfficiency", [_x, _currEff + 0.02]];
                } forEach (keys _spendingTypes);
            };

            ["OPFOR_RES", 3, format["Spent %1 on %2 (eff: %3) | Remaining: %4",
                round _cost, _type, round (_newEff * 100), round _new]] call FLO_fnc_log;
            true
        }],

        // Serialize state for saving
        ["serialize", {
            createHashMapFromArray [
                ["resources", _self get "_resources"],
                ["lastUpdate", _self get "_lastUpdate"],
                ["efficiencies", _self get "_efficiencies"]
            ]
        }]
    ];

    FLO_OPFOR_Resources = createHashMapObject [_resourceClass];
    ["OPFOR_RES", 2, "OPFOR Resource System initialized"] call FLO_fnc_log;
};