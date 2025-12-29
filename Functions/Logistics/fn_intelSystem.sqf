/*
    Function: FLO_fnc_intelSystem

    Description:
    OOP-based BLUFOR intelligence system. Integrates with FLO_Objectives
    for dynamic intel generation based on controlled territory.

    Intel Generation (per 5-minute cycle):
    - Capital: 15 intel (major comms infrastructure)
    - City: 10 intel (population intelligence network)
    - Marine: 8 intel (port surveillance)
    - Local: 6 intel (military signals)
    - Village: 3 intel (local informants)
    - Cluster: 1 intel (limited coverage)

    Base decay: 5 intel/cycle
    Net intel = generation + tempBonus - decay

    Intel Tiers & Effects:
    - HIGH (75-100): Full enemy visibility, accurate garrison estimates
    - MODERATE (50-74): Objective ownership visible, approximate estimates
    - LIMITED (25-49): Frontline info only, vague garrison data
    - MINIMAL (0-24): Minimal intel, OPFOR has surprise advantage

    Parameter(s):
        None (self-initializing)

    Returns:
        Creates FLO_Intel_System global object

    Public Methods:
        getIntelLevel: Returns current intel level (0-100)
        getIntelTier: Returns tier string (HIGH/MODERATE/LIMITED/MINIMAL)
        addIntel: [amount, source, duration] - Add intel
        serialize: Returns HashMap for saving
*/

if (!isServer) exitWith {};

if (isNil "FLO_Intel_System") then {
    private _intelClass = [
        ["#type", "IntelSystem"],

        // ========================================
        // CLASS CONSTANTS
        // ========================================
        ["INTEL_VALUES", createHashMapFromArray [
            ["capital", 15],
            ["city", 10],
            ["marine", 8],
            ["local", 6],
            ["village", 3],
            ["cluster", 1]
        ]],

        ["BASE_DECAY", 5],
        ["MAX_LEVEL", 100],
        ["MIN_LEVEL", 0],
        ["UPDATE_INTERVAL", 300],

        // ========================================
        // STATE PROPERTIES
        // ========================================
        ["_intelLevel", 25],
        ["_lastUpdate", 0],
        ["_bluforObjectives", 0],
        ["_tempBonus", 0],
        ["_tempBonusExpiry", 0],

        // ========================================
        // CONSTRUCTOR
        // ========================================
        ["#create", {
            // Check for saved game data
            private _savedState = nil;
            if (!isNil "FLO_SavedGameData") then {
                _savedState = FLO_SavedGameData getOrDefault ["intelSystem", nil];
            };

            if (!isNil "_savedState" && {_savedState isEqualType createHashMap}) then {
                // Restore from save
                _self set ["_intelLevel", _savedState getOrDefault ["intelLevel", 25]];
                _self set ["_tempBonus", _savedState getOrDefault ["tempBonus", 0]];
                _self set ["_tempBonusExpiry", time + (_savedState getOrDefault ["tempBonusRemaining", 0])];
                _self set ["_lastUpdate", time];

                ["INTEL", 2, format["Restored from save: %1 intel", _self get "_intelLevel"]] call FLO_fnc_log;
            } else {
                // Fresh start
                _self set ["_intelLevel", 25];
                _self set ["_lastUpdate", time];
                _self set ["_tempBonus", 0];
                _self set ["_tempBonusExpiry", 0];

                ["INTEL", 2, "Fresh start: 25 intel"] call FLO_fnc_log;
            };

            // Start update loop
            _self call ["_startUpdateLoop", []];
        }],

        // ========================================
        // PRIVATE METHODS
        // ========================================

        // Calculate intel generation from BLUFOR objectives
        ["_calculateObjectiveIntel", {
            if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) exitWith { 0 };

            private _intelValues = _self get "INTEL_VALUES";
            private _totalIntel = 0;
            private _bluforCount = 0;

            {
                if ((_y getOrDefault ["owner", east]) isEqualTo west) then {
                    private _subtype = _y getOrDefault ["subtype", "cluster"];
                    _totalIntel = _totalIntel + (_intelValues getOrDefault [_subtype, 1]);
                    _bluforCount = _bluforCount + 1;
                };
            } forEach FLO_Objectives;

            _self set ["_bluforObjectives", _bluforCount];
            _totalIntel
        }],

        // Start the background update loop
        ["_startUpdateLoop", {
            [] spawn {
                waitUntil { sleep 1; !isNil "FLO_Objectives" && {count FLO_Objectives > 0} };

                while {true} do {
                    if (isNil "FLO_Intel_System") exitWith {};

                    private _currentLevel = FLO_Intel_System get "_intelLevel";
                    private _baseDecay = FLO_Intel_System get "BASE_DECAY";
                    private _maxLevel = FLO_Intel_System get "MAX_LEVEL";
                    private _minLevel = FLO_Intel_System get "MIN_LEVEL";

                    // Calculate intel from BLUFOR objectives
                    private _objectiveIntel = FLO_Intel_System call ["_calculateObjectiveIntel", []];

                    // Check temporary bonus expiry
                    private _tempBonus = FLO_Intel_System get "_tempBonus";
                    private _tempExpiry = FLO_Intel_System get "_tempBonusExpiry";
                    if (time > _tempExpiry && _tempBonus > 0) then {
                        _tempBonus = (_tempBonus - 2) max 0;
                        FLO_Intel_System set ["_tempBonus", _tempBonus];
                    };

                    // Calculate net intel change
                    private _netChange = _objectiveIntel + _tempBonus - _baseDecay;

                    // Apply with bounds
                    private _newLevel = ((_currentLevel + _netChange) min _maxLevel) max _minLevel;
                    FLO_Intel_System set ["_intelLevel", _newLevel];
                    FLO_Intel_System set ["_lastUpdate", time];

                    // Broadcast to clients
                    private _tier = FLO_Intel_System call ["getIntelTier", []];
                    FLO_Intel_Level = _newLevel;
                    FLO_Intel_Tier = _tier;
                    publicVariable "FLO_Intel_Level";
                    publicVariable "FLO_Intel_Tier";

                    ["INTEL", 3, format["Intel: %1 (%2) | Gen: +%3 | Temp: +%4 | Decay: -%5 | Net: %6",
                        round _newLevel, _tier, _objectiveIntel, _tempBonus, _baseDecay, round _netChange]] call FLO_fnc_log;

                    sleep (FLO_Intel_System get "UPDATE_INTERVAL");
                };
            };
        }],

        // ========================================
        // PUBLIC METHODS
        // ========================================

        // Get current intel level
        ["getIntelLevel", {
            _self get "_intelLevel"
        }],

        // Get intel tier string
        ["getIntelTier", {
            private _level = _self get "_intelLevel";
            switch (true) do {
                case (_level >= 75): { "HIGH" };
                case (_level >= 50): { "MODERATE" };
                case (_level >= 25): { "LIMITED" };
                default { "MINIMAL" };
            }
        }],

        // Add intel from items or other sources
        ["addIntel", {
            params ["_amount", ["_source", "unknown"], ["_duration", 0]];

            private _max = _self get "MAX_LEVEL";
            private _min = _self get "MIN_LEVEL";

            if (_source == "intel_item") then {
                // Temporary bonus
                private _currentBonus = _self get "_tempBonus";
                _self set ["_tempBonus", (_currentBonus + _amount) min 20];
                _self set ["_tempBonusExpiry", time + (if (_duration > 0) then {_duration} else {600})];

                ["INTEL", 3, format["Intel item: +%1 temp bonus", _amount]] call FLO_fnc_log;
            } else {
                // Direct addition
                private _current = _self get "_intelLevel";
                private _new = ((_current + _amount) min _max) max _min;
                _self set ["_intelLevel", _new];
                _self set ["_lastUpdate", time];
            };

            _self get "_intelLevel"
        }],

        // Serialize state for saving
        ["serialize", {
            private _tempExpiry = _self get "_tempBonusExpiry";
            private _tempRemaining = if (_tempExpiry > time) then { _tempExpiry - time } else { 0 };

            createHashMapFromArray [
                ["intelLevel", _self get "_intelLevel"],
                ["tempBonus", _self get "_tempBonus"],
                ["tempBonusRemaining", _tempRemaining]
            ]
        }]
    ];

    FLO_Intel_System = createHashMapObject [_intelClass];
    ["INTEL", 2, "Intel System initialized"] call FLO_fnc_log;
};