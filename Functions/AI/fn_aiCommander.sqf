/*
 * Function: FLO_fnc_aiCommander
 * Author: Frontline Operations Development Group
 * Description:
 * Creates an AI Commander that controls overall OPFOR operations.
 * Manages virtual groups for attacking BLUFOR and defending objectives.
 * Creates staging points and force coordination for better tactical operations.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * AI Commander HashMap Object <HASHMAP>
 *
 * Example:
 * [] call FLO_fnc_aiCommander;
 */

// Log function start
["AI Commander", 3, "Starting AI Commander"] call FLO_fnc_log;

// Load configuration
private _config = call FLO_fnc_aiCommanderConfig;

// Initialize variables from config
private _lastCommanderUpdate = diag_tickTime;
private _currentThreatLevel = 0;

// Set up the Commander object using a HashMap
private _aiCommander = createHashMapObject [[
    // Runtime state
    ["_threatLevel", _currentThreatLevel],
    ["_lastUpdate", _lastCommanderUpdate],
    ["_activeAttackGroups", []],
    ["_activeDefenseGroups", []],
    ["_garrisonedGroups", []],
    ["_attackOperations", createHashMap],
    ["_defenseOperations", createHashMap],
    ["_stagingPoints", createHashMap],
    ["_strategicReserve", []],
    ["_lastThreatLevel", 0],
    ["_operationHistory", []],
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
        ["avgStagingTime", 0],
        ["totalStagingTime", 0],
        ["stagingCount", 0],
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
    ["_attackStageTime", _config get "attackStageTime"],
    ["_defenseStageTime", _config get "defenseStageTime"],
    ["_minStagingForce", _config get "minStagingForce"],
    ["_maxStagingForce", _config get "maxStagingForce"],
    ["_reserveRatio", _config get "reserveRatio"],
    ["_commanderUpdateInterval", _config get "strategyInterval"],

    // Asset managers
    ["_airTaskOrder", call FLO_fnc_airTaskOrder],
    ["_artilleryAssetManager", call FLO_fnc_artilleryAssetManager],
    ["_airAssetManager", call FLO_fnc_airAssetManager],

    // GTN (Goal Task Network) system - initialized later
    ["_gtnCommander", nil],
    ["_gtnEnabled", true],  // Toggle for GTN vs reactive mode

    // Get cached military groups (refreshes every 30 seconds)
    ["_getMilitaryGroups", {
        // Safety check for virtualization system
        if (isNil "FLO_virtualGroups") exitWith { createHashMap };

        private _cacheTime = _self get "_cachedMilitaryGroupsTime";
        private _cfg = _self get "_config";
        private _cacheExpiry = _cfg getOrDefault ["groupCacheExpiry", 30];

        if (diag_tickTime - _cacheTime > _cacheExpiry) then {
            private _groups = FLO_virtualGroups getOrDefault ["_groups", createHashMap];
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
            "AI Commander Metrics (Runtime: %1 min):\n- Attacks: %2 launched, %3%4 success\n- Defenses: %5 launched, %6%7 success\n- Groups Lost: %8\n- Artillery Missions: %9\n- Air Missions: %10\n- Avg Staging Time: %11s",
            round(_runtime / 60),
            _metrics get "attacksLaunched",
            round _attackSuccess, "%",
            _metrics get "defensesLaunched",
            round _defenseSuccess, "%",
            _metrics get "groupsLost",
            _metrics get "artilleryMissionsFired",
            _metrics get "airMissionsFlown",
            round((_metrics get "avgStagingTime"))
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
        // Note: _allGroups already contains only non-civilian group IDs from initialization
        private _prioritizedGroups = [_allGroups, [], {
            private _groupData = _groups getOrDefault [_x, nil];
            if (isNil "_groupData") exitWith { 0 }; // Skip groups that no longer exist
            private _groupType = _groupData getOrDefault ["groupType", ""];
            if (_groupType in ["civilian", "civilianVehicle"]) exitWith { 0 }; // Extra safety check
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

        ["AI Commander", 4, format["Updated strategic reserve: %1 groups of %2 total", count _newReserve, _totalGroups]] call FLO_fnc_log;
    }],

    // Find a valid nearby objective for staging (must be inside another objective, not the main target, not contested, not in water)
    ["_findStagingObjective", {
        params ["_targetId", "_side"];
        if (isNil "FLO_Objectives") exitWith {nil};
        private _targetObj = FLO_Objectives get _targetId;
        if (isNil "_targetObj") exitWith {nil};
        private _targetPos = _targetObj get "position";
        private _candidates = [];
        {
            if (_x == _targetId) exitWith {};
            private _obj = FLO_Objectives get _x;
            if (isNil "_obj") exitWith {};
            private _pos = _obj get "position";
            private _owner = _obj getOrDefault ["owner", east];
            // Only filter by side (can relax if needed)
            if (_owner != _side) exitWith {};
            private _dist = _targetPos distance2D _pos;
            _candidates pushBack [_x, _obj, _dist];
        } forEach (keys FLO_Objectives);
        if (count _candidates == 0) exitWith {
            ["AI Commander", 2, format["No valid staging objective found for %1. Skipping staging point.", _targetId]] call FLO_fnc_log;
            nil
        };
        _candidates = [_candidates, [], { _x select 2 }, "ASCEND"] call BIS_fnc_sortBy;
        private _chosen = _candidates select 0;
        ["AI Commander", 3, format["Chose staging objective %1 at distance %2m", _chosen select 0, _chosen select 2]] call FLO_fnc_log;
        _chosen
    }],

    // Enhanced staging point generation with multiple staging areas and concealment
    ["_generateStagingPoint", {
        params ["_targetPos", "_operationType", "_distance", ["_targetId", ""], ["_multiStaging", false]];
        private _stagingPositions = [];
        private _side = east; // Default to OPFOR, can be parameterized if needed

        if (_targetId != "" && {!isNil "FLO_Objectives"}) then {
            private _stagingObj = _self call ["_findStagingObjective", [_targetId, _side]];
            if (!isNil "_stagingObj") then {
                private _objId = _stagingObj select 0;
                private _obj = _stagingObj select 1;
                private _pos = _obj get "position";
                private _radius = _obj getOrDefault ["radius", 100];

                if (_multiStaging && _operationType == "ATTACK") then {
                    // Generate multiple staging points for coordinated attacks
                    private _numStaging = 2 + floor(random 2); // 2-3 staging areas
                    for "_i" from 1 to _numStaging do {
                        private _dir = (360 / _numStaging) * _i + random 60 - 30; // Spread around target
                        private _dist = _distance + random 200;
                        private _stagingPos = _targetPos getPos [_dist, _dir];

                        // Try to find concealed position (near trees, buildings, or terrain features)
                        private _concealedPos = _self call ["_findConcealedPosition", [_stagingPos, 150]];
                        if (count _concealedPos > 0) then {
                            _stagingPos = _concealedPos;
                        };

                        // Ensure staging position is on land
                        if (surfaceIsWater _stagingPos) then {
                            _stagingPos = [_stagingPos, 500] call FLO_fnc_getSafeLandPos;
                        };

                        _stagingPositions pushBack _stagingPos;
                    };
                } else {
                    // Single staging point with concealment
                    private _dir = random 360;
                    private _dist = random (_radius * 0.8);
                    private _stagingPos = _pos getPos [_dist, _dir];

                    // Try to find concealed position
                    private _concealedPos = _self call ["_findConcealedPosition", [_stagingPos, 100]];
                    if (count _concealedPos > 0) then {
                        _stagingPos = _concealedPos;
                    };

                    // Ensure staging position is on land
                    if (surfaceIsWater _stagingPos) then {
                        _stagingPos = [_stagingPos, 500] call FLO_fnc_getSafeLandPos;
                    };

                    _stagingPositions pushBack _stagingPos;
                };
            } else {
                ["AI Commander", 2, format["No valid staging objective found for %1. Skipping staging point.", _targetId]] call FLO_fnc_log;
            };
        };

        if (count _stagingPositions == 0) exitWith {[]};
        ["AI Commander", 3, format["Generated %1 staging point(s) for %2 operation against %3", count _stagingPositions, _operationType, _targetPos]] call FLO_fnc_log;

        // Return single position for compatibility, or array for multi-staging
        if (_multiStaging) then {_stagingPositions} else {_stagingPositions select 0}
    }],

    // Find concealed positions for staging areas
    ["_findConcealedPosition", {
        params ["_centerPos", "_searchRadius"];

        // Look for positions near trees, buildings, or terrain features
        private _trees = nearestObjects [_centerPos, ["Tree", "Bush"], _searchRadius];
        private _buildings = nearestObjects [_centerPos, ["House", "Building"], _searchRadius];
        private _concealmentObjects = _trees + _buildings;

        if (count _concealmentObjects > 0) then {
            private _selectedObject = selectRandom _concealmentObjects;
            private _objectPos = getPos _selectedObject;

            // Position near the concealment object
            private _dir = random 360;
            private _dist = 20 + random 30; // 20-50m from concealment
            private _concealedPos = _objectPos getPos [_dist, _dir];

            // Ensure position is not in water and has reasonable terrain
            if (!surfaceIsWater _concealedPos && {getTerrainHeightASL _concealedPos > 0}) then {
                _concealedPos
            } else {
                []
            };
        } else {
            []
        };
    }],

    // Create staging operation with enhanced coordination and multi-staging
    ["_createStagingOperation", {
        params ["_targetPos", "_targetId", "_operationType", "_priority"];
        private _cfg = _self get "_config";
        private _operation = createHashMap;

        // Calculate staging distance from config
        private _distConfig = if (_operationType == "ATTACK") then {
            _cfg get "stagingDistanceAttack"
        } else {
            _cfg get "stagingDistanceDefense"
        };
        private _distance = (_distConfig select 0) + random (_distConfig select 1);

        // Determine if this should be a multi-staging operation (high priority attacks)
        private _multiThreshold = _cfg get "multiStagingThreshold";
        private _useMultiStaging = (_operationType == "ATTACK" && _priority >= _multiThreshold);

        _operation set ["operationType", _operationType];
        _operation set ["targetId", _targetId];
        _operation set ["targetPos", _targetPos];
        _operation set ["priority", _priority];
        _operation set ["stagingPos", _self call ["_generateStagingPoint", [_targetPos, _operationType, _distance, _targetId, _useMultiStaging]]];
        _operation set ["multiStaging", _useMultiStaging];
        _operation set ["groups", []];
        _operation set ["startTime", diag_tickTime];
        _operation set ["operationLaunched", false];
        _operation set ["minForce", _self get "_minStagingForce"];
        _operation set ["maxForce", if (_useMultiStaging) then {_cfg get "maxStagingForceMulti"} else {_self get "_maxStagingForce"}];
        _operation set ["stageTime", if (_operationType == "ATTACK") then {_self get "_attackStageTime"} else {_self get "_defenseStageTime"}];

        // Enhanced staging for attacks includes preparatory phase
        if (_operationType == "ATTACK") then {
            _operation set ["preparatoryPhase", true];
            _operation set ["preparatoryTime", _cfg get "preparatoryFireTime"];
        };

        _operation
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
        
        ["AI Commander", 3, format["Initialized with %1 virtual groups", count _garrisonedGroups]] call FLO_fnc_log;
    }],

    // Assign groups to staged attack with better coordination
    ["_assignGroupToAttack", {
        params ["_targetPos", "_targetType", "_priority"];
        
        // Recalculate max attacking groups based on current player count
        _self set ["_maxAttackingGroups", _self call ["_calculateMaxAttackingGroups", []]];
        
        // Check if we're at the attack group limit
        if (count (_self get "_activeAttackGroups") >= (_self get "_maxAttackingGroups")) exitWith {
            ["AI Commander", 3, format["Maximum attacking groups reached (%1 groups)", _self get "_maxAttackingGroups"]] call FLO_fnc_log;
            false
        };
        
        // Get or create attack operation
        private _ops = _self get "_attackOperations";
        private _op = _ops getOrDefault [_targetType, nil];
        
        if (isNil "_op") then {
            _op = _self call ["_createStagingOperation", [_targetPos, _targetType, "ATTACK", _priority]];
            _ops set [_targetType, _op];
            _self set ["_attackOperations", _ops];
            ["AI Commander", 3, format["Created new attack operation for %1", _targetType]] call FLO_fnc_log;
        };
        
        private _currentGroups = _op get "groups";
        if (count _currentGroups >= (_op get "maxForce")) exitWith {
            ["AI Commander", 3, format["Attack operation %1 already at maximum force", _targetType]] call FLO_fnc_log;
            false
        };
        
        // Find available garrison groups using dynamic requirements
        private _availableGroups = _self get "_garrisonedGroups";
        private _strategicReserve = _self get "_strategicReserve";
        private _dynamicMinGarrison = _self call ["_calculateDynamicGarrisonRequirements", []];

        // Exclude strategic reserve from normal operations unless critical
        private _availableNonReserve = _availableGroups - _strategicReserve;

        if (count _availableNonReserve <= _dynamicMinGarrison) exitWith {
            ["AI Commander", 3, format["Cannot assign more attack groups - dynamic garrison requirement: %1, available: %2", _dynamicMinGarrison, count _availableNonReserve]] call FLO_fnc_log;
            false
        };
        
        // Get all virtual groups (using cache)
        private _virtualGroups = _self call ["_getMilitaryGroups", []];

        // Sort groups by priority: capability first, then distance to staging point
        private _stagingPos = _op get "stagingPos";
        private _sortedGroups = [_availableNonReserve, [], {
            private _groupData = _virtualGroups get _x;
            private _groupPos = _groupData get "position";
            private _groupType = _groupData get "groupType";

            // Priority scoring: capability (higher is better) + distance penalty
            private _capabilityScore = switch (_groupType) do {
                case "armor": { 1000 };
                case "mechanized": { 800 };
                case "motorized": { 600 };
                case "infantry": { 400 };
                default { 200 };
            };

            private _distance = _groupPos distance2D _stagingPos;
            private _distancePenalty = _distance / 10; // 1 point per 10m

            _capabilityScore - _distancePenalty
        }, "DESCEND"] call BIS_fnc_sortBy;
        
        // Calculate how many groups we can assign to this operation
        private _slotsInOperation = (_op get "maxForce") - count (_currentGroups);
        private _availableCount = count _availableNonReserve - _dynamicMinGarrison;
        private _remainingSlots = (_self get "_maxAttackingGroups") - count (_self get "_activeAttackGroups");
        private _groupsToAssign = _availableCount min _remainingSlots min _slotsInOperation min 2; // Assign up to 2 groups per cycle
        
        // Assign groups to staging
        private _assignedGroups = [];
        for "_i" from 0 to (_groupsToAssign - 1) do {
            if (_i < count _sortedGroups) then {
                private _selectedGroupId = _sortedGroups select _i;
                private _groupData = _virtualGroups get _selectedGroupId;
                
                // Clear existing waypoints first
                _groupData set ["waypoints", []];
                _groupData set ["currentWaypointIndex", 0];
                
                // If group was reinforcing, clear that status
                if (_groupData getOrDefault ["isReinforcing", false]) then {
                    _groupData set ["isReinforcing", false];
                    ["AI Commander", 3, format["Intercepted reinforcing group %1 for attack staging", _selectedGroupId]] call FLO_fnc_log;
                };
                
                // Update group assignments
                private _garrisonedGroups = _self get "_garrisonedGroups";
                private _activeAttackGroups = _self get "_activeAttackGroups";
                _garrisonedGroups deleteAt (_garrisonedGroups find _selectedGroupId);
                _activeAttackGroups pushBack _selectedGroupId;
                
                // Set up staging waypoints
                private _waypoints = [[_stagingPos, "MOVE", "AWARE", "NORMAL", "WEDGE", "YELLOW", 30]];
                [_selectedGroupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;

                // Add to operation
                _currentGroups pushBack _selectedGroupId;
                _op set ["groups", _currentGroups];

                _groupData set ["currentOrder", "STAGING"];
                _groupData set ["attackObjective", _targetType];
                _groupData set ["operationId", _targetType];
                
                _assignedGroups pushBack _selectedGroupId;
                ["AI Commander", 3, format["Assigned group %1 to attack staging for %2", _selectedGroupId, _targetType]] call FLO_fnc_log;
            };
        };
        
        count _assignedGroups > 0
    }],

    // Assign groups to staged defense with coordination
    ["_assignGroupToDefend", {
        params ["_targetPos", "_reason", "_objectiveId", "_priority"];
        
        // Check if we're at the defense group limit
        if (count (_self get "_activeDefenseGroups") >= (_self get "_maxDefendingGroups")) exitWith {
            ["AI Commander", 3, "Maximum defending groups reached"] call FLO_fnc_log;
            false
        };
        
        // Get or create defense operation
        private _ops = _self get "_defenseOperations";
        private _opId = format["DEF_%1", _objectiveId];
        private _op = _ops getOrDefault [_opId, nil];
        
        if (isNil "_op") then {
            _op = _self call ["_createStagingOperation", [_targetPos, _objectiveId, "DEFENSE", _priority]];
            // Defense operations have smaller staging time and force requirements
            _op set ["minForce", 1]; // Can launch with single group for urgent defense
            _op set ["maxForce", 3]; // Smaller defense forces
            _ops set [_opId, _op];
            _self set ["_defenseOperations", _ops];
            ["AI Commander", 3, format["Created new defense operation for %1 - %2", _objectiveId, _reason]] call FLO_fnc_log;
        };
        
        private _currentGroups = _op get "groups";
        if (count _currentGroups >= (_op get "maxForce")) exitWith {
            ["AI Commander", 3, format["Defense operation %1 already at maximum force", _opId]] call FLO_fnc_log;
            false
        };
        
        // Find available garrison groups using dynamic requirements
        private _availableGroups = _self get "_garrisonedGroups";
        private _strategicReserve = _self get "_strategicReserve";
        private _dynamicMinGarrison = _self call ["_calculateDynamicGarrisonRequirements", []];

        // For critical defense, can use strategic reserve
        private _availableForDefense = if (_priority >= 3) then {
            _availableGroups // Can use all groups including reserve for critical defense
        } else {
            _availableGroups - _strategicReserve // Normal defense excludes reserve
        };

        if (count _availableForDefense <= _dynamicMinGarrison) exitWith {
            ["AI Commander", 3, format["Cannot assign more defense groups - dynamic garrison requirement: %1, available: %2", _dynamicMinGarrison, count _availableForDefense]] call FLO_fnc_log;
            false
        };
        
        // Get all virtual groups (using cache)
        private _virtualGroups = _self call ["_getMilitaryGroups", []];

        // Sort groups by capability and distance for defense
        private _stagingPos = _op get "stagingPos";
        private _sortedGroups = [_availableForDefense, [], {
            private _groupData = _virtualGroups get _x;
            private _groupPos = _groupData get "position";
            private _groupType = _groupData get "groupType";

            // Defense priority: fast response units first, then heavy units
            private _capabilityScore = switch (_groupType) do {
                case "motorized": { 1000 }; // Fast response
                case "mechanized": { 900 };
                case "armor": { 800 }; // Heavy but slower
                case "infantry": { 600 };
                default { 400 };
            };

            private _distance = _groupPos distance2D _stagingPos;
            private _distancePenalty = _distance / 5; // Higher penalty for defense (need fast response)

            _capabilityScore - _distancePenalty
        }, "DESCEND"] call BIS_fnc_sortBy;
        
        // Calculate how many groups we can assign
        private _slotsInOperation = (_op get "maxForce") - count (_currentGroups);
        private _availableCount = count _availableForDefense - _dynamicMinGarrison;
        private _remainingSlots = (_self get "_maxDefendingGroups") - count (_self get "_activeDefenseGroups");
        private _groupsToAssign = _availableCount min _remainingSlots min _slotsInOperation min 2; // Assign up to 2 groups per cycle
        
        // Assign groups to defense staging
        private _assignedGroups = [];
        for "_i" from 0 to (_groupsToAssign - 1) do {
            if (_i < count _sortedGroups) then {
                private _selectedGroupId = _sortedGroups select _i;
                private _groupData = _virtualGroups get _selectedGroupId;
                
                // Clear existing waypoints first
                _groupData set ["waypoints", []];
                _groupData set ["currentWaypointIndex", 0];
                
                // If group was reinforcing, clear that status
                if (_groupData getOrDefault ["isReinforcing", false]) then {
                    _groupData set ["isReinforcing", false];
                    ["AI Commander", 3, format["Intercepted reinforcing group %1 for defense staging", _selectedGroupId]] call FLO_fnc_log;
                };
                
                // Update group assignments
                private _garrisonedGroups = _self get "_garrisonedGroups";
                private _activeDefenseGroups = _self get "_activeDefenseGroups";
                _garrisonedGroups deleteAt (_garrisonedGroups find _selectedGroupId);
                _activeDefenseGroups pushBack _selectedGroupId;
                
                // Set up staging waypoints for defense
                private _waypoints = [[_stagingPos, "MOVE", "COMBAT", "NORMAL", "WEDGE", "YELLOW", 20]];
                [_selectedGroupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;

                // Add to operation
                _currentGroups pushBack _selectedGroupId;
                _op set ["groups", _currentGroups];

                // Attach group to this objective for future garrisoning
                _groupData set ["garrisonObjective", _objectiveId];
                _groupData set ["garrisonPosition", [_objectiveId] call FLO_fnc_getRandomObjectivePos];
                _groupData set ["currentOrder", "STAGING"];
                _groupData set ["operationId", _opId];
                
                _assignedGroups pushBack _selectedGroupId;
                ["AI Commander", 3, format["Assigned group %1 to defense staging for %2 - %3", _selectedGroupId, _objectiveId, _reason]] call FLO_fnc_log;
            };
        };
        
        count _assignedGroups > 0
    }],

    // Return group to garrison with better operation cleanup
    ["_returnGroupToGarrison", {
        params ["_groupId", "_currentRole"];

        // Safety check for virtualization system
        if (isNil "FLO_virtualGroups") exitWith {
            ["AI Commander", 2, format["Cannot return group %1 - virtualization not initialized", _groupId]] call FLO_fnc_log;
        };

        // Get the group's data with proper nil handling
        private _groups = FLO_virtualGroups getOrDefault ["_groups", createHashMap];
        private _groupData = _groups getOrDefault [_groupId, nil];
        if (isNil "_groupData") exitWith {
            ["AI Commander", 3, format["Failed to return group %1 to garrison - group not found", _groupId]] call FLO_fnc_log;
        };
        
        // Check if group still has waypoints to complete
        private _waypoints = _groupData getOrDefault ["waypoints", []];
        if (count _waypoints > 0) exitWith {
            ["AI Commander", 4, format["Group %1 still has waypoints to complete - keeping on task", _groupId]] call FLO_fnc_log;
        };
        
        // Clean up operation assignments
        private _operationId = _groupData getOrDefault ["operationId", ""];
        if (_operationId != "") then {
            private _ops = if (_currentRole == "ATTACK") then {_self get "_attackOperations"} else {_self get "_defenseOperations"};
            private _op = _ops getOrDefault [_operationId, nil];
            if (!isNil "_op") then {
                private _groups = _op get "groups";
                _groups deleteAt (_groups find _groupId);
                _op set ["groups", _groups];
                if (count _groups == 0) then {
                    _ops deleteAt _operationId;
                    ["AI Commander", 3, format["Cleaned up empty operation %1", _operationId]] call FLO_fnc_log;
                };
            };
            _groupData deleteAt "operationId";
        };
        
        // Determine garrison position based on assigned objective
        private _garrisonPos = _groupData getOrDefault ["garrisonPosition", _groupData get "position"];
        private _objId = _groupData getOrDefault ["garrisonObjective", ""];
        if (_objId != "" && {!isNil "FLO_Objectives"}) then {
            private _odata = FLO_Objectives get _objId;
            if (!isNil "_odata") then { _garrisonPos = [_objId] call FLO_fnc_getRandomObjectivePos; };
        };
        
        // Update group assignments
        private _garrisonedGroups = _self get "_garrisonedGroups";
        private _activeGroups = _self get (["_activeAttackGroups", "_activeDefenseGroups"] select (_currentRole == "DEFEND"));
        _activeGroups deleteAt (_activeGroups find _groupId);
        _garrisonedGroups pushBack _groupId;

        // Update group data so next time it's pulled it knows its garrison objective
        _groupData set ["garrisonPosition", _garrisonPos];
        _groupData set ["garrisonObjective", _objId];
        _groupData set ["currentOrder", "GARRISON"];
        
        // Set up return waypoints
        private _waypoints = [
            [_garrisonPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 10]  // Tighter radius for garrison positions
        ];
        [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
        
        ["AI Commander", 3, format["Returned group %1 to garrison from %2 role", _groupId, _currentRole]] call FLO_fnc_log;
    }],

    ["_assessThreats", {
        private _threats = [];

        if (isNil "FLO_Objectives") exitWith {[]};

        private _bluforUnits = allUnits select {side _x == west && alive _x && !(captive _x)};

        {
            private _id = _x;
            private _data = FLO_Objectives get _id;
            if (isNil "_data") then { continue };

            private _pos = _data get "position";
            private _priority = _data getOrDefault ["priority",50];
            private _owner = _data getOrDefault ["owner", east];
            private _near = _bluforUnits inAreaArray [_pos, 500, 500];
            private _count = count _near;

            if (_owner == east) then {
                if (_count > 0) then {
                    private _score = _priority + (_count * 10);
                    _threats pushBack ["DEFEND", _id, _pos, _score];
                };
            } else {
                private _score = _priority + (_count * 10);
                _threats pushBack ["ATTACK", _id, _pos, _score];
            };
        } forEach (keys FLO_Objectives);

        // Additional threat: roaming BLUFOR groups not tied to an objective
        private _bluforGroups = allGroups select {side _x == west};
        {
            private _group = _x;
            private _units = units _group select {alive _x && !(captive _x)};
            if (count _units > 2) then {
                private _p = getPos (leader _group);
                private _score = count _units * 10;
                _threats pushBack ["ATTACK", str _group, _p, _score];
            };
        } forEach _bluforGroups;

        _threats = [_threats, [], {_x select 3}, "DESCEND"] call BIS_fnc_sortBy;

        _threats
    }],

    // === GTN HELPER METHODS ===
    // These methods are called by the GTN executor to interface with commander operations

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

        private _groups = (FLO_virtualGroups get "_groups");
        private _gData = _groups getOrDefault [_groupId, nil];
        if (isNil "_gData") exitWith { false };

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

        private _groups = (FLO_virtualGroups get "_groups");
        private _gData = _groups getOrDefault [_groupId, nil];
        if (isNil "_gData") exitWith { false };

        // Remove from garrison, add to attack
        private _garrisoned = _self get "_garrisonedGroups";
        private _attacking = _self get "_activeAttackGroups";

        _garrisoned deleteAt (_garrisoned find _groupId);
        if !(_groupId in _attacking) then { _attacking pushBack _groupId };

        private _waypoints = [
            [_targetPos, "SAD", "COMBAT", "FULL", "WEDGE", "RED", 75],
            [_targetPos, "DESTROY", "COMBAT", "NORMAL", "LINE", "RED", 50]
        ];

        [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
        _gData set ["currentOrder", "ATTACK"];

        true
    }],

    // Order a group to defend a position (for GTN)
    ["_orderGroupDefend", {
        params ["_groupId", "_targetPos"];

        private _groups = (FLO_virtualGroups get "_groups");
        private _gData = _groups getOrDefault [_groupId, nil];
        if (isNil "_gData") exitWith { false };

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
        ["AI Commander", 3, "Initializing GTN subsystem"] call FLO_fnc_log;

        private _gtn = [_self] call FLO_fnc_gtnCommander;
        _self set ["_gtnCommander", _gtn];

        if (!isNil "_gtn") then {
            _self set ["_gtnEnabled", true];
            _gtn call ["_start", []];
            ["AI Commander", 2, "GTN Commander initialized and started"] call FLO_fnc_log;
        } else {
            ["AI Commander", 1, "Failed to initialize GTN Commander"] call FLO_fnc_log;
        };
    }],

    // Toggle GTN mode
    ["_setGTNEnabled", {
        params ["_enabled"];
        _self set ["_gtnEnabled", _enabled];

        private _gtn = _self get "_gtnCommander";
        if (!isNil "_gtn") then {
            if (_enabled) then {
                _gtn call ["_start", []];
            } else {
                _gtn call ["_stop", []];
            };
        };

        ["AI Commander", 2, format["GTN mode: %1", if (_enabled) then {"ENABLED"} else {"DISABLED"}]] call FLO_fnc_log;
    }],

    // === END GTN HELPER METHODS ===

    // Process both attack and defense staging operations
    ["_processStagingOperations", {
        _self call ["_processAttackOperations", []];
        _self call ["_processDefenseOperations", []];
    }],

    ["_processAttackOperations", {
        private _ops = _self get "_attackOperations";
        private _cfg = _self get "_config";
        private _toRemove = [];
        private _stagingRadius = _cfg get "stagingArrivalRadius";
        private _forceActivate = _cfg get "forceActivateForOperations";

        {
            private _id = _x;
            private _op = _y;
            private _groups = _op get "groups";
            private _launched = _op get "operationLaunched";
            private _stagePos = _op get "stagingPos";
            private _targetPos = _op get "targetPos";
            private _stageTime = _op get "stageTime";
            private _minForce = _op get "minForce";
            private _priority = _op get "priority";

            if (!_launched) then {
                // CRITICAL: Force-activate groups for operations if enabled
                if (_forceActivate) then {
                    {
                        private _gData = (FLO_virtualGroups get "_groups") get _x;
                        if (!isNil "_gData" && {!(_gData getOrDefault ["isActive", false])}) then {
                            [_x, _gData] call FLO_fnc_activateVirtualGroup;
                            ["AI Commander", 3, format["Force-activated group %1 for attack operation %2", _x, _id]] call FLO_fnc_log;
                        };
                    } forEach _groups;
                };

                // Check how many groups are ready at staging point
                private _ready = [];
                private _enRoute = [];
                {
                    private _gData = (FLO_virtualGroups get "_groups") get _x;
                    if (isNil "_gData") then { continue };
                    private _pos = _gData get "position";
                    if (_pos distance2D _stagePos < _stagingRadius) then {
                        _ready pushBack _x;
                    } else {
                        _enRoute pushBack _x;
                    };
                } forEach _groups;
                
                private _timeElapsed = diag_tickTime - (_op get "startTime");
                private _shouldLaunch = false;
                
                // Launch conditions:
                // 1. All groups are ready, OR
                // 2. Minimum force is ready and staging time exceeded, OR  
                // 3. Timeout reached (don't wait forever)
                if (count _ready >= count _groups) then {
                    _shouldLaunch = true;
                    ["AI Commander", 3, format["Attack operation %1: All %2 groups ready - launching", _id, count _ready]] call FLO_fnc_log;
                } else {
                    if (count _ready >= _minForce && _timeElapsed > _stageTime) then {
                        _shouldLaunch = true;
                        ["AI Commander", 3, format["Attack operation %1: %2/%3 groups ready, time exceeded - launching", _id, count _ready, count _groups]] call FLO_fnc_log;
                    } else {
                        if (_timeElapsed > (_stageTime * 2)) then {
                            _shouldLaunch = true;
                            ["AI Commander", 3, format["Attack operation %1: Timeout reached with %2/%3 groups - launching", _id, count _ready, count _groups]] call FLO_fnc_log;
                        };
                    };
                };
                
                if (_shouldLaunch) then {
                    // Enhanced preparatory fires and air support
                    private _prepRounds = _cfg get "preparatoryFireRounds";
                    _self call ["_callArtillerySupport", [_targetPos, _prepRounds, "PREPARATORY", 1]];
                    _self call ["_callAirSupport", [_targetPos, "BOMB", "", -1, "PREPARATORY"]];

                    // SEAD mission if high-value target
                    private _multiThreshold = _cfg get "multiStagingThreshold";
                    if (_priority >= _multiThreshold) then {
                        _self call ["_callAirSupport", [_targetPos, "LASER", "", -1, "SEAD"]];
                    };

                    // Launch attack with ready groups
                    {
                        private _gData = (FLO_virtualGroups get "_groups") get _x;
                        if (isNil "_gData") then { continue };
                        
                        // Create multiple waypoints for coordinated attack
                        private _attackWaypoints = [
                            [_targetPos, "SAD", "COMBAT", "NORMAL", "WEDGE", "RED", 75], // Main assault
                            [_targetPos, "DESTROY", "COMBAT", "NORMAL", "LINE", "RED", 50] // Follow-up destruction
                        ];
                        [_x, _attackWaypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
                        _gData set ["currentOrder", "ATTACK"];
                    } forEach _ready;
                    
                    // Send stragglers directly to target if any
                    {
                        private _gData = (FLO_virtualGroups get "_groups") get _x;
                        if (isNil "_gData") then { continue };
                        private _directWaypoints = [[_targetPos, "SAD", "COMBAT", "NORMAL", "WEDGE", "RED", 75]];
                        [_x, _directWaypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
                        _gData set ["currentOrder", "ATTACK"];
                        ["AI Commander", 3, format["Sending straggler group %1 directly to attack", _x]] call FLO_fnc_log;
                    } forEach _enRoute;
                    
                    _op set ["operationLaunched", true];
                    _op set ["launchTime", diag_tickTime];

                    // Track metrics
                    _self call ["_updateMetric", ["attacksLaunched", 1, "INC"]];
                    private _stagingTime = diag_tickTime - (_op get "startTime");
                    _self call ["_updateMetric", ["totalStagingTime", _stagingTime, "ADD"]];
                    _self call ["_updateMetric", ["stagingCount", 1, "INC"]];
                    private _metrics = _self get "_metrics";
                    _metrics set ["avgStagingTime", (_metrics get "totalStagingTime") / (_metrics get "stagingCount")];
                };
            } else {
                // Check if attack is complete or failed
                private _aliveGroups = _groups select {
                    _x in (_self get "_activeAttackGroups") && 
                    {!isNil ((FLO_virtualGroups get "_groups") get _x)}
                };
                
                if (count _aliveGroups == 0) then {
                    _toRemove pushBack _id;
                    ["AI Commander", 3, format["Attack operation %1 completed - no groups remaining", _id]] call FLO_fnc_log;
                    // Track as successful if objective was captured (groups eliminated means they fought)
                    _self call ["_updateMetric", ["attacksSuccessful", 1, "INC"]];
                } else {
                    // Check if attack has been running too long without progress
                    private _launchTime = _op getOrDefault ["launchTime", diag_tickTime];
                    private _attackTimeout = _cfg get "attackTimeout";
                    if (diag_tickTime - _launchTime > _attackTimeout) then {
                        _toRemove pushBack _id;
                        ["AI Commander", 3, format["Attack operation %1 timed out - recalling groups", _id]] call FLO_fnc_log;
                        _self call ["_updateMetric", ["attacksFailed", 1, "INC"]];
                        // Recall remaining groups
                        {
                            _self call ["_returnGroupToGarrison", [_x, "ATTACK"]];
                        } forEach _aliveGroups;
                    };
                };
            };
            _ops set [_id, _op];
        } forEach _ops;

        { _ops deleteAt _x; } forEach _toRemove;
        _self set ["_attackOperations", _ops];
    }],

    // Process defense staging operations
    ["_processDefenseOperations", {
        private _ops = _self get "_defenseOperations";
        private _cfg = _self get "_config";
        private _toRemove = [];
        private _stagingRadius = _cfg get "defenseStagingArrivalRadius";
        private _forceActivate = _cfg get "forceActivateForOperations";

        {
            private _id = _x;
            private _op = _y;
            private _groups = _op get "groups";
            private _launched = _op get "operationLaunched";
            private _stagePos = _op get "stagingPos";
            private _targetPos = _op get "targetPos";
            private _stageTime = _op get "stageTime";
            private _minForce = _op get "minForce";

            if (!_launched) then {
                // CRITICAL: Force-activate groups for defense operations if enabled
                if (_forceActivate) then {
                    {
                        private _gData = (FLO_virtualGroups get "_groups") get _x;
                        if (!isNil "_gData" && {!(_gData getOrDefault ["isActive", false])}) then {
                            [_x, _gData] call FLO_fnc_activateVirtualGroup;
                            ["AI Commander", 3, format["Force-activated group %1 for defense operation %2", _x, _id]] call FLO_fnc_log;
                        };
                    } forEach _groups;
                };

                // Check how many groups are ready at staging point
                private _ready = [];
                private _enRoute = [];
                {
                    private _gData = (FLO_virtualGroups get "_groups") get _x;
                    if (isNil "_gData") then { continue };
                    private _pos = _gData get "position";
                    if (_pos distance2D _stagePos < _stagingRadius) then {
                        _ready pushBack _x;
                    } else {
                        _enRoute pushBack _x;
                    };
                } forEach _groups;
                
                private _timeElapsed = diag_tickTime - (_op get "startTime");
                private _shouldLaunch = false;
                
                // Defense launches faster than attack (more urgent)
                if (count _ready >= _minForce) then {
                    if (count _ready >= count _groups || _timeElapsed > _stageTime) then {
                        _shouldLaunch = true;
                        ["AI Commander", 3, format["Defense operation %1: %2/%3 groups ready - launching QRF", _id, count _ready, count _groups]] call FLO_fnc_log;
                    };
                } else {
                    if (_timeElapsed > (_stageTime * 1.5)) then {
                        _shouldLaunch = true;
                        ["AI Commander", 3, format["Defense operation %1: Emergency launch with %2/%3 groups", _id, count _ready, count _groups]] call FLO_fnc_log;
                    };
                };
                
                if (_shouldLaunch) then {
                    // Launch defense with ready groups
                    {
                        private _gData = (FLO_virtualGroups get "_groups") get _x;
                        if (isNil "_gData") then { continue };
                        
                        // Defense waypoints with overwatch positions
                        private _defenseWaypoints = [
                            [_targetPos, "MOVE", "COMBAT", "NORMAL", "WEDGE", "RED", 40], // Move to defend
                            [_targetPos, "GUARD", "COMBAT", "NORMAL", "LINE", "RED", 60] // Set up defensive positions
                        ];
                        [_x, _defenseWaypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
                        _gData set ["currentOrder", "DEFEND"];
                    } forEach _ready;
                    
                    // Send remaining groups directly to defense point
                    {
                        private _gData = (FLO_virtualGroups get "_groups") get _x;
                        if (isNil "_gData") then { continue };
                        private _directWaypoints = [[_targetPos, "MOVE", "COMBAT", "NORMAL", "WEDGE", "RED", 40]];
                        [_x, _directWaypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
                        _gData set ["currentOrder", "DEFEND"];
                    } forEach _enRoute;
                    
                    _op set ["operationLaunched", true];
                    _op set ["launchTime", diag_tickTime];

                    // Track metrics
                    _self call ["_updateMetric", ["defensesLaunched", 1, "INC"]];
                };
            } else {
                // Check if defense is complete
                private _aliveGroups = _groups select {
                    _x in (_self get "_activeDefenseGroups") &&
                    {((FLO_virtualGroups get "_groups") getOrDefault [_x, nil]) isNotEqualTo nil}
                };

                if (count _aliveGroups == 0) then {
                    _toRemove pushBack _id;
                    ["AI Commander", 3, format["Defense operation %1 completed - no groups remaining", _id]] call FLO_fnc_log;
                    _self call ["_updateMetric", ["defensesSuccessful", 1, "INC"]];
                } else {
                    // Check if defense has been running too long
                    private _launchTime = _op getOrDefault ["launchTime", diag_tickTime];
                    private _defenseTimeout = _cfg get "defenseTimeout";
                    if (diag_tickTime - _launchTime > _defenseTimeout) then {
                        _toRemove pushBack _id;
                        ["AI Commander", 3, format["Defense operation %1 timed out - recalling groups", _id]] call FLO_fnc_log;
                        // Recall remaining groups
                        {
                            _self call ["_returnGroupToGarrison", [_x, "DEFEND"]];
                        } forEach _aliveGroups;
                    };
                };
            };
            _ops set [_id, _op];
        } forEach _ops;

        { _ops deleteAt _x; } forEach _toRemove;
        _self set ["_defenseOperations", _ops];
    }],

    // Enhanced artillery support with preparatory fires and mission tracking
    ["_callArtillerySupport", {
        params ["_self", "_targetPos", ["_rounds", 6], ["_missionType", "IMMEDIATE"], ["_priority", 1]];

        private _artilleryMgr = _self get "_artilleryAssetManager";
        private _success = false;

        switch (_missionType) do {
            case "PREPARATORY": {
                // Preparatory fires before major operations
                private _prepRounds = _rounds * 2; // More rounds for prep fires
                _success = _artilleryMgr call ["_requestFireMission", [_targetPos, _prepRounds]];

                if (_success) then {
                    // Track preparatory fires
                    private _prepFires = _self get "_preparatoryFiresActive";
                    _prepFires set [str _targetPos, diag_tickTime];
                    _self set ["_preparatoryFiresActive", _prepFires];

                    ["AI Commander", 3, format["Preparatory artillery fires initiated at %1 (%2 rounds)", _targetPos, _prepRounds]] call FLO_fnc_log;
                };
            };

            case "SUPPRESSIVE": {
                // Ongoing suppressive fires during operations
                _success = _artilleryMgr call ["_requestFireMission", [_targetPos, _rounds]];

                if (_success) then {
                    // Schedule follow-up suppressive fires using spawn
                    [_targetPos, _artilleryMgr, _rounds] spawn {
                        params ["_pos", "_mgr", "_rounds"];
                        sleep 120;
                        _mgr call ["_requestFireMission", [_pos, _rounds]];
                    };

                    ["AI Commander", 3, format["Suppressive artillery fires at %1", _targetPos]] call FLO_fnc_log;
                };
            };

            case "COUNTER_BATTERY": {
                // Counter-battery fires against player artillery
                private _cbRounds = _rounds + 4; // More rounds for counter-battery
                _success = _artilleryMgr call ["_requestFireMission", [_targetPos, _cbRounds]];

                if (_success) then {
                    ["AI Commander", 2, format["Counter-battery fires at detected artillery position %1", _targetPos]] call FLO_fnc_log;
                };
            };

            default {
                // Immediate fires (original behavior)
                _success = _artilleryMgr call ["_requestFireMission", [_targetPos, _rounds]];
            };
        };

        if (_success) then {
            // Track the mission
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

            // Track metrics
            _self call ["_updateMetric", ["artilleryMissionsFired", 1, "INC"]];

            // Send notification
            private _grid = mapGridPosition _targetPos;
            ["STR_FLO_WARNING_TITLE", format ["%1 at grid %2", localize "STR_FLO_WARNING_EARTYINC", _grid], "warning"] call FLO_fnc_sendNotification;
        };

        _success
    }],

    ["_selectAirMission", {
        params ["_self", "_targetPos"];

        private _rad = 300;

        // Look for enemy vehicles around the target
        private _veh = vehicles select {
            side _x == west && alive _x && { _x distance2D _targetPos < _rad }
        };
        private _tanks = _veh select { _x isKindOf "Tank" };

        if (count _tanks > 0) exitWith {"LASER"};
        if (count _veh > 0) exitWith {"BOMB"};

        // Count infantry not inside vehicles
        private _inf = allUnits select {
            side _x == west && alive _x && { _x distance2D _targetPos < _rad } &&
            { vehicle _x == _x }
        };
        if (count _inf > 10) exitWith {"BOMB"};

        "CAS"
    }],

    // Enhanced air support with mission types and coordination
    ["_callAirSupport", {
        /*
            Enhanced air support system with multiple mission types:
            - PREPARATORY: Pre-attack strikes to soften targets
            - CAS: Close Air Support during operations
            - SEAD: Suppress Enemy Air Defenses
            - CAP: Combat Air Patrol for air superiority
            - INTERDICTION: Strike enemy supply lines/reinforcements
        */
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
                // Pre-attack strikes
                _mission = "BOMB";
                _alt = 400;
                _ato call ["_addTask", [_targetPos, _mission, _type, _alt]];

                // Schedule follow-up strike
                [_targetPos, _mission, _type, _alt, _ato] spawn {
                    params ["_pos", "_miss", "_typ", "_altitude", "_airTaskOrder"];
                    sleep (60 + random 60);
                    _airTaskOrder call ["_addTask", [_pos, _miss, _typ, _altitude]];
                };

                _success = true;
                ["AI Commander", 3, format["Preparatory air strikes ordered at %1", _targetPos]] call FLO_fnc_log;
            };

            case "SEAD": {
                // Suppress Enemy Air Defenses
                _mission = "LASER";
                _ato call ["_addTask", [_targetPos, _mission, _type, _alt]];
                _success = true;
                ["AI Commander", 3, format["SEAD mission ordered at %1", _targetPos]] call FLO_fnc_log;
            };

            case "CAP": {
                // Combat Air Patrol
                _mission = "CAP";
                _alt = if (_alt < 0) then { 300 } else { _alt };
                _ato call ["_addTask", [_targetPos, _mission, _type, _alt]];
                _success = true;
                ["AI Commander", 3, format["CAP mission queued at %1 via ATO", _targetPos]] call FLO_fnc_log;
            };

            case "INTERDICTION": {
                // Strike supply lines and reinforcements
                _mission = "BOMB";
                _ato call ["_addTask", [_targetPos, _mission, _type, _alt]];
                _success = true;
                ["AI Commander", 3, format["Interdiction strike ordered at %1", _targetPos]] call FLO_fnc_log;
            };

            default {
                // Immediate support
                _ato call ["_addTask", [_targetPos, _mission, _type, _alt]];
                _success = true;
            };
        };

        if (_success) then {
            // Track the air mission
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

            // Track metrics
            _self call ["_updateMetric", ["airMissionsFlown", 1, "INC"]];
        };

        _success
    }],
    
    ["_update", {
        // Safety check - ensure virtualization system exists
        if (isNil "FLO_virtualGroups") exitWith {
            ["AI Commander", 2, "Update skipped - virtualization system not initialized"] call FLO_fnc_log;
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
        private _deadGroups = [];
        {
            private _groupId = _x;
            private _groupData = (FLO_virtualGroups get "_groups") getOrDefault [_groupId, nil];
            
            // Only consider a group "dead" if:
            // 1. It doesn't exist in the virtual system at all, OR
            // 2. It's active (has a real group) but that real group is null/dead
            if (isNil "_groupData" || 
                {(_groupData getOrDefault ["isActive", false]) && 
                 {isNull (_groupData getOrDefault ["realGroup", grpNull])}}) then {
                _deadGroups pushBack _groupId;
                ["AI_COMMANDER", 2, format["Group %1 no longer exists or was eliminated, removing from tracking", _groupId]] call FLO_fnc_log;
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

            // Track groups lost metric
            _self call ["_updateMetric", ["groupsLost", count _deadGroups, "ADD"]];
            ["AI Commander", 3, format["Removed %1 dead groups from tracking", count _deadGroups]] call FLO_fnc_log;
        };
        
        // === GTN vs REACTIVE MODE ===
        // If GTN is enabled, let GTN handle strategic decisions
        // Otherwise, use the reactive threat-response system

        private _gtnEnabled = _self get "_gtnEnabled";
        private _gtn = _self get "_gtnCommander";

        if (_gtnEnabled && {!isNil "_gtn"}) then {
            // GTN Mode: Goal-driven planning
            _gtn call ["_update", []];
        } else {
            // Reactive Mode: Traditional threat-response
            // Get current threats
            private _threats = _self call ["_assessThreats", []];

            // Early exit if no threats
            if (count _threats > 0) then {
                // Process threats by type
                private _attackThreats = _threats select {_x select 0 == "ATTACK"};
                private _defenseThreats = _threats select {_x select 0 == "DEFEND"};

                // Handle defense threats first (protect our objectives)
                {
                    _x params ["_type", "_id", "_pos", "_strength"];
                    _self call ["_assignGroupToDefend", [_pos, format["Objective %1 under attack (%2 enemies)", _id, _strength], _id, 1]];
                } forEach _defenseThreats;

                // Then handle attack threats
                {
                    _x params ["_type", "_id", "_pos", "_strength"];
                    _self call ["_assignGroupToAttack", [_pos, _id, 1]];
                } forEach _attackThreats;
            };

            // Process staging and launch of operations (reactive mode only)
            _self call ["_processStagingOperations", []];
        };

        // Check if any active groups should return to garrison
        private _cfg = _self get "_config";
        private _attackReturnDist = _cfg get "attackReturnDistance";
        private _defenseReturnDist = _cfg get "defenseReturnDistance";

        {
            private _groupId = _x;
            private _groupData = (FLO_virtualGroups get "_groups") get _groupId;

            if (!isNull (_groupData getOrDefault ["realGroup", grpNull])) then {
                private _nearestEnemy = leader (_groupData get "realGroup") findNearestEnemy (leader (_groupData get "realGroup"));

                if (isNull _nearestEnemy || {_nearestEnemy distance (leader (_groupData get "realGroup")) > _attackReturnDist}) then {
                    _self call ["_returnGroupToGarrison", [_groupId, "ATTACK"]];
                };
            };
        } forEach (_self get "_activeAttackGroups");

        {
            private _groupId = _x;
            private _groupData = (FLO_virtualGroups get "_groups") get _groupId;

            if (!isNull (_groupData getOrDefault ["realGroup", grpNull])) then {
                private _nearestEnemy = leader (_groupData get "realGroup") findNearestEnemy (leader (_groupData get "realGroup"));

                if (isNull _nearestEnemy || {_nearestEnemy distance (leader (_groupData get "realGroup")) > _defenseReturnDist}) then {
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
            ["AI Commander", 4, format["Cleaned up %1 expired preparatory fires", count _expiredFires]] call FLO_fnc_log;
        };
    }]
]];

// Initialize Commander (strategy interval already set from config)
["AI Commander", 3, format["Initialized with strategy interval: %1s, update interval: %2s",
    _config get "strategyInterval", _config get "updateInterval"]] call FLO_fnc_log;

// Initialize groups
_aiCommander call ["_initializeGroups", []];

// Initialize GTN system if enabled in config
private _gtnEnabled = _config getOrDefault ["gtnEnabled", true];
if (_gtnEnabled) then {
    _aiCommander call ["_initializeGTN", []];
} else {
    ["AI Commander", 3, "GTN system disabled in config - using reactive mode"] call FLO_fnc_log;
};

// Start the commander loop
[_aiCommander, _config get "updateInterval"] spawn {
    params ["_commander", "_updateInterval"];

    while {true} do {
        _commander call ["_update", []];
        sleep _updateInterval;
    };
};

// Return the commander object
_aiCommander