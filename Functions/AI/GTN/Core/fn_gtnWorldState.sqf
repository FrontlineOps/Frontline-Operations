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
 * 0: Side Context <HASHMAP> - Normalized own/enemy side context
 *
 * Return Value:
 * World State HashMap Object <HASHMAP>
 *
 * Example:
 * private _worldState = [[east] call FLO_fnc_gtnSideContext] call FLO_fnc_gtnWorldState;
 * _worldState call ["_update", []];
 * private _objectives = _worldState call ["_getObjectives", []];
 */

params [["_sideContext", createHashMap]];

if (isNil "_sideContext" || {!(_sideContext isEqualType createHashMap)} || {count _sideContext == 0}) then {
    _sideContext = [east] call FLO_fnc_gtnSideContext;
};

private _ownSide = _sideContext get "ownSide";
private _enemySide = _sideContext get "enemySide";
private _sideKey = _sideContext get "sideKey";

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
        ["casCooldown", 0]
    ]],
    
    // Enemy intel
    ["_enemyIntel", createHashMapFromArray [
        ["knownPositions", []],
        ["contactReports", []],    // [Pos, Time, Strength, Type, Confidence]
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
    ["_lastSupportAssetsSense", -1],
    ["_supportAssetSenseInterval", 20],
    ["_lastEnemyIntelSense", -1],
    ["_enemyIntelSenseInterval", 30],
    ["_enemyIntelScanCursor", 0],
    ["_enemyIntelScanBudget", 24], // Max leaders to scan per intel pass
    ["_sideContext", _sideContext],
    ["_ownSide", _ownSide],
    ["_enemySide", _enemySide],
    ["_sideKey", _sideKey],
    ["_perf", createHashMapFromArray [
        ["lastUpdateMs", 0],
        ["peakUpdateMs", 0],
        ["slowUpdates", 0],
        ["lastRanAt", -1],
        ["lastPhaseMs", createHashMapFromArray [
            ["objectives", 0],
            ["forces", 0],
            ["supportAssets", 0],
            ["enemyIntel", 0],
            ["tacticalSituation", 0]
        ]],
        ["lastMeta", createHashMapFromArray [
            ["objectiveCount", 0],
            ["availableGroups", 0],
            ["contactCount", 0],
            ["concentrationCount", 0],
            ["supportSenseRan", false],
            ["enemyIntelSenseRan", false]
        ]]
    ]],
    
    // Reference to AI Commander for integration
    ["_commander", nil],
    
    // === SENSOR METHODS ===
    
    // Update objective states from FLO_Objectives
    ["_senseObjectives", {
        private _objectives = createHashMap;

        if (isNil "FLO_Objectives") exitWith { _objectives };

        private _ownSide = _self get "_ownSide";
        private _enemySide = _self get "_enemySide";
        private _friendlyCountKey = if (_ownSide isEqualTo east) then { "opforCount" } else { "bluforCount" };
        private _enemyCountKey = if (_enemySide isEqualTo east) then { "opforCount" } else { "bluforCount" };
        private _intelCache = _self getOrDefault ["_objectiveIntel", createHashMap];

        {
            private _id = _x;
            private _data = FLO_Objectives get _id;
            if (isNil "_data") then { continue };

            private _pos = _data get "position";
            private _priority = _data getOrDefault ["priority", 50];
            private _owner = _data getOrDefault ["owner", _enemySide];
            if (_owner isEqualType "") then {
                private _ownerKey = toUpper _owner;
                if (_ownerKey isEqualTo "EAST") then { _owner = east; };
                if (_ownerKey isEqualTo "WEST") then { _owner = west; };
            };

            private _nearFriendly = _data get _friendlyCountKey;
            private _nearEnemy = _data get _enemyCountKey;

            private _contested = (_nearEnemy > 0) && (_nearFriendly > 0);
            private _underAttack = (_owner == _ownSide) && (_nearEnemy > 0);
            private _vulnerable = (_owner == _enemySide) && (_nearEnemy == 0) && (_nearFriendly < 3);

            private _cachedIntel = _intelCache getOrDefault [_id, createHashMapFromArray [
                ["lastReconTime", 0],
                ["intelQuality", 0],
                ["confirmedStrength", 0],
                ["hasArmor", false],
                ["hasAA", false],
                ["defensePosture", "UNKNOWN"]
            ]];

            private _objState = createHashMapFromArray [
                ["position", _pos],
                ["priority", _priority],
                ["owner", _owner],
                ["enemyCount", if (_owner == _ownSide) then {_nearEnemy} else {_nearFriendly}],
                ["friendlyCount", if (_owner == _ownSide) then {_nearFriendly} else {_nearEnemy}],
                ["contested", _contested],
                ["underAttack", _underAttack],
                ["vulnerable", _vulnerable],
                ["forceRatio", if (_nearEnemy > 0) then {_nearFriendly / _nearEnemy} else {999}],
                ["linkedObjectives", _data getOrDefault ["linkedObjectives", []]],
                ["intel", _cachedIntel]
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

        private _ownSide = _self get "_ownSide";

        {
            private _gData = _groups get _x;
            if (isNil "_gData") then { continue };
            if ((_gData get "side") != _ownSide) then { continue };

            private _groupType = _gData get "groupType";

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

            // Count by status using commanderOrder
            private _currentOrder = _gData get "commanderOrder";
            private _missionLock = _gData get "missionLock";

            switch (_currentOrder) do {
                case "ATTACK": { _counts set ["attacking", (_counts get "attacking") + 1]; };
                case "DEFEND": { _counts set ["defending", (_counts get "defending") + 1]; };
                case "GARRISON": { _counts set ["garrisoned", (_counts get "garrisoned") + 1]; };
                default { _counts set ["garrisoned", (_counts get "garrisoned") + 1]; };
            };

            // A group is "available" if it's not on an active mission
            if (_missionLock == "") then {
                if !(_currentOrder in ["ATTACK", "DEFEND", "MOVE"]) then {
                    _counts set ["available", (_counts get "available") + 1];
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
        private _ownSide = _self get "_ownSide";

        if (isNil "_cmdr") exitWith { _assets };

        // Check artillery using Capability Analyzer for accurate ammo counts
        private _artyAvailable = false;
        private _artyAmmo = 0;
        private _artyBatteries = 0;

        if (!isNil "FLO_GTN_CapabilityAnalyzer") then {
            private _artyStatus = FLO_GTN_CapabilityAnalyzer call ["_getArtilleryStatus", [_ownSide]];
            _artyBatteries = _artyStatus get "availableBatteries";
            _artyAvailable = _artyBatteries > 0;
            // Use estimated rounds which combines actual (active) + estimated (virtual)
            _artyAmmo = _artyStatus get "estimatedRounds";

            ["GTN", 4, format["Artillery sense: batteries=%1/%2, rounds=%3 (active=%4, virtual=%5)",
                _artyBatteries,
                _artyStatus get "totalBatteries",
                _artyAmmo,
                _artyStatus get "activeRounds",
                _artyStatus get "totalRounds"]] call FLO_fnc_log;
        } else {
            // Fallback if analyzer not initialized
            private _groups = FLO_virtualGroups get "_groups";
            {
                private _gData = _groups get _x;
                if ((_gData getOrDefault ["side", sideUnknown]) != _ownSide) then { continue };
                if (_gData get "groupType" == "artillery") exitWith {
                    _artyAvailable = true;
                };
            } forEach (keys _groups);
            ["GTN", 4, format["Artillery sense (fallback): available=%1", _artyAvailable]] call FLO_fnc_log;
        };

        _assets set ["artilleryAvailable", _artyAvailable];
        _assets set ["artilleryAmmo", _artyAmmo];

        // Check air assets using Capability Analyzer for accurate status
        private _casAvailable = false;
        private _casOrdnance = 0;

        if (!isNil "FLO_GTN_CapabilityAnalyzer") then {
            private _airStatus = FLO_GTN_CapabilityAnalyzer call ["_getAirAssetStatus", [_ownSide]];
            _casAvailable = (_airStatus get "casAvailable") > 0 || (_airStatus get "heloAvailable") > 0;
            _casOrdnance = _airStatus get "totalOrdnance";

            ["GTN", 4, format["Air sense: CAS=%1/%2, Helo=%3/%4, ordnance=%5",
                _airStatus get "casAvailable", _airStatus get "casTotal",
                _airStatus get "heloAvailable", _airStatus get "heloTotal",
                _casOrdnance]] call FLO_fnc_log;
        } else {
            // Fallback if analyzer not initialized
            private _groups = FLO_virtualGroups get "_groups";
            {
                private _gData = _groups get _x;
                if ((_gData getOrDefault ["side", sideUnknown]) != _ownSide) then { continue };
                if ((_gData get "missionLock") != "") then { continue };
                private _gType = _gData get "groupType";
                if (_gType in ["cas", "sead", "bomber", "air", "helicopter"]) then {
                    _casAvailable = true;
                };
            } forEach (keys _groups);
            ["GTN", 4, format["Air sense (fallback): CAS=%1", _casAvailable]] call FLO_fnc_log;
        };

        _assets set ["casAvailable", _casAvailable];
        _assets set ["casOrdnance", _casOrdnance];

        _self set ["_supportAssets", _assets];
        _assets
    }],

    // Sense enemy intel from known contacts via actual reports
    ["_senseEnemyIntel", {
        private _intel = _self get "_enemyIntel";
        private _contacts = _intel get "contactReports";
        private _newContacts = [];
        
        // Remove old contacts
        private _cutoffTime = diag_tickTime - 900;
        _contacts = _contacts select { (_x select 1) > _cutoffTime };
        
        private _ownSide = _self get "_ownSide";
        private _enemySide = _self get "_enemySide";
        private _scanLeaders = [];

        if (!isNil "FLO_virtualGroups") then {
            private _groups = FLO_virtualGroups get "_groups";
            {
                private _gData = _y;
                if ((_gData get "side") != _ownSide) then { continue };
                if !(_gData get "isActive") then { continue };

                private _realGroup = _gData get "realGroup";
                if (isNull _realGroup) then { continue };

                private _leader = leader _realGroup;
                if (isNull _leader || {!alive _leader}) then { continue };
                _scanLeaders pushBack _leader;
            } forEach _groups;
        };

        if (count _scanLeaders == 0) then {
            {
                if (side _x != _ownSide) then { continue };
                private _leader = leader _x;
                if (isNull _leader || {!alive _leader}) then { continue };
                _scanLeaders pushBack _leader;
            } forEach allGroups;
        };

        private _scanTotal = count _scanLeaders;
        private _scanCursor = _self get "_enemyIntelScanCursor";
        private _scanBudget = _self get "_enemyIntelScanBudget";

        if (_scanTotal > 0) then {
            if (_scanCursor >= _scanTotal) then { _scanCursor = 0; };
            if (_scanBudget < 1) then { _scanBudget = 1; };
            if (_scanBudget > _scanTotal) then { _scanBudget = _scanTotal; };

            for "_step" from 0 to (_scanBudget - 1) do {
                private _idx = (_scanCursor + _step) mod _scanTotal;
                private _leader = _scanLeaders select _idx;
                // nearTargets returns [pos, type, side, subjectiveCost, object, accuracy]
                private _targets = _leader nearTargets 1500;

                {
                    _x params ["_pos", "_type", "_side", "_cost", "_obj", "_acc"];

                    // Only report enemies for this side context.
                    if (_side == _enemySide) then {
                        // Check if we already have a recent report for this location (within 50m, 60s)
                        private _isNew = true;
                        {
                            _x params ["_cPos", "_cTime"];
                            if (_cPos distance2D _pos < 50 && (diag_tickTime - _cTime) < 60) exitWith {
                                _isNew = false;
                            };
                        } forEach _contacts;

                        if (_isNew) then {
                            // Create contact report: [Pos, Time, Strength(1), Type, Confidence]
                            _contacts pushBack [_pos, diag_tickTime, 1, _type, _acc];
                            _newContacts pushBack [_pos, _type];
                        };
                    };
                } forEach _targets;
            };

            _scanCursor = (_scanCursor + _scanBudget) mod _scanTotal;
        } else {
            _scanCursor = 0;
        };

        _self set ["_enemyIntelScanCursor", _scanCursor];
        
        // Cluster contacts into concentrations using 150m spatial buckets.
        // This keeps complexity near O(n) instead of O(n^2) during large fights.
        private _concentrations = [];
        private _bucketSize = 150;
        private _buckets = createHashMap;

        {
            private _pos = _x select 0;
            private _bx = floor ((_pos select 0) / _bucketSize);
            private _by = floor ((_pos select 1) / _bucketSize);
            private _bKey = format ["%1_%2", _bx, _by];

            if !(_bKey in _buckets) then {
                _buckets set [_bKey, []];
            };
            private _bucket = _buckets get _bKey;
            _bucket pushBack _x;
            _buckets set [_bKey, _bucket];
        } forEach _contacts;

        {
            private _cluster = _y;
            if (count _cluster < 3) then { continue };

            private _centerPos = [0,0,0];
            private _clusStrength = 0;
            private _lastSeen = 0;
            {
                _centerPos = _centerPos vectorAdd (_x select 0);
                _clusStrength = _clusStrength + (_x select 2);
                if ((_x select 1) > _lastSeen) then {
                    _lastSeen = _x select 1;
                };
            } forEach _cluster;
            _centerPos = _centerPos vectorMultiply (1 / count _cluster);

            _concentrations pushBack createHashMapFromArray [
                ["position", _centerPos],
                ["strength", _clusStrength],
                ["lastSeen", _lastSeen]
            ];
        } forEach _buckets;

        // Log significant new contacts
        if (count _newContacts > 0) then {
             ["GTN", 3, format["New enemy contacts reported: %1", count _newContacts]] call FLO_fnc_log;
        };

        _intel set ["contactReports", _contacts];
        _intel set ["concentrations", _concentrations];
        
        // Estimate strength based on active reports
        _intel set ["estimatedStrength", count _contacts]; // Rough estimate
        _intel set ["lastContactTime", if (count _contacts > 0) then {diag_tickTime} else { _intel get "lastContactTime" }];
        
        // Threat level (0-10)
        private _threatLevel = ((count _contacts) / 5) min 10;
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
        private _ownSide = _self get "_ownSide";
        private _enemySide = _self get "_enemySide";

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
            if ((_obj get "owner") == _ownSide) then { _ownedByUs = _ownedByUs + 1 };
            if ((_obj get "owner") == _enemySide) then { _ownedByEnemy = _ownedByEnemy + 1 };
            if (_obj get "contested") then { _contested = _contested + 1 };
        } forEach (keys _objectives);

        private _totalObj = count (keys _objectives) max 1;
        private _momentum = ((_ownedByUs - _ownedByEnemy) / _totalObj) * 100;
        _situation set ["momentum", _momentum];

        // Initiative holder
        private _initiative = switch (true) do {
            case (_momentum > 30): { "OWN" };
            case (_momentum < -30): { "ENEMY" };
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
            (_obj get "owner") == (_self get "_enemySide")
        }]]
    }],

    // True when an enemy objective touches at least one friendly-held linked objective.
    ["_isFrontlineEnemyObjective", {
        params ["_objectiveId"];
        private _objectives = _self get "_objectives";
        private _obj = _objectives get _objectiveId;
        private _links = _obj get "linkedObjectives";
        private _ownSide = _self get "_ownSide";

        ({((_objectives get _x) get "owner") isEqualTo _ownSide} count _links) > 0
    }],

    // Enemy objectives currently on the front line (adjacent to friendly ownership).
    ["_getFrontlineEnemyObjectives", {
        _self call ["_getObjectivesWhere", [{
            params ["_id", "_obj"];
            (_obj get "owner") == (_self get "_enemySide")
            && { _self call ["_isFrontlineEnemyObjective", [_id]] }
        }]]
    }],

    ["_segmentCrossesWater", {
        params ["_fromPos", "_toPos"];
        private _dist = _fromPos distance2D _toPos;
        private _steps = ceil (_dist / 150);
        if (_steps < 1) then { _steps = 1 };

        private _crosses = false;
        for "_i" from 0 to _steps do {
            private _t = _i / _steps;
            private _samplePos = [
                (_fromPos select 0) + (((_toPos select 0) - (_fromPos select 0)) * _t),
                (_fromPos select 1) + (((_toPos select 1) - (_fromPos select 1)) * _t),
                0
            ];
            if (surfaceIsWater _samplePos) exitWith {
                _crosses = true;
            };
        };

        _crosses
    }],

    ["_getObjectiveLinkRouteInfo", {
        params ["_fromObjectiveId", "_toObjectiveId"];

        private _pair = [_fromObjectiveId, _toObjectiveId];
        _pair sort true;
        private _linkKey = format ["%1_%2", _pair select 0, _pair select 1];
        private _linkData = FLO_ObjectiveLinks get _linkKey;

        private _routeDistance = _linkData get "routeDistance";
        private _crossesWater = _linkData get "crossesWater";

        if (isNil "_routeDistance") then {
            private _fromPos = ((FLO_Objectives get _fromObjectiveId) get "position");
            private _toPos = ((FLO_Objectives get _toObjectiveId) get "position");
            _routeDistance = _fromPos distance2D _toPos;
            _crossesWater = _self call ["_segmentCrossesWater", [_fromPos, _toPos]];

            _linkData set ["routeDistance", _routeDistance];
            _linkData set ["crossesWater", _crossesWater];
            FLO_ObjectiveLinks set [_linkKey, _linkData];
        };

        createHashMapFromArray [
            ["distance", _routeDistance],
            ["crossesWater", _crossesWater]
        ]
    }],

    // Get friendly objectives (owned by us - OPFOR)
    ["_getFriendlyObjectives", {
        _self call ["_getObjectivesWhere", [{
            params ["_id", "_obj"];
            (_obj get "owner") == (_self get "_ownSide")
        }]]
    }],

    // Get our objectives under attack
    ["_getObjectivesUnderAttack", {
        _self call ["_getObjectivesWhere", [{
            params ["_id", "_obj"];
            (_obj get "owner") == (_self get "_ownSide") && {_obj get "underAttack"}
        }]]
    }],

    // Get vulnerable enemy objectives
    ["_getVulnerableObjectives", {
        _self call ["_getObjectivesWhere", [{
            params ["_id", "_obj"];
            (_obj get "owner") == (_self get "_enemySide") && {_obj get "vulnerable"}
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
            case "cap": { _assets get "casAvailable" };
            default { false };
        }
    }],

    // Get distance from position to nearest friendly (OPFOR) group
    ["_getNearestFriendlyDistance", {
        params ["_pos"];

        if (isNil "FLO_virtualGroups") exitWith { 10000 };
        private _ownSide = _self get "_ownSide";

        private _groups = FLO_virtualGroups get "_groups";
        private _minDist = 10000;

        {
            private _gData = _groups get _x;
            if ((_gData get "side") != _ownSide) then { continue };

            private _gPos = _gData get "position";
            private _dist = _pos distance2D _gPos;
            if (_dist < _minDist) then { _minDist = _dist };
        } forEach (keys _groups);

        _minDist
    }],

    ["_getTacticalSituation", {
        _self get "_tacticalSituation"
    }],

    ["_getEnemyIntel", {
        _self get "_enemyIntel"
    }],

    ["_getSupportAssets", {
        _self get "_supportAssets"
    }],

    ["_getPerf", {
        _self get "_perf"
    }],

    ["_getObjectiveAnalysis", {
        params ["_objId"];
        private _cmdr = _self get "_commander";
        if (isNil "_cmdr") exitWith { nil };
        private _analyzer = _cmdr get "_capabilityAnalyzer";
        if (isNil "_analyzer") exitWith { nil };
        _analyzer call ["_analyzeObjective", [_objId, _self]]
    }],

    ["_getForceRatioAtObjective", {
        params ["_objId"];
        private _objs = _self get "_objectives";
        private _obj = _objs get _objId;
        if (isNil "_obj") exitWith { 1 };
        private _friendly = _obj getOrDefault ["friendlyCount", 0];
        private _enemy = (_obj getOrDefault ["enemyCount", 1]) max 1;
        _friendly / _enemy
    }],

    ["_getAvailableCombatPower", {
        private _cmdr = _self get "_commander";
        if (isNil "_cmdr") exitWith { 0 };
        private _analyzer = _cmdr get "_capabilityAnalyzer";
        if (isNil "_analyzer") exitWith { 0 };
        private _summary = _analyzer call ["_getForcesSummary", [_self get "_ownSide"]];
        _summary get "totalCombatPower"
    }],

    ["_getArmorGroupCount", {
        private _forces = _self get "_ownForces";
        (_forces get "armorGroups") + (_forces get "mechanizedGroups")
    }],

    ["_getObjectiveIntel", {
        params ["_objId"];
        private _intelCache = _self getOrDefault ["_objectiveIntel", createHashMap];
        _intelCache getOrDefault [_objId, createHashMapFromArray [
            ["lastReconTime", 0],
            ["intelQuality", 0],
            ["confirmedStrength", 0],
            ["totalCombatPower", 0],
            ["hasArmor", false],
            ["hasAA", false],
            ["hasStatic", false],
            ["fortificationLevel", 0],
            ["recommendedForce", 0],
            ["defensePosture", "UNKNOWN"]
        ]]
    }],

    ["_isIntelFresh", {
        params ["_objId", ["_maxAge", 300]];
        private _intel = _self call ["_getObjectiveIntel", [_objId]];
        private _lastRecon = _intel get "lastReconTime";
        (diag_tickTime - _lastRecon) < _maxAge
    }],

    ["_updateObjectiveIntel", {
        params ["_objId", "_intelData"];
        private _intelCache = _self getOrDefault ["_objectiveIntel", createHashMap];
        private _existing = _intelCache getOrDefault [_objId, createHashMap];
        { _existing set [_x, _intelData get _x]; } forEach (keys _intelData);
        _existing set ["lastReconTime", diag_tickTime];
        _intelCache set [_objId, _existing];
        _self set ["_objectiveIntel", _intelCache];
    }],

    ["_getObjectivesNeedingRecon", {
        params [["_maxAge", 300]];
        private _objectives = _self get "_objectives";
        private _enemySide = _self get "_enemySide";
        private _needsRecon = [];
        {
            private _objId = _x;
            private _obj = _objectives get _objId;
            if ((_obj get "owner") == _enemySide) then {
                if !(_self call ["_isIntelFresh", [_objId, _maxAge]]) then {
                    _needsRecon pushBack [_objId, _obj get "priority"];
                };
            };
        } forEach (keys _objectives);
        _needsRecon sort false;
        _needsRecon apply { _x select 0 }
    }],

    ["_getReconGroups", {
        private _forces = _self get "_ownForces";
        private _infantry = _forces get "infantryGroups";
        (_infantry min 2) max 0
    }],

    // === MAIN UPDATE ===

    // Full state update from all sensors
    ["_update", {
        private _now = diag_tickTime;
        private _lastUpdate = _self get "_lastUpdate";
        private _interval = _self get "_updateInterval";
        private _lastSupportAssetsSense = _self get "_lastSupportAssetsSense";
        private _supportAssetSenseInterval = _self get "_supportAssetSenseInterval";
        private _lastEnemyIntelSense = _self get "_lastEnemyIntelSense";
        private _enemyIntelSenseInterval = _self get "_enemyIntelSenseInterval";
        private _perf = _self get "_perf";

        // Throttle updates
        if (_now - _lastUpdate < _interval) exitWith { false };

        private _phaseMs = createHashMapFromArray [
            ["objectives", 0],
            ["forces", 0],
            ["supportAssets", 0],
            ["enemyIntel", 0],
            ["tacticalSituation", 0]
        ];
        private _meta = createHashMapFromArray [
            ["objectiveCount", 0],
            ["availableGroups", 0],
            ["contactCount", 0],
            ["concentrationCount", 0],
            ["supportSenseRan", false],
            ["enemyIntelSenseRan", false]
        ];
        private _cycleStart = diag_tickTime;
        private _tPhase = diag_tickTime;

        // Run all sensors
        _self call ["_senseObjectives", []];
        _phaseMs set ["objectives", (diag_tickTime - _tPhase) * 1000];

        _tPhase = diag_tickTime;
        _self call ["_senseForces", []];
        _phaseMs set ["forces", (diag_tickTime - _tPhase) * 1000];
        if (_lastSupportAssetsSense < 0 || {_now - _lastSupportAssetsSense >= _supportAssetSenseInterval}) then {
            _tPhase = diag_tickTime;
            _self call ["_senseSupportAssets", []];
            _phaseMs set ["supportAssets", (diag_tickTime - _tPhase) * 1000];
            _meta set ["supportSenseRan", true];
            _self set ["_lastSupportAssetsSense", _now];
        };
        if (_lastEnemyIntelSense < 0 || {_now - _lastEnemyIntelSense >= _enemyIntelSenseInterval}) then {
            _tPhase = diag_tickTime;
            _self call ["_senseEnemyIntel", []];
            _phaseMs set ["enemyIntel", (diag_tickTime - _tPhase) * 1000];
            _meta set ["enemyIntelSenseRan", true];
            _self set ["_lastEnemyIntelSense", _now];
        };
        _tPhase = diag_tickTime;
        _self call ["_senseTacticalSituation", []];
        _phaseMs set ["tacticalSituation", (diag_tickTime - _tPhase) * 1000];

        _self set ["_lastUpdate", _now];

        _meta set ["objectiveCount", count (keys (_self get "_objectives"))];
        _meta set ["availableGroups", ((_self get "_ownForces") get "availableGroups")];
        _meta set ["contactCount", count ((_self get "_enemyIntel") get "contactReports")];
        _meta set ["concentrationCount", count ((_self get "_enemyIntel") get "concentrations")];

        private _dtMs = (diag_tickTime - _cycleStart) * 1000;
        _perf set ["lastUpdateMs", _dtMs];
        _perf set ["lastPhaseMs", _phaseMs];
        _perf set ["lastMeta", _meta];
        _perf set ["lastRanAt", _now];
        if (_dtMs > (_perf get "peakUpdateMs")) then {
            _perf set ["peakUpdateMs", _dtMs];
        };
        if (_dtMs > 10) then {
            _perf set ["slowUpdates", (_perf get "slowUpdates") + 1];
        };

        ["GTN", 4, "World state updated"] call FLO_fnc_log;
        true
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
