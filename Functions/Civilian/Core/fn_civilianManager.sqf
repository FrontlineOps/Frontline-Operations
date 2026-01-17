/*
 * Function: FLO_fnc_civilianManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Unified Civilian Manager - OOP-style HashMap that manages civilian behavior,
 *   area dispositions, and reputation-based interactions.
 *
 * Arguments:
 *   None (initializes global FLO_CivilianManager)
 *
 * Returns:
 *   HashMap - The civilian manager object
 *
 * Example:
 *   [] call FLO_fnc_civilianManager;
 *   FLO_CivilianManager call ["getDisposition", [_objectiveId]];
 */

if (!isServer) exitWith {};

// ============================================================================
// CIVILIAN MANAGER OBJECT
// ============================================================================
FLO_CivilianManager = createHashMapFromArray [

    // ========================================================================
    // CONFIGURATION
    // ========================================================================
    ["CONFIG", createHashMapFromArray [
        // Reputation thresholds for behavior changes
        ["REP_FRIENDLY", 12],       // >= this: proactive help
        ["REP_NEUTRAL", 8],         // >= this: normal
        ["REP_WARY", 4],            // >= this: reduced intel, some flee
        ["REP_HOSTILE", 0],         // below WARY: flee, report to OPFOR
        
        // Intel generation rates (passive, per cycle)
        ["INTEL_FRIENDLY_BONUS", 2],    // Bonus intel from friendly areas
        ["INTEL_NEUTRAL_BONUS", 0],     // No bonus from neutral
        
        // Update interval
        ["UPDATE_INTERVAL", 60],        // Seconds between disposition updates
        
        // Flee parameters
        ["FLEE_RADIUS", 150],           // Civilians flee within this radius of combat
        ["FLEE_DURATION", 180]          // Seconds before fleeing civs return
    ]],

    // ========================================================================
    // STATE
    // ========================================================================
    ["_areaDispositions", createHashMap],   // Per-objective civilian mood
    ["_lastUpdate", 0],
    ["_fleeingGroups", createHashMap],      // Groups currently fleeing

    // ========================================================================
    // METHODS
    // ========================================================================
    
    // Get current global reputation (0-16)
    ["getReputation", {
        if (isNil "FLO_ReputationHandle") exitWith { 8 };
        FLO_ReputationHandle getOrDefault ["value", 8]
    }],
    
    // Get behavior tier based on reputation
    ["getBehaviorTier", {
        private _rep = _self call ["getReputation", []];
        private _cfg = _self get "CONFIG";
        
        if (_rep >= _cfg get "REP_FRIENDLY") exitWith { "FRIENDLY" };
        if (_rep >= _cfg get "REP_NEUTRAL") exitWith { "NEUTRAL" };
        if (_rep >= _cfg get "REP_WARY") exitWith { "WARY" };
        "HOSTILE"
    }],
    
    // Get disposition for a specific objective area
    ["getDisposition", {
        params [["_objectiveId", ""]];
        
        private _dispositions = _self get "_areaDispositions";
        private _areaDisp = _dispositions getOrDefault [_objectiveId, nil];
        
        // If no specific disposition, use global behavior tier
        if (isNil "_areaDisp") exitWith {
            _self call ["getBehaviorTier", []]
        };
        
        _areaDisp
    }],
    
    // Set disposition for an objective area
    ["setDisposition", {
        params ["_objectiveId", "_disposition"];
        
        private _dispositions = _self get "_areaDispositions";
        _dispositions set [_objectiveId, _disposition];
        
        ["CIVILIAN", 3, format["Area %1 disposition set to %2", _objectiveId, _disposition]] call FLO_fnc_log;
    }],
    
    // Check if civilian should flee based on position and combat state
    ["shouldFlee", {
        params ["_position"];
        
        private _tier = _self call ["getBehaviorTier", []];
        if (_tier == "FRIENDLY") exitWith { false };
        
        private _cfg = _self get "CONFIG";
        private _fleeRadius = _cfg get "FLEE_RADIUS";
        
        // Check for nearby combat (gunfire, explosions)
        private _nearbyUnits = _position nearEntities [["Man", "Car", "Tank"], _fleeRadius];
        private _combatNearby = false;
        
        {
            if (side _x == west && {behaviour _x in ["COMBAT", "STEALTH"]}) exitWith {
                _combatNearby = true;
            };
        } forEach _nearbyUnits;
        
        // If WARY or HOSTILE and combat nearby, flee
        if (_combatNearby && {_tier in ["WARY", "HOSTILE"]}) exitWith { true };
        
        // If HOSTILE, flee from any player proximity
        if (_tier == "HOSTILE") then {
            private _nearPlayers = _position nearEntities [["Man"], 100];
            _nearPlayers = _nearPlayers select { isPlayer _x };
            count _nearPlayers > 0
        } else {
            false
        }
    }],
    
    // Get intel chance modifier based on disposition
    ["getIntelChance", {
        params [["_objectiveId", ""]];
        
        private _disp = _self call ["getDisposition", [_objectiveId]];
        
        switch (_disp) do {
            case "FRIENDLY": { 0.75 };
            case "NEUTRAL": { 0.45 };
            case "WARY": { 0.2 };
            case "HOSTILE": { 0 };
            default { 0.3 };
        }
    }],
    
    // Update area dispositions based on objective ownership
    ["_updateDispositions", {
        if (isNil "FLO_Objectives") exitWith {};
        
        private _dispositions = _self get "_areaDispositions";
        private _globalTier = _self call ["getBehaviorTier", []];
        
        {
            private _objId = _x;
            private _objData = FLO_Objectives get _objId;
            private _owner = _objData getOrDefault ["owner", east];
            private _captureTime = _objData getOrDefault ["lastCaptureTime", 0];
            private _timeSinceCapture = diag_tickTime - _captureTime;
            
            private _newDisp = switch (true) do {
                // OPFOR held = fearful
                case (_owner == east): { "WARY" };
                
                // Recently captured = uncertain
                case (_owner == west && _timeSinceCapture < 600): { "NEUTRAL" };
                
                // Long BLUFOR held = follows global rep
                case (_owner == west): { _globalTier };
                
                default { "NEUTRAL" };
            };
            
            _dispositions set [_objId, _newDisp];
            
        } forEach (keys FLO_Objectives);
        
        ["CIVILIAN", 3, "Updated area dispositions"] call FLO_fnc_log;
    }],
    
    // Main update tick - call periodically
    ["update", {
        private _cfg = _self get "CONFIG";
        private _lastUpdate = _self get "_lastUpdate";
        private _interval = _cfg get "UPDATE_INTERVAL";
        
        if (diag_tickTime - _lastUpdate < _interval) exitWith {};
        
        _self set ["_lastUpdate", diag_tickTime];
        
        // Update area dispositions
        _self call ["_updateDispositions", []];
        
        // Check for protest conditions (HOSTILE areas)
        private _tier = _self call ["getBehaviorTier", []];
        if (_tier == "HOSTILE") then {
            // Check for players in protest-eligible areas
            {
                private _player = _x;
                private _playerPos = getPosATL _player;
                
                // Check if in a populated location
                private _nearLocs = nearestLocations [_playerPos, ["NameCity", "NameCityCapital", "NameVillage"], 300];
                if (count _nearLocs > 0) then {
                    // 50% chance per check to spawn protesters
                    if (random 1 < 0.5) then {
                        [_player] spawn FLO_fnc_civilianProtest;
                    };
                };
            } forEach allPlayers;
        };
        
        // Log status
        private _rep = _self call ["getReputation", []];
        ["CIVILIAN", 3, format["Civilian Manager Update - Rep: %1, Tier: %2", _rep, _tier]] call FLO_fnc_log;
    }],
    
    // Initialize the manager
    ["init", {
        _self call ["_updateDispositions", []];
        _self set ["_lastUpdate", diag_tickTime];
        
        ["CIVILIAN", 2, "Civilian Manager Initialized"] call FLO_fnc_log;
    }]
];

// Initialize
FLO_CivilianManager call ["init", []];

publicVariable "FLO_CivilianManager";

["CIVILIAN", 2, "FLO_CivilianManager created and initialized"] call FLO_fnc_log;

FLO_CivilianManager
