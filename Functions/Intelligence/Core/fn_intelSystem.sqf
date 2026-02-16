/*
    Function: FLO_fnc_intelSystem

    Description:
    BLUFOR intelligence system with engagement-focused mechanics.
    Provides tiered intel reveals with anticipation delays and variable rewards.

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

    Reveal Tiers (Variable Rewards):
    - COMMON (60%): Single enemy group
    - UNCOMMON (25%): Artillery battery or waypoints
    - RARE (12%): Commander objective
    - EPIC (3%): Multiple reveals

    Parameter(s):
        None (self-initializing)

    Returns:
        Creates FLO_Intel_System global object

    Public Methods:
        getIntelLevel: Returns current intel level (0-100)
        getIntelTier: Returns tier string (HIGH/MODERATE/LIMITED/MINIMAL)
        addIntel: [amount, source, duration] - Add intel
        triggerReveal: [source] - Trigger intel reveal with briefing
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
            ["capital", 6],
            ["city", 4],
            ["marine", 3],
            ["local", 2],
            ["village", 1],
            ["cluster", 0]
        ]],

        ["BASE_DECAY", 3],
        ["MAX_LEVEL", 100],
        ["MIN_LEVEL", 0],
        ["UPDATE_INTERVAL", 300],
        ["REVEAL_COOLDOWN", 60],

        // Reveal tier weights (total 100)
        ["REVEAL_WEIGHTS", createHashMapFromArray [
            ["COMMON", 60],
            ["UNCOMMON", 25],
            ["RARE", 12],
            ["EPIC", 3]
        ]],

        // ========================================
        // STATE PROPERTIES
        // ========================================
        ["_intelLevel", 25],
        ["_lastUpdate", 0],
        ["_lastReveal", 0],
        ["_bluforObjectives", 0],
        ["_tempBonus", 0],
        ["_tempBonusExpiry", 0],
        ["_pendingReveal", false],

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
            
            // Start radio intercept loop (ambient intel at HIGH tier)
            _self call ["_startRadioInterceptLoop", []];
        }],

        // ========================================
        // PRIVATE METHODS
        // ========================================

        // Calculate intel generation from BLUFOR objectives
        ["_calculateObjectiveIntel", {
            if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) exitWith { 0 };

            private _intelValues = _self get "INTEL_VALUES";
            private _totalIntel = 0;
            private _friendlyCount = 0;
            private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
            if !(_activeSide in [east, west]) then { _activeSide = west };

            {
                private _objId = _x;
                private _objData = FLO_Objectives get _objId;
                if ((_objData getOrDefault ["owner", east]) isEqualTo _activeSide) then {
                    private _subtype = _objData getOrDefault ["subtype", "cluster"];
                    _totalIntel = _totalIntel + (_intelValues getOrDefault [_subtype, 1]);
                    _friendlyCount = _friendlyCount + 1;
                };
            } forEach (keys FLO_Objectives);

            _self set ["_bluforObjectives", _friendlyCount];
            _totalIntel
        }],

        // Roll for reveal tier based on weights
        ["_rollRevealTier", {
            private _weights = _self get "REVEAL_WEIGHTS";
            private _roll = floor random 100;
            private _cumulative = 0;
            private _result = "COMMON";
            
            {
                private _tier = _x;
                private _weight = _weights get _tier;
                _cumulative = _cumulative + _weight;
                if (_roll < _cumulative) exitWith {
                    _result = _tier;
                };
            } forEach (keys _weights);
            
            _result
        }],

        // Execute reveal based on tier
        ["_executeReveal", {
            params ["_tier"];
            
            private _revealed = false;
            
            switch (_tier) do {
                case "EPIC": {
                    // Multiple reveals + audio warning
                    [] call FLO_fnc_revealRandomEnemyGroup;
                    [] call FLO_fnc_revealRandomEnemyGroup;
                    [] call FLO_fnc_revealArtilleryBattery;
                    _revealed = true;
                    
                    ["Major enemy force disposition acquired!", "success"] remoteExec ["FLO_fnc_sendNotification", 0];
                };
                
                case "RARE": {
                    // Commander objective
                    _revealed = [] call FLO_fnc_revealCommanderObjective;
                    if (!_revealed) then {
                        // Fallback to artillery
                        _revealed = [] call FLO_fnc_revealArtilleryBattery;
                    };
                };
                
                case "UNCOMMON": {
                    // Artillery or multiple groups
                    if (random 1 > 0.5) then {
                        _revealed = [] call FLO_fnc_revealArtilleryBattery;
                    } else {
                        [] call FLO_fnc_revealRandomEnemyGroup;
                        [] call FLO_fnc_revealRandomEnemyGroup;
                        _revealed = true;
                    };
                };
                
                default {
                    // COMMON: Single group
                    [] call FLO_fnc_revealRandomEnemyGroup;
                    _revealed = true;
                };
            };
            
            ["INTEL", 3, format["Intel reveal: %1 tier, success=%2", _tier, _revealed]] call FLO_fnc_log;
            _revealed
        }],

        // Intel briefing with anticipation delay
        ["_showBriefing", {
            params ["_source", "_callback"];
            
            _self set ["_pendingReveal", true];
            
            // Broadcast processing notification
            ["Processing intelligence...", "info"] remoteExec ["FLO_fnc_sendNotification", 0];
            
            // Radio chatter sound (if available)
            // playSound "radio_static"; // Uncomment if sound exists
            
            // Delay for anticipation (2-4 seconds)
            private _delay = 2 + random 2;
            
            [_self, _callback, _delay] spawn {
                params ["_system", "_cb", "_d"];
                sleep _d;
                
                // Roll tier and execute
                private _tier = _system call ["_rollRevealTier", []];
                _system call ["_executeReveal", [_tier]];
                
                _system set ["_pendingReveal", false];
                _system set ["_lastReveal", time];
            };
        }],

        // Start radio intercept loop (ambient intel at HIGH tier)
        ["_startRadioInterceptLoop", {
            [] spawn {
                waitUntil { sleep 5; !isNil "FLO_Intel_System" };
                
                private _intercepts = [
                    "Enemy commander requesting reinforcements",
                    "Artillery battery ordered to relocate",
                    "Patrol route changes detected",
                    "Enemy logistics convoy scheduled",
                    "Air assets on standby alert",
                    "Enemy forces consolidating at forward positions"
                ];
                
                while {true} do {
                    if (isNil "FLO_Intel_System") exitWith {};
                    
                    private _tier = FLO_Intel_System call ["getIntelTier", []];
                    
                    // Only at HIGH tier
                    if (_tier == "HIGH") then {
                        private _msg = selectRandom _intercepts;
                        [format ["Radio intercept: '%1'", _msg], "info"] remoteExec ["FLO_fnc_sendNotification", 0];
                        
                        ["INTEL", 3, format["Radio intercept: %1", _msg]] call FLO_fnc_log;
                    };
                    
                    // Random interval 3-6 minutes
                    sleep (180 + random 180);
                };
            };
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

        // Trigger intel reveal with briefing and tiered rewards
        ["triggerReveal", {
            params [["_source", "unknown"]];
            
            private _lastReveal = _self get "_lastReveal";
            private _cooldown = _self get "REVEAL_COOLDOWN";
            private _pending = _self get "_pendingReveal";
            
            // Check cooldown
            if (_pending || {(time - _lastReveal) < _cooldown}) exitWith {
                ["INTEL", 3, "Reveal on cooldown or pending"] call FLO_fnc_log;
                false
            };
            
            _self call ["_showBriefing", [_source, nil]];
            true
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
                
                // Trigger a reveal for the action
                _self call ["triggerReveal", [_source]];
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
    ["INTEL", 2, "Intel System initialized with engagement features"] call FLO_fnc_log;
};
