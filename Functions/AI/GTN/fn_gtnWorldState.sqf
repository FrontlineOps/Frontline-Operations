/*
 * Function: FLO_fnc_gtnWorldState
 * Author: Frontline Operations Development Group
 * 
 * Description:
 * Goal Task Network World State - Blackboard pattern implementation.
 * Maintains a centralized world state that all GTN components can query.
 * Sensors update the state, conditions query it, actions modify it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * World State HashMap Object <HASHMAP>
 *
 * Example:
 * private _worldState = call FLO_fnc_gtnWorldState;
 * _worldState call ["_update", []];
 * private _objectives = _worldState call ["_getObjectives", []];
 */

["GTN", 3, "Initializing GTN World State System"] call FLO_fnc_log;

private _worldState = createHashMapObject [[
    // === STATE DATA ===
    
    // Objective state - keyed by objective ID
    ["_objectives", createHashMap],
    
    // Force disposition
    ["_ownForces", createHashMapFromArray [
        ["totalGroups", 0],
        ["availableGroups", 0],
        ["attackingGroups", 0],
        ["defendingGroups", 0],
        ["garrisonedGroups", 0],
        ["infantryGroups", 0],
        ["armorGroups", 0],
        ["mechanizedGroups", 0],
        ["motorizedGroups", 0],
        ["artilleryGroups", 0],
        ["airGroups", 0]
    ]],
    
    // Support assets
    ["_supportAssets", createHashMapFromArray [
        ["artilleryAvailable", false],
        ["artilleryCooldown", 0],
        ["artilleryAmmo", 0],
        ["casAvailable", false],
        ["casCooldown", 0],
        ["seadAvailable", false],
        ["bombingAvailable", false]
    ]],
    
    // Enemy intel
    ["_enemyIntel", createHashMapFromArray [
        ["knownPositions", []],
        ["estimatedStrength", 0],
        ["lastContactTime", 0],
        ["threatLevel", 0],
        ["concentrations", []]
    ]],
    
    // Tactical situation
    ["_tacticalSituation", createHashMapFromArray [
        ["timeOfDay", "DAY"],
        ["weather", "CLEAR"],
        ["overallThreat", 0],
        ["momentum", 0],           // -100 (losing) to +100 (winning)
        ["initiativeHolder", "NEUTRAL"]
    ]],
    
    // State metadata
    ["_lastUpdate", 0],
    ["_updateInterval", 10],      // Seconds between full updates
    
    // Reference to AI Commander for integration
    ["_commander", nil],
    
    // === SENSOR METHODS ===
    
    // Update objective states from FLO_Objectives
    ["_senseObjectives", {
        private _objectives = createHashMap;
        
        if (isNil "FLO_Objectives") exitWith { _objectives };
        
        private _bluforUnits = allUnits select {side _x == west && alive _x && !(captive _x)};
        private _opforUnits = allUnits select {side _x == east && alive _x};
        
        {
            private _id = _x;
            private _data = FLO_Objectives get _id;
            if (isNil "_data") then { continue };
            
            private _pos = _data get "position";
            private _priority = _data getOrDefault ["priority", 50];
            private _owner = _data getOrDefault ["owner", east];
            
            // Count units near objective
            private _nearBlufor = count (_bluforUnits inAreaArray [_pos, 500, 500]);
            private _nearOpfor = count (_opforUnits inAreaArray [_pos, 500, 500]);
            
            // Determine contestation
            private _contested = (_nearBlufor > 0) && (_nearOpfor > 0);
            private _underAttack = (_owner == east) && (_nearBlufor > 0);
            private _vulnerable = (_owner == west) && (_nearOpfor == 0) && (_nearBlufor < 3);
            
            private _objState = createHashMapFromArray [
                ["position", _pos],
                ["priority", _priority],
                ["owner", _owner],
                ["enemyCount", if (_owner == east) then {_nearBlufor} else {_nearOpfor}],
                ["friendlyCount", if (_owner == east) then {_nearOpfor} else {_nearBlufor}],
                ["contested", _contested],
                ["underAttack", _underAttack],
                ["vulnerable", _vulnerable],
                ["forceRatio", if (_nearBlufor > 0) then {_nearOpfor / _nearBlufor} else {999}]
            ];
            
            _objectives set [_id, _objState];
        } forEach (keys FLO_Objectives);
        
        _self set ["_objectives", _objectives];
        _objectives
    }],
    
    // Update force disposition from virtualization system
    ["_senseForces", {
        private _forces = _self get "_ownForces";
        
        if (isNil "FLO_virtualGroups") exitWith { _forces };
        
        private _groups = FLO_virtualGroups get "_groups";
        private _allGroupIds = keys _groups;

        // Count by type and status
        private _counts = createHashMapFromArray [
            ["total", 0], ["available", 0], ["attacking", 0], ["defending", 0], ["garrisoned", 0],
            ["infantry", 0], ["armor", 0], ["mechanized", 0], ["motorized", 0], ["artillery", 0], ["air", 0]
        ];

        // Get commander reference for status checks
        private _cmdr = _self get "_commander";
        private _attackGroups = if (!isNil "_cmdr") then { _cmdr get "_activeAttackGroups" } else { [] };
        private _defenseGroups = if (!isNil "_cmdr") then { _cmdr get "_activeDefenseGroups" } else { [] };
        private _garrisonGroups = if (!isNil "_cmdr") then { _cmdr get "_garrisonedGroups" } else { [] };

        {
            private _gData = _groups get _x;
            if (isNil "_gData") then { continue };
            if ((_gData getOrDefault ["side", sideUnknown]) != east) then { continue };

            private _groupType = _gData getOrDefault ["groupType", "infantry"];

            // Count total
            _counts set ["total", (_counts get "total") + 1];

            // Count by type
            private _typeKey = switch (_groupType) do {
                case "armor": { "armor" };
                case "mechanized": { "mechanized" };
                case "motorized": { "motorized" };
                case "artillery": { "artillery" };
                case "air": { "air" };
                default { "infantry" };
            };
            _counts set [_typeKey, (_counts get _typeKey) + 1];

            // Count by status
            if (_x in _attackGroups) then {
                _counts set ["attacking", (_counts get "attacking") + 1];
            } else {
                if (_x in _defenseGroups) then {
                    _counts set ["defending", (_counts get "defending") + 1];
                } else {
                    if (_x in _garrisonGroups) then {
                        _counts set ["garrisoned", (_counts get "garrisoned") + 1];
                        _counts set ["available", (_counts get "available") + 1];
                    };
                };
            };
        } forEach _allGroupIds;

        // Update forces HashMap
        _forces set ["totalGroups", _counts get "total"];
        _forces set ["availableGroups", _counts get "available"];
        _forces set ["attackingGroups", _counts get "attacking"];
        _forces set ["defendingGroups", _counts get "defending"];
        _forces set ["garrisonedGroups", _counts get "garrisoned"];
        _forces set ["infantryGroups", _counts get "infantry"];
        _forces set ["armorGroups", _counts get "armor"];
        _forces set ["mechanizedGroups", _counts get "mechanized"];
        _forces set ["motorizedGroups", _counts get "motorized"];
        _forces set ["artilleryGroups", _counts get "artillery"];
        _forces set ["airGroups", _counts get "air"];

        _self set ["_ownForces", _forces];
        _forces
    }],

    // Update support asset availability
    ["_senseSupportAssets", {
        private _assets = _self get "_supportAssets";
        private _cmdr = _self get "_commander";

        if (isNil "_cmdr") exitWith { _assets };

        // Check artillery - look for artillery groups in virtualization system
        private _artyAvailable = false;
        if (!isNil "FLO_virtualGroups") then {
            private _groups = FLO_virtualGroups get "_groups";
            if (!isNil "_groups") then {
                {
                    private _gData = _groups get _x;
                    if (!isNil "_gData" && {(_gData getOrDefault ["groupType", ""]) == "artillery"}) exitWith {
                        _artyAvailable = true;
                    };
                } forEach (keys _groups);
            };
        };
        _assets set ["artilleryAvailable", _artyAvailable];

        // Check air assets - look for air groups in virtualization system
        private _casAvailable = false;
        private _seadAvailable = false;
        private _bombAvailable = false;
        if (!isNil "FLO_virtualGroups") then {
            private _groups = FLO_virtualGroups get "_groups";
            if (!isNil "_groups") then {
                {
                    private _gData = _groups get _x;
                    if (isNil "_gData") then { continue };
                    private _gType = _gData getOrDefault ["groupType", ""];
                    if (_gType in ["cas", "sead", "bomber", "air", "helicopter"]) then {
                        switch (_gType) do {
                            case "cas": { _casAvailable = true };
                            case "sead": { _seadAvailable = true };
                            case "bomber": { _bombAvailable = true };
                            default { _casAvailable = true }; // Generic air = CAS
                        };
                    };
                } forEach (keys _groups);
            };
        };
        _assets set ["casAvailable", _casAvailable];
        _assets set ["seadAvailable", _seadAvailable];
        _assets set ["bombingAvailable", _bombAvailable];

        _self set ["_supportAssets", _assets];
        _assets
    }],

    // Sense enemy intel from known contacts
    ["_senseEnemyIntel", {
        private _intel = _self get "_enemyIntel";

        private _bluforUnits = allUnits select {side _x == west && alive _x && !(captive _x)};
        private _knownPositions = [];
        private _concentrations = [];

        // Find enemy concentrations (groups of 3+ within 100m)
        private _processedUnits = [];
        {
            if (_x in _processedUnits) then { continue };

            private _pos = getPos _x;
            private _nearby = _bluforUnits inAreaArray [_pos, 100, 100];

            if (count _nearby >= 3) then {
                private _centerPos = [0,0,0];
                { _centerPos = _centerPos vectorAdd (getPos _x); } forEach _nearby;
                _centerPos = _centerPos vectorMultiply (1 / count _nearby);

                _concentrations pushBack createHashMapFromArray [
                    ["position", _centerPos],
                    ["strength", count _nearby],
                    ["lastSeen", diag_tickTime]
                ];

                _processedUnits append _nearby;
            };

            _knownPositions pushBack [getPos _x, diag_tickTime];
        } forEach _bluforUnits;

        _intel set ["knownPositions", _knownPositions];
        _intel set ["concentrations", _concentrations];
        _intel set ["estimatedStrength", count _bluforUnits];
        _intel set ["lastContactTime", diag_tickTime];

        // Calculate threat level (0-10)
        private _threatLevel = ((count _bluforUnits) / 10) min 10;
        _intel set ["threatLevel", _threatLevel];

        _self set ["_enemyIntel", _intel];
        _intel
    }],

    // Update tactical situation assessment
    ["_senseTacticalSituation", {
        private _situation = _self get "_tacticalSituation";
        private _objectives = _self get "_objectives";
        private _forces = _self get "_ownForces";
        private _intel = _self get "_enemyIntel";

        // Time of day
        private _hour = daytime;
        private _timeOfDay = switch (true) do {
            case (_hour >= 6 && _hour < 18): { "DAY" };
            case (_hour >= 18 && _hour < 21): { "DUSK" };
            case (_hour >= 21 || _hour < 5): { "NIGHT" };
            default { "DAWN" };
        };
        _situation set ["timeOfDay", _timeOfDay];

        // Weather
        private _overcast = overcast;
        private _rain = rain;
        private _weather = switch (true) do {
            case (_rain > 0.5): { "RAIN" };
            case (_overcast > 0.7): { "OVERCAST" };
            case (_overcast > 0.3): { "CLOUDY" };
            default { "CLEAR" };
        };
        _situation set ["weather", _weather];

        // Overall threat
        _situation set ["overallThreat", _intel get "threatLevel"];

        // Calculate momentum (-100 to +100)
        private _ownedByUs = 0;
        private _ownedByEnemy = 0;
        private _contested = 0;
        {
            private _obj = _objectives get _x;
            if ((_obj get "owner") == east) then { _ownedByUs = _ownedByUs + 1 };
            if ((_obj get "owner") == west) then { _ownedByEnemy = _ownedByEnemy + 1 };
            if (_obj get "contested") then { _contested = _contested + 1 };
        } forEach (keys _objectives);

        private _totalObj = count (keys _objectives) max 1;
        private _momentum = ((_ownedByUs - _ownedByEnemy) / _totalObj) * 100;
        _situation set ["momentum", _momentum];

        // Initiative holder
        private _initiative = switch (true) do {
            case (_momentum > 30): { "OPFOR" };
            case (_momentum < -30): { "BLUFOR" };
            default { "NEUTRAL" };
        };
        _situation set ["initiativeHolder", _initiative];

        _self set ["_tacticalSituation", _situation];
        _situation
    }],

    // === QUERY METHODS ===

    // Get all objectives
    ["_getObjectives", {
        _self get "_objectives"
    }],

    // Get objectives by filter
    ["_getObjectivesWhere", {
        params [["_filterFn", {true}]];
        private _result = createHashMap;
        private _objectives = _self get "_objectives";

        {
            private _obj = _objectives get _x;
            if ([_x, _obj] call _filterFn) then {
                _result set [_x, _obj];
            };
        } forEach (keys _objectives);

        _result
    }],

    // Get enemy objectives (not owned by us)
    ["_getEnemyObjectives", {
        _self call ["_getObjectivesWhere", [{
            params ["_id", "_obj"];
            (_obj get "owner") != east
        }]]
    }],

    // Get our objectives under attack
    ["_getObjectivesUnderAttack", {
        _self call ["_getObjectivesWhere", [{
            params ["_id", "_obj"];
            (_obj get "owner") == east && {_obj get "underAttack"}
        }]]
    }],

    // Get vulnerable enemy objectives
    ["_getVulnerableObjectives", {
        _self call ["_getObjectivesWhere", [{
            params ["_id", "_obj"];
            (_obj get "owner") != east && {_obj get "vulnerable"}
        }]]
    }],

    // Get force counts
    ["_getForces", {
        _self get "_ownForces"
    }],

    // Check if we have force superiority for an objective
    ["_hasSuperiority", {
        params ["_objectiveId", ["_ratio", 3]];
        private _objectives = _self get "_objectives";
        private _obj = _objectives getOrDefault [_objectiveId, nil];

        if (isNil "_obj") exitWith { false };

        (_obj get "forceRatio") >= _ratio
    }],

    // Check if support asset is available
    ["_isAssetAvailable", {
        params ["_assetType"];
        private _assets = _self get "_supportAssets";

        switch (toLower _assetType) do {
            case "artillery": { _assets get "artilleryAvailable" };
            case "cas": { _assets get "casAvailable" };
            case "sead": { _assets get "seadAvailable" };
            case "bombing": { _assets get "bombingAvailable" };
            default { false };
        }
    }],

    // Get tactical situation
    ["_getTacticalSituation", {
        _self get "_tacticalSituation"
    }],

    // Get enemy intel
    ["_getEnemyIntel", {
        _self get "_enemyIntel"
    }],

    // === MAIN UPDATE ===

    // Full state update from all sensors
    ["_update", {
        private _now = diag_tickTime;
        private _lastUpdate = _self get "_lastUpdate";
        private _interval = _self get "_updateInterval";

        // Throttle updates
        if (_now - _lastUpdate < _interval) exitWith {};

        // Run all sensors
        _self call ["_senseObjectives", []];
        _self call ["_senseForces", []];
        _self call ["_senseSupportAssets", []];
        _self call ["_senseEnemyIntel", []];
        _self call ["_senseTacticalSituation", []];

        _self set ["_lastUpdate", _now];

        ["GTN", 4, "World state updated"] call FLO_fnc_log;
    }],

    // Set commander reference
    ["_setCommander", {
        params ["_cmdr"];
        _self set ["_commander", _cmdr];
    }],

    // Get state snapshot for comparison (used by replan detection)
    ["_getSnapshot", {
        createHashMapFromArray [
            ["objectives", +(_self get "_objectives")],
            ["forces", +(_self get "_ownForces")],
            ["assets", +(_self get "_supportAssets")],
            ["intel", +(_self get "_enemyIntel")],
            ["situation", +(_self get "_tacticalSituation")],
            ["time", diag_tickTime]
        ]
    }],

    // Compare two snapshots for significant changes
    ["_hasSignificantChange", {
        params ["_oldSnapshot"];

        if (isNil "_oldSnapshot") exitWith { true };

        private _oldForces = _oldSnapshot get "forces";
        private _newForces = _self get "_ownForces";

        // Check for significant force changes (>20% loss)
        private _oldTotal = _oldForces get "totalGroups";
        private _newTotal = _newForces get "totalGroups";
        if (_oldTotal > 0 && {((_oldTotal - _newTotal) / _oldTotal) > 0.2}) exitWith { true };

        // Check for objective status changes
        private _oldObjs = _oldSnapshot get "objectives";
        private _newObjs = _self get "_objectives";
        {
            private _oldObj = _oldObjs getOrDefault [_x, nil];
            private _newObj = _newObjs getOrDefault [_x, nil];

            if (isNil "_oldObj" || isNil "_newObj") then { continue };

            // Owner changed
            if ((_oldObj get "owner") != (_newObj get "owner")) exitWith { true };

            // Contestation changed
            if ((_oldObj get "contested") != (_newObj get "contested")) exitWith { true };
        } forEach (keys _newObjs);

        // Check for asset availability changes
        private _oldAssets = _oldSnapshot get "assets";
        private _newAssets = _self get "_supportAssets";
        if ((_oldAssets get "artilleryAvailable") != (_newAssets get "artilleryAvailable")) exitWith { true };
        if ((_oldAssets get "casAvailable") != (_newAssets get "casAvailable")) exitWith { true };

        false
    }],

    // Debug output
    ["_debugPrint", {
        private _forces = _self get "_ownForces";
        private _situation = _self get "_tacticalSituation";
        private _objectives = _self get "_objectives";
        private _assets = _self get "_supportAssets";

        format[
            "GTN World State:\n  Forces: %1 total (%2 available, %3 attacking, %4 defending)\n  Objectives: %5 total, Momentum: %6\n  Assets: Arty=%7, CAS=%8\n  Time: %9, Weather: %10",
            _forces get "totalGroups",
            _forces get "availableGroups",
            _forces get "attackingGroups",
            _forces get "defendingGroups",
            count (keys _objectives),
            _situation get "momentum",
            _assets get "artilleryAvailable",
            _assets get "casAvailable",
            _situation get "timeOfDay",
            _situation get "weather"
        ]
    }]
]];

["GTN", 3, "GTN World State System initialized"] call FLO_fnc_log;

_worldState
