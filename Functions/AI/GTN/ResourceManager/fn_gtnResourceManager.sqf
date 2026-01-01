/*
 * Function: FLO_fnc_gtnResourceManager
 * Author: Frontline Operations Development Group
 * Description:
 * Creates the GTN Resource Manager that controls overall OPFOR operations.
 * Manages virtual groups for attacking BLUFOR and defending objectives.
 * Provides resource allocation and group management for the GTN planning system.
 *
 * This is the main integration point for the GTN (Goal Task Network) system.
 * All ground force management flows through this resource manager.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * GTN Resource Manager HashMap Object <HASHMAP>
 *
 * Example:
 * [] call FLO_fnc_gtnResourceManager;
 */

// Log function start
["GTN Resource Manager", 3, "Starting GTN Resource Manager"] call FLO_fnc_log;

// Load configuration
private _config = call FLO_fnc_gtnConfig;

// Initialize variables from config
private _lastCommanderUpdate = diag_tickTime;
private _currentThreatLevel = 0;

// Set up the Resource Manager object using a HashMap
private _resourceManager = createHashMapObject [[
    // Runtime state
    ["_threatLevel", _currentThreatLevel],
    ["_lastUpdate", _lastCommanderUpdate],
    ["_activeAttackGroups", []],
    ["_activeDefenseGroups", []],
    ["_garrisonedGroups", []],
    ["_strategicReserve", []],
    ["_activeAirMissions", []],
    ["_activeArtilleryMissions", []],
    ["_preparatoryFiresActive", createHashMap],

    // Cached filtered groups (refreshed each update cycle)
    ["_cachedMilitaryGroups", createHashMap],
    ["_cachedMilitaryGroupsTime", 0],

    // Telemetry/Metrics tracking
    ["_metrics", createHashMapFromArray [
        ["attacksLaunched", 0],
        ["attacksSuccessful", 0],
        ["attacksFailed", 0],
        ["defensesLaunched", 0],
        ["defensesSuccessful", 0],
        ["defensesFailed", 0],
        ["groupsLost", 0],
        ["artilleryMissionsFired", 0],
        ["airMissionsFlown", 0],
        ["lastUpdateDuration", 0],
        ["startTime", diag_tickTime]
    ]],

    // Configuration reference
    ["_config", _config],

    // Computed limits (will be set in initialize)
    ["_maxAttackingGroups", 0],

    // Config-driven properties (cached for performance)
    ["_maxDefendingGroups", _config get "maxDefendingGroups"],
    ["_minGarrisonGroups", _config get "minGarrisonGroups"],
    ["_reserveRatio", _config get "reserveRatio"],
    ["_commanderUpdateInterval", _config get "strategyInterval"],

    // Asset managers
    ["_airTaskOrder", call FLO_fnc_gtnAirTaskOrder],
    ["_artilleryAssetManager", call FLO_fnc_gtnArtilleryManager],
    ["_airAssetManager", call FLO_fnc_gtnAirAssetManager],

    // GTN (Goal Task Network) system - initialized later
    ["_gtnCommander", nil],

    // Get cached military groups (refreshes every 30 seconds)
    ["_getMilitaryGroups", {
        private _cacheTime = _self get "_cachedMilitaryGroupsTime";
        private _cfg = _self get "_config";
        private _cacheExpiry = _cfg get "groupCacheExpiry";

        if (diag_tickTime - _cacheTime > _cacheExpiry) then {
            private _groups = FLO_virtualGroups get "_groups";
            private _filtered = [_groups] call FLO_fnc_filterNonCivGroups;
            _self set ["_cachedMilitaryGroups", _filtered];
            _self set ["_cachedMilitaryGroupsTime", diag_tickTime];
        };

        _self get "_cachedMilitaryGroups"
    }],

    // Update a metric value
    ["_updateMetric", {
        params ["_metricName", "_value", ["_operation", "SET"]];
        private _metrics = _self get "_metrics";

        switch (_operation) do {
            case "SET": { _metrics set [_metricName, _value]; };
            case "ADD": { _metrics set [_metricName, (_metrics getOrDefault [_metricName, 0]) + _value]; };
            case "INC": { _metrics set [_metricName, (_metrics getOrDefault [_metricName, 0]) + 1]; };
        };
    }],

    // Get metrics report
    ["_getMetricsReport", {
        private _metrics = _self get "_metrics";
        private _runtime = diag_tickTime - (_metrics get "startTime");

        private _attackSuccess = if ((_metrics get "attacksLaunched") > 0) then {
            ((_metrics get "attacksSuccessful") / (_metrics get "attacksLaunched")) * 100
        } else { 0 };

        private _defenseSuccess = if ((_metrics get "defensesLaunched") > 0) then {
            ((_metrics get "defensesSuccessful") / (_metrics get "defensesLaunched")) * 100
        } else { 0 };

        format[
            "GTN Resource Manager Metrics (Runtime: %1 min):\n- Attacks: %2 launched, %3%4 success\n- Defenses: %5 launched, %6%7 success\n- Groups Lost: %8\n- Artillery Missions: %9\n- Air Missions: %10",
            round(_runtime / 60),
            _metrics get "attacksLaunched",
            round _attackSuccess, "%",
            _metrics get "defensesLaunched",
            round _defenseSuccess, "%",
            _metrics get "groupsLost",
            _metrics get "artilleryMissionsFired",
            _metrics get "airMissionsFlown"
        ]
    }],

    ["_calculateMaxAttackingGroups", {
        private _cfg = _self get "_config";
        private _playerCount = count (allPlayers - entities "HeadlessClient_F");

        // No attacks with few players
        if (_playerCount <= (_cfg get "minPlayersForAttack")) exitWith { 0 };

        // Calculate groups based on player count
        private _playersPerGroup = _cfg get "playersPerAttackGroup";
        private _minPlayers = _cfg get "minPlayersForAttack";
        private _maxGroups = floor((_playerCount - _minPlayers) / _playersPerGroup);

        // Add aggression score bonus
        private _AGGRSCORE = FLO_DifficultyHandle get "value";
        private _aggrBonus = _cfg get "aggressionGroupBonus";
        _maxGroups = _maxGroups + floor (_AGGRSCORE / _aggrBonus);

        // Cap at maximum
        _maxGroups = _maxGroups min (_cfg get "maxAttackGroups");

        _maxGroups
    }],

    // Enhanced resource management - calculate dynamic garrison requirements
    ["_calculateDynamicGarrisonRequirements", {
        private _currentThreat = _self get "_threatLevel";
        private _totalGroups = count (_self get "_garrisonedGroups") + count (_self get "_activeAttackGroups") + count (_self get "_activeDefenseGroups");

        // Base minimum garrison
        private _baseGarrison = 2;

        // Increase garrison requirements based on threat level
        private _threatMultiplier = 1 + (_currentThreat / 10);
        private _dynamicGarrison = ceil(_baseGarrison * _threatMultiplier);

        // Ensure we always have strategic reserves
        private _reserveRequirement = ceil(_totalGroups * (_self get "_reserveRatio"));

        // Return the higher of dynamic garrison or reserve requirement
        _dynamicGarrison max _reserveRequirement max _baseGarrison
    }],

    // Manage strategic reserves - high-priority units for critical situations
    ["_manageStrategicReserve", {
        private _allGroups = (_self get "_garrisonedGroups") + (_self get "_activeAttackGroups") + (_self get "_activeDefenseGroups");
        private _totalGroups = count _allGroups;
        private _reserveSize = ceil(_totalGroups * (_self get "_reserveRatio"));

        // Get all virtual groups to assess capabilities
        private _groups = FLO_virtualGroups get "_groups";

        // Prioritize groups for reserve (armor, mechanized, then motorized)
        private _prioritizedGroups = [_allGroups, [], {
            private _groupData = _groups get _x;
            if (isNil "_groupData") exitWith { 0 };  // Group was deleted
            private _groupType = _groupData get "groupType";
            if (_groupType in ["civilian", "civilianVehicle"]) exitWith { 0 };
            switch (_groupType) do {
                case "armor": { 100 };
                case "mechanized": { 80 };
                case "motorized": { 60 };
                case "helicopter": { 90 };
                case "jet": { 95 };
                default { 40 };
            };
        }, "DESCEND"] call BIS_fnc_sortBy;

        // Update strategic reserve
        private _newReserve = _prioritizedGroups select [0, _reserveSize min count _prioritizedGroups];
        _self set ["_strategicReserve", _newReserve];

        ["GTN Resource Manager", 4, format["Updated strategic reserve: %1 groups of %2 total", count _newReserve, _totalGroups]] call FLO_fnc_log;
    }],

    ["_initializeGroups", {
        // Wait until the objective groups have been initialized
        waitUntil {!isNil "InitializationOG" && {InitializationOG}};

        // Calculate initial max attacking groups
        _self set ["_maxAttackingGroups", _self call ["_calculateMaxAttackingGroups", []]];

        // Get all virtual groups from the virtualization system (using cache)
        private _allGroups = _self call ["_getMilitaryGroups", []];
        private _garrisonedGroups = [];

        {
            private _groupId = _x;
            private _groupData = _y;

            _garrisonedGroups pushBack _groupId;

            // Determine garrison objective and position
            private _objId = _groupData get "objective";
            if (_objId isEqualTo "") then {
                _objId = [(_groupData get "position")] call FLO_fnc_getNearestObjective;
            };
            _groupData set ["garrisonObjective", _objId];

            if (_objId != "" && {!isNil "FLO_Objectives"}) then {
                private _objData = FLO_Objectives get _objId;
                if (!isNil "_objData") then {
                    _groupData set ["garrisonPosition", [_objId] call FLO_fnc_getRandomObjectivePos];
                } else {
                    _groupData set ["garrisonPosition", _groupData get "position"];
                };
            } else {
                _groupData set ["garrisonPosition", _groupData get "position"];
            };
        } forEach _allGroups;

        // Store the garrisoned groups
        _self set ["_garrisonedGroups", _garrisonedGroups];

        ["GTN Resource Manager", 3, format["Initialized with %1 virtual groups", count _garrisonedGroups]] call FLO_fnc_log;
    }],

    // Return group to garrison
    ["_returnGroupToGarrison", {
        params ["_groupId", "_currentRole"];

        // Safety check for virtualization system
        if (isNil "FLO_virtualGroups") exitWith {
            ["GTN Resource Manager", 2, format["Cannot return group %1 - virtualization not initialized", _groupId]] call FLO_fnc_log;
        };

        // Get the group's data
        private _groups = FLO_virtualGroups get "_groups";
        private _groupData = _groups get _groupId;

        // Check if group still has waypoints to complete
        private _waypoints = _groupData get "waypoints";
        if (count _waypoints > 0) exitWith {
            ["GTN Resource Manager", 4, format["Group %1 still has waypoints to complete - keeping on task", _groupId]] call FLO_fnc_log;
        };

        // Clear any operation assignment
        _groupData deleteAt "operationId";

        // Determine garrison position based on assigned objective
        private _garrisonPos = _groupData get "position";
        private _objId = _groupData get "objective";
        if (_objId != "" && {!isNil "FLO_Objectives"}) then {
            private _odata = FLO_Objectives get _objId;
            if (!isNil "_odata") then { _garrisonPos = [_objId] call FLO_fnc_getRandomObjectivePos; };
        };

        // Update group assignments
        private _garrisonedGroups = _self get "_garrisonedGroups";
        private _activeGroups = _self get (["_activeAttackGroups", "_activeDefenseGroups"] select (_currentRole == "DEFEND"));
        _activeGroups deleteAt (_activeGroups find _groupId);
        if !(_groupId in _garrisonedGroups) then {
            _garrisonedGroups pushBack _groupId;
        };

        // Update group data
        _groupData set ["garrisonPosition", _garrisonPos];
        _groupData set ["garrisonObjective", _objId];
        _groupData set ["currentOrder", "GARRISON"];

        // Set up return waypoints
        private _waypoints = [
            [_garrisonPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 10]
        ];
        [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;

        ["GTN Resource Manager", 3, format["Returned group %1 to garrison from %2 role", _groupId, _currentRole]] call FLO_fnc_log;
    }],

    // === GTN HELPER METHODS ===
    // These methods are called by the GTN executor to interface with resource manager operations

    // Get available groups for GTN operations
    ["_getAvailableGroups", {
        params [["_count", 1]];

        private _garrisoned = _self get "_garrisonedGroups";
        private _reserve = _self get "_strategicReserve";
        private _available = _garrisoned - _reserve;
        private _dynamicMin = _self call ["_calculateDynamicGarrisonRequirements", []];

        // Respect minimum garrison
        private _canTake = (count _available) - _dynamicMin;
        if (_canTake <= 0) exitWith { [] };

        private _toReturn = _available select [0, _count min _canTake];
        _toReturn
    }],

    // Order a group to move to a position (for GTN)
    ["_orderGroupMove", {
        params ["_groupId", "_targetPos", ["_mode", "AWARE"]];

        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups get _groupId;

        private _speed = switch (_mode) do {
            case "COMBAT": { "FULL" };
            case "STEALTH": { "LIMITED" };
            default { "NORMAL" };
        };

        private _waypoints = [
            [_targetPos, "MOVE", _mode, _speed, "WEDGE", "YELLOW", 50]
        ];

        [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
        _gData set ["currentOrder", "MOVE"];

        true
    }],

    // Order a group to attack a position (for GTN)
    ["_orderGroupAttack", {
        params ["_groupId", "_targetPos"];

        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups get _groupId;

        // Remove from garrison, add to attack
        private _garrisoned = _self get "_garrisonedGroups";
        private _attacking = _self get "_activeAttackGroups";

        _garrisoned deleteAt (_garrisoned find _groupId);
        if !(_groupId in _attacking) then { _attacking pushBack _groupId };

        private _waypoints = [
            [_targetPos, "MOVE", "COMBAT", "FULL", "WEDGE", "RED", 75],
            [_targetPos, "MOVE", "COMBAT", "NORMAL", "LINE", "RED", 50]
        ];

        [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
        _gData set ["currentOrder", "ATTACK"];

        true
    }],

    // Order a group to defend a position (for GTN)
    ["_orderGroupDefend", {
        params ["_groupId", "_targetPos"];

        private _groups = FLO_virtualGroups get "_groups";
        private _gData = _groups get _groupId;

        // Remove from garrison, add to defense
        private _garrisoned = _self get "_garrisonedGroups";
        private _defending = _self get "_activeDefenseGroups";

        _garrisoned deleteAt (_garrisoned find _groupId);
        if !(_groupId in _defending) then { _defending pushBack _groupId };

        private _waypoints = [
            [_targetPos, "MOVE", "COMBAT", "FULL", "WEDGE", "RED", 40],
            [_targetPos, "GUARD", "COMBAT", "NORMAL", "LINE", "RED", 60]
        ];

        [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
        _gData set ["currentOrder", "DEFEND"];

        true
    }],

    // Select highest priority enemy objective (for GTN)
    ["_selectPriorityObjective", {
        if (isNil "FLO_Objectives") exitWith { "" };

        private _bestObj = "";
        private _bestScore = -1;

        {
            private _data = FLO_Objectives get _x;
            if (isNil "_data") then { continue };

            private _owner = _data getOrDefault ["owner", east];
            if (_owner == east) then { continue };  // Skip our objectives

            private _priority = _data getOrDefault ["priority", 50];
            private _pos = _data get "position";

            // Factor in enemy presence (less enemies = easier target)
            private _blufor = allUnits select {side _x == west && alive _x};
            private _defenders = count (_blufor inAreaArray [_pos, 300, 300]);

            private _score = _priority - (_defenders * 5);

            if (_score > _bestScore) then {
                _bestScore = _score;
                _bestObj = _x;
            };
        } forEach (keys FLO_Objectives);

        _bestObj
    }],

    // Initialize GTN system
    ["_initializeGTN", {
        ["GTN Resource Manager", 3, "Initializing GTN subsystem"] call FLO_fnc_log;

        private _gtn = [_self] call FLO_fnc_gtnCommander;
        _self set ["_gtnCommander", _gtn];

        if (!isNil "_gtn") then {
            _gtn call ["_start", []];
            ["GTN Resource Manager", 2, "GTN Commander initialized and started"] call FLO_fnc_log;
        } else {
            ["GTN Resource Manager", 1, "Failed to initialize GTN Commander"] call FLO_fnc_log;
        };
    }],

    // === END GTN HELPER METHODS ===

    // Enhanced artillery support with preparatory fires and mission tracking
    ["_callArtillerySupport", {
        params ["_self", "_targetPos", ["_rounds", 6], ["_missionType", "IMMEDIATE"], ["_priority", 1]];

        private _artilleryMgr = _self get "_artilleryAssetManager";
        private _success = false;

        switch (_missionType) do {
            case "PREPARATORY": {
                private _prepRounds = _rounds * 2;
                _success = _artilleryMgr call ["_requestFireMission", [_targetPos, _prepRounds]];

                if (_success) then {
                    private _prepFires = _self get "_preparatoryFiresActive";
                    _prepFires set [str _targetPos, diag_tickTime];
                    _self set ["_preparatoryFiresActive", _prepFires];
                    ["GTN Resource Manager", 3, format["Preparatory artillery fires initiated at %1 (%2 rounds)", _targetPos, _prepRounds]] call FLO_fnc_log;
                };
            };

            case "SUPPRESSIVE": {
                _success = _artilleryMgr call ["_requestFireMission", [_targetPos, _rounds]];

                if (_success) then {
                    [_targetPos, _artilleryMgr, _rounds] spawn {
                        params ["_pos", "_mgr", "_rounds"];
                        sleep 120;
                        _mgr call ["_requestFireMission", [_pos, _rounds]];
                    };
                    ["GTN Resource Manager", 3, format["Suppressive artillery fires at %1", _targetPos]] call FLO_fnc_log;
                };
            };

            case "COUNTER_BATTERY": {
                private _cbRounds = _rounds + 4;
                _success = _artilleryMgr call ["_requestFireMission", [_targetPos, _cbRounds]];

                if (_success) then {
                    ["GTN Resource Manager", 2, format["Counter-battery fires at detected artillery position %1", _targetPos]] call FLO_fnc_log;
                };
            };

            default {
                _success = _artilleryMgr call ["_requestFireMission", [_targetPos, _rounds]];
            };
        };

        if (_success) then {
            private _activeMissions = _self get "_activeArtilleryMissions";
            private _missionData = createHashMapFromArray [
                ["targetPos", _targetPos],
                ["rounds", _rounds],
                ["type", _missionType],
                ["startTime", diag_tickTime],
                ["priority", _priority]
            ];
            _activeMissions pushBack _missionData;
            _self set ["_activeArtilleryMissions", _activeMissions];

            _self call ["_updateMetric", ["artilleryMissionsFired", 1, "INC"]];

            private _grid = mapGridPosition _targetPos;
            ["STR_FLO_WARNING_TITLE", format ["%1 at grid %2", localize "STR_FLO_WARNING_EARTYINC", _grid], "warning"] call FLO_fnc_sendNotification;
        };

        _success
    }],

    ["_selectAirMission", {
        params ["_self", "_targetPos"];

        private _rad = 300;

        private _veh = vehicles select {
            side _x == west && alive _x && { _x distance2D _targetPos < _rad }
        };
        private _tanks = _veh select { _x isKindOf "Tank" };

        if (count _tanks > 0) exitWith {"LASER"};
        if (count _veh > 0) exitWith {"BOMB"};

        private _inf = allUnits select {
            side _x == west && alive _x && { _x distance2D _targetPos < _rad } &&
            { vehicle _x == _x }
        };
        if (count _inf > 10) exitWith {"BOMB"};

        "CAS"
    }],

    // Enhanced air support with mission types and coordination
    ["_callAirSupport", {
        params ["_self", "_targetPos", ["_mission", ""], ["_type", ""], ["_alt", -1], ["_missionType", "IMMEDIATE"]];

        if (_mission isEqualTo "") then {
            _mission = _self call ["_selectAirMission", [_targetPos]];
        };

        if (_alt < 0) then {
            _alt = if (_mission in ["BOMB", "LASER"]) then {300} else {150};
        };

        private _ato = _self get "_airTaskOrder";
        private _success = false;

        switch (_missionType) do {
            case "PREPARATORY": {
                _mission = "BOMB";
                _alt = 400;
                _ato call ["_addTask", [_targetPos, _mission, _type, _alt]];

                [_targetPos, _mission, _type, _alt, _ato] spawn {
                    params ["_pos", "_miss", "_typ", "_altitude", "_airTaskOrder"];
                    sleep (60 + random 60);
                    _airTaskOrder call ["_addTask", [_pos, _miss, _typ, _altitude]];
                };

                _success = true;
                ["GTN Resource Manager", 3, format["Preparatory air strikes ordered at %1", _targetPos]] call FLO_fnc_log;
            };

            case "SEAD": {
                _mission = "LASER";
                _ato call ["_addTask", [_targetPos, _mission, _type, _alt]];
                _success = true;
                ["GTN Resource Manager", 3, format["SEAD mission ordered at %1", _targetPos]] call FLO_fnc_log;
            };

            case "CAP": {
                _mission = "CAP";
                _alt = if (_alt < 0) then { 300 } else { _alt };
                _ato call ["_addTask", [_targetPos, _mission, _type, _alt]];
                _success = true;
                ["GTN Resource Manager", 3, format["CAP mission queued at %1 via ATO", _targetPos]] call FLO_fnc_log;
            };

            case "INTERDICTION": {
                _mission = "BOMB";
                _ato call ["_addTask", [_targetPos, _mission, _type, _alt]];
                _success = true;
                ["GTN Resource Manager", 3, format["Interdiction strike ordered at %1", _targetPos]] call FLO_fnc_log;
            };

            default {
                _ato call ["_addTask", [_targetPos, _mission, _type, _alt]];
                _success = true;
            };
        };

        if (_success) then {
            private _activeMissions = _self get "_activeAirMissions";
            private _missionData = createHashMapFromArray [
                ["targetPos", _targetPos],
                ["mission", _mission],
                ["type", _missionType],
                ["startTime", diag_tickTime],
                ["altitude", _alt]
            ];
            _activeMissions pushBack _missionData;
            _self set ["_activeAirMissions", _activeMissions];

            _self call ["_updateMetric", ["airMissionsFlown", 1, "INC"]];
        };

        _success
    }],

    ["_update", {
        // Safety check - ensure virtualization system exists
        if (isNil "FLO_virtualGroups") exitWith {
            ["GTN Resource Manager", 2, "Update skipped - virtualization system not initialized"] call FLO_fnc_log;
        };

        private _currentTime = diag_tickTime;
        private _lastUpdate = _self get "_lastUpdate";
        private _updateInterval = _self get "_commanderUpdateInterval";

        // Only update periodically
        if (_currentTime - _lastUpdate < _updateInterval) exitWith {};

        // Update resource management
        _self call ["_manageStrategicReserve", []];

        // Clean up any dead groups first
        private _allGroups = (_self get "_activeAttackGroups") + (_self get "_activeDefenseGroups") + (_self get "_garrisonedGroups");
        private _groups = FLO_virtualGroups get "_groups";
        private _deadGroups = [];
        {
            private _groupId = _x;
            private _groupData = _groups get _groupId;

            // Group deleted from virtualization
            if (isNil "_groupData") then {
                _deadGroups pushBack _groupId;
            } else {
                // Group is active but real group destroyed
                if (_groupData get "isActive" && {isNull (_groupData get "realGroup")}) then {
                    _deadGroups pushBack _groupId;
                };
            };
        } forEach _allGroups;

        // Remove dead groups from all tracked arrays (batched for performance)
        if (count _deadGroups > 0) then {
            private _activeAttackGroups = _self get "_activeAttackGroups";
            private _activeDefenseGroups = _self get "_activeDefenseGroups";
            private _garrisonedGroups = _self get "_garrisonedGroups";

            _activeAttackGroups = _activeAttackGroups - _deadGroups;
            _activeDefenseGroups = _activeDefenseGroups - _deadGroups;
            _garrisonedGroups = _garrisonedGroups - _deadGroups;

            _self set ["_activeAttackGroups", _activeAttackGroups];
            _self set ["_activeDefenseGroups", _activeDefenseGroups];
            _self set ["_garrisonedGroups", _garrisonedGroups];

            _self call ["_updateMetric", ["groupsLost", count _deadGroups, "ADD"]];
            ["GTN Resource Manager", 3, format["Removed %1 dead groups from tracking", count _deadGroups]] call FLO_fnc_log;
        };

        // GTN Mode: Goal-driven planning
        private _gtn = _self get "_gtnCommander";
        if (!isNil "_gtn") then {
            _gtn call ["_update", []];
        };

        // Check if any active groups should return to garrison
        private _cfg = _self get "_config";
        private _attackReturnDist = _cfg get "attackReturnDistance";
        private _defenseReturnDist = _cfg get "defenseReturnDistance";

        private _vGroups = FLO_virtualGroups get "_groups";

        {
            private _groupId = _x;
            private _groupData = _vGroups get _groupId;
            private _realGroup = _groupData get "realGroup";

            if (!isNull _realGroup) then {
                private _nearestEnemy = leader _realGroup findNearestEnemy leader _realGroup;

                if (isNull _nearestEnemy || {_nearestEnemy distance leader _realGroup > _attackReturnDist}) then {
                    _self call ["_returnGroupToGarrison", [_groupId, "ATTACK"]];
                };
            };
        } forEach (_self get "_activeAttackGroups");

        {
            private _groupId = _x;
            private _groupData = _vGroups get _groupId;
            private _realGroup = _groupData get "realGroup";

            if (!isNull _realGroup) then {
                private _nearestEnemy = leader _realGroup findNearestEnemy leader _realGroup;

                if (isNull _nearestEnemy || {_nearestEnemy distance leader _realGroup > _defenseReturnDist}) then {
                    _self call ["_returnGroupToGarrison", [_groupId, "DEFEND"]];
                };
            };
        } forEach (_self get "_activeDefenseGroups");

        // Process any queued air support tasks
        (_self get "_airTaskOrder") call ["_processTasks", []];

        // Clean up completed missions
        _self call ["_cleanupCompletedMissions", []];

        // Update last update time
        _self set ["_lastUpdate", _currentTime];
    }],

    // Clean up completed air and artillery missions
    ["_cleanupCompletedMissions", {
        private _currentTime = diag_tickTime;
        private _cfg = _self get "_config";

        // Clean up old artillery missions
        private _artilleryExpiry = _cfg get "artilleryMissionExpiry";
        private _artilleryMissions = _self get "_activeArtilleryMissions";
        private _activeArtillery = _artilleryMissions select {
            (_currentTime - (_x get "startTime")) < _artilleryExpiry
        };
        _self set ["_activeArtilleryMissions", _activeArtillery];

        // Clean up old air missions
        private _airExpiry = _cfg get "airMissionExpiry";
        private _airMissions = _self get "_activeAirMissions";
        private _activeAir = _airMissions select {
            (_currentTime - (_x get "startTime")) < _airExpiry
        };
        _self set ["_activeAirMissions", _activeAir];

        // Clean up old preparatory fires
        private _prepExpiry = _cfg get "prepFiresExpiry";
        private _prepFires = _self get "_preparatoryFiresActive";
        private _expiredFires = [];
        {
            if ((_currentTime - _y) > _prepExpiry) then {
                _expiredFires pushBack _x;
            };
        } forEach _prepFires;

        {
            _prepFires deleteAt _x;
        } forEach _expiredFires;

        _self set ["_preparatoryFiresActive", _prepFires];

        if (count _expiredFires > 0) then {
            ["GTN Resource Manager", 4, format["Cleaned up %1 expired preparatory fires", count _expiredFires]] call FLO_fnc_log;
        };
    }]
]];

// Initialize Resource Manager (strategy interval already set from config)
["GTN Resource Manager", 3, format["Initialized with strategy interval: %1s, update interval: %2s",
    _config get "strategyInterval", _config get "updateInterval"]] call FLO_fnc_log;

// Initialize groups
_resourceManager call ["_initializeGroups", []];

// Initialize GTN system
_resourceManager call ["_initializeGTN", []];

// Start the resource manager loop
[_resourceManager, _config get "updateInterval"] spawn {
    params ["_manager", "_updateInterval"];

    while {true} do {
        _manager call ["_update", []];
        sleep _updateInterval;
    };
};

// Return the resource manager object
_resourceManager

