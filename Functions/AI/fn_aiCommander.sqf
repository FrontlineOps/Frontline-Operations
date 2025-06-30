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

// Initialize variables
private _lastCommanderUpdate = diag_tickTime;
private _commanderUpdateInterval = 300; // 5 minutes between strategy updates
private _currentThreatLevel = 0;

// Set up the Commander object using a HashMap
private _aiCommander = createHashMapObject [[
    ["_threatLevel", _currentThreatLevel],
    ["_lastUpdate", _lastCommanderUpdate],
    ["_activeAttackGroups", []],
    ["_activeDefenseGroups", []],
    ["_garrisonedGroups", []],
    ["_attackOperations", createHashMap],
    ["_defenseOperations", createHashMap], // Defense staging operations
    ["_stagingPoints", createHashMap], // Global staging point management
    ["_maxAttackingGroups", 0],  // Will be set in initialize
    ["_maxDefendingGroups", 6],  // Maximum number of groups that can be defending/QRF simultaneously
    ["_minGarrisonGroups", 2],   // Minimum number of groups that must remain in garrison
    ["_attackStageTime", 280],
    ["_defenseStageTime", 120],  
    ["_minStagingForce", 2],     // Minimum units required before launching operation
    ["_maxStagingForce", 4],     // Maximum units for single operation
    ["_airTaskOrder", call FLO_fnc_airTaskOrder],

    ["_calculateMaxAttackingGroups", {
        private _playerCount = count (allPlayers - entities "HeadlessClient_F");
        
        // No attacks with 1-2 players
        if (_playerCount <= 2) exitWith { 0 };
        
        // Calculate groups: subtract 2 from player count and divide by 2 (rounded down)
        private _maxGroups = floor((_playerCount - 2) / 2);
        
        // Add aggression score
        private _AGGRSCORE = FLO_DifficultyHandle get "value";
        private _maxGroups = _maxGroups + floor (_AGGRSCORE / 4);
        
        // Cap at maximum of 16 groups
        _maxGroups = _maxGroups min 16;
        
        _maxGroups
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

    // Generate staging point for operations (must be inside a valid objective)
    ["_generateStagingPoint", {
        params ["_targetPos", "_operationType", "_distance", ["_targetId", ""]];
        private _stagingPos = [];
        private _side = east; // Default to OPFOR, can be parameterized if needed
        if (_targetId != "" && {!isNil "FLO_Objectives"}) then {
            private _stagingObj = _self call ["_findStagingObjective", [_targetId, _side]];
            if (!isNil "_stagingObj") then {
                private _objId = _stagingObj select 0;
                private _obj = _stagingObj select 1;
                private _pos = _obj get "position";
                private _radius = _obj getOrDefault ["radius", 100];
                // Pick a random point inside the objective's area
                private _dir = random 360;
                private _dist = random (_radius * 0.8);
                _stagingPos = _pos getPos [_dist, _dir];
            } else {
                ["AI Commander", 2, format["No valid staging objective found for %1. Skipping staging point.", _targetId]] call FLO_fnc_log;
            };
        };
        if (count _stagingPos == 0) exitWith {[]};
        ["AI Commander", 4, format["Generated %1 staging point at %2 for target %3", _operationType, _stagingPos, _targetPos]] call FLO_fnc_log;
        _stagingPos
    }],

    // Create staging operation with better coordination
    ["_createStagingOperation", {
        params ["_targetPos", "_targetId", "_operationType", "_priority"];
        private _operation = createHashMap;
        private _distance = if (_operationType == "ATTACK") then {500 + random 300} else {300 + random 200};
        _operation set ["operationType", _operationType];
        _operation set ["targetId", _targetId];
        _operation set ["targetPos", _targetPos];
        _operation set ["priority", _priority];
        _operation set ["stagingPos", _self call ["_generateStagingPoint", [_targetPos, _operationType, _distance, _targetId]]];
        _operation set ["groups", []];
        _operation set ["startTime", diag_tickTime];
        _operation set ["operationLaunched", false];
        _operation set ["minForce", _self get "_minStagingForce"];
        _operation set ["maxForce", _self get "_maxStagingForce"];
        _operation set ["stageTime", if (_operationType == "ATTACK") then {_self get "_attackStageTime"} else {_self get "_defenseStageTime"}];
        _operation
    }],

    ["_initializeGroups", {
        // Wait until the objective groups have been initialized
        waitUntil {!isNil "InitializationOG" && {InitializationOG}};

        // Calculate initial max attacking groups
        _self set ["_maxAttackingGroups", _self call ["_calculateMaxAttackingGroups", []]];

        // Get all virtual groups from the virtualization system
        private _groups = FLO_virtualGroups get "_groups";
        private _allGroups = [_groups] call FLO_fnc_filterNonCivGroups;
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
        
        // Find available garrison groups
        private _availableGroups = _self get "_garrisonedGroups";
        if (count _availableGroups <= (_self get "_minGarrisonGroups")) exitWith {
            ["AI Commander", 3, "Cannot assign more attack groups - minimum garrison requirement"] call FLO_fnc_log;
            false
        };
        
        // Get all virtual groups
        private _groups = FLO_virtualGroups get "_groups";
        private _virtualGroups = [_groups] call FLO_fnc_filterNonCivGroups;
        
        // Sort groups by distance to staging point (not target)
        private _stagingPos = _op get "stagingPos";
        private _sortedGroups = [_availableGroups, [], {
            private _groupData = _virtualGroups get _x;
            private _groupPos = _groupData get "position";
            _groupPos distance2D _stagingPos
        }, "ASCEND"] call BIS_fnc_sortBy;
        
        // Calculate how many groups we can assign to this operation
        private _slotsInOperation = (_op get "maxForce") - count (_currentGroups);
        private _availableCount = count _availableGroups - (_self get "_minGarrisonGroups");
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
        
        // Find available garrison groups
        private _availableGroups = _self get "_garrisonedGroups";
        if (count _availableGroups <= (_self get "_minGarrisonGroups")) exitWith {
            ["AI Commander", 3, "Cannot assign more defense groups - minimum garrison requirement"] call FLO_fnc_log;
            false
        };
        
        // Get all virtual groups
        private _groups = FLO_virtualGroups get "_groups";
        private _virtualGroups = [_groups] call FLO_fnc_filterNonCivGroups;
        
        // Sort groups by distance to staging point
        private _stagingPos = _op get "stagingPos";
        private _sortedGroups = [_availableGroups, [], {
            private _groupData = _virtualGroups get _x;
            private _groupPos = _groupData get "position";
            _groupPos distance2D _stagingPos
        }, "ASCEND"] call BIS_fnc_sortBy;
        
        // Calculate how many groups we can assign
        private _slotsInOperation = (_op get "maxForce") - count (_currentGroups);
        private _availableCount = count _availableGroups - (_self get "_minGarrisonGroups");
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
        
        // Get the group's data
        private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
        if (_groupData isEqualTo createHashMap) exitWith {
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

    // Process both attack and defense staging operations
    ["_processStagingOperations", {
        _self call ["_processAttackOperations", []];
        _self call ["_processDefenseOperations", []];
    }],

    ["_processAttackOperations", {
        private _ops = _self get "_attackOperations";
        private _toRemove = [];

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
                // Check how many groups are ready at staging point
                private _ready = [];
                private _enRoute = [];
                {
                    private _gData = (FLO_virtualGroups get "_groups") get _x;
                    if (isNil "_gData") then { continue }; 
                    private _pos = _gData get "position";
                    if (_pos distance2D _stagePos < 75) then { 
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
                    // Call artillery/air support to soften the target
                    _self call ["_callArtillerySupport", [_targetPos, 8]];
                    _self call ["_callAirSupport", [_targetPos, "BOMB"]];
                    
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
                } else {
                    // Check if attack has been running too long without progress
                    private _launchTime = _op getOrDefault ["launchTime", diag_tickTime];
                    if (diag_tickTime - _launchTime > 1800) then { // 30 minute timeout
                        _toRemove pushBack _id;
                        ["AI Commander", 3, format["Attack operation %1 timed out - recalling groups", _id]] call FLO_fnc_log;
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
        private _toRemove = [];

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
                // Check how many groups are ready at staging point
                private _ready = [];
                private _enRoute = [];
                {
                    private _gData = (FLO_virtualGroups get "_groups") get _x;
                    if (isNil "_gData") then { continue }; 
                    private _pos = _gData get "position";
                    if (_pos distance2D _stagePos < 50) then { 
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
                };
            } else {
                // Check if defense is complete
                private _aliveGroups = _groups select { 
                    _x in (_self get "_activeDefenseGroups") && 
                    {!isNil ((FLO_virtualGroups get "_groups") get _x)}
                };
                
                if (count _aliveGroups == 0) then { 
                    _toRemove pushBack _id;
                    ["AI Commander", 3, format["Defense operation %1 completed - no groups remaining", _id]] call FLO_fnc_log;
                } else {
                    // Check if defense has been running too long
                    private _launchTime = _op getOrDefault ["launchTime", diag_tickTime];
                    if (diag_tickTime - _launchTime > 1200) then { // 20 minute timeout for defense
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

    ["_callArtillerySupport", {
        params ["_self", "_targetPos", ["_rounds", 6]];

        private _success = [_targetPos, _rounds] call FLO_fnc_requestVirtualArtillery;
        if (_success) then {
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

    ["_callAirSupport", {
        /*
            Queues a mission for the Air Tasking Order. Mission types can be
            "CAS", "BOMB" or "LASER". CAS missions perform a rocket or cannon
            strafe while the strike missions drop bombs or fire laser guided
            missiles. If the mission is empty the commander selects an
            appropriate type based on nearby enemy vehicles. If no altitude is
            provided the function defaults to 300 metres for strike missions and
            150 metres for CAS.
        */
        params ["_self", "_targetPos", ["_mission", ""], ["_type", ""], ["_alt", -1]];

        if (_mission isEqualTo "") then {
            _mission = _self call ["_selectAirMission", [_targetPos]];
        };

        if (_alt < 0) then {
            _alt = if (_mission in ["BOMB", "LASER"]) then {300} else {150};
        };

        private _ato = _self get "_airTaskOrder";
        _ato call ["_addTask", [_targetPos, _mission, _type, _alt]];
    }],
    
    ["_update", {
        private _currentTime = diag_tickTime;
        private _lastUpdate = _self get "_lastUpdate";
        private _updateInterval = _self get "_commanderUpdateInterval";
        
        // Only update periodically
        if (_currentTime - _lastUpdate < _updateInterval) exitWith {};
        
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
        
        // Remove dead groups from all tracked arrays
        {
            private _activeAttackGroups = _self get "_activeAttackGroups";
            private _activeDefenseGroups = _self get "_activeDefenseGroups";
            private _garrisonedGroups = _self get "_garrisonedGroups";
            
            _activeAttackGroups = _activeAttackGroups - [_x];
            _activeDefenseGroups = _activeDefenseGroups - [_x];
            _garrisonedGroups = _garrisonedGroups - [_x];
            
            _self set ["_activeAttackGroups", _activeAttackGroups];
            _self set ["_activeDefenseGroups", _activeDefenseGroups];
            _self set ["_garrisonedGroups", _garrisonedGroups];
            diag_log format["Removed group %1 from tracking", _x];
        } forEach _deadGroups;
        
        // Get current threats
        private _threats = _self call ["_assessThreats", []];
        
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

        // Process staging and launch of operations
        _self call ["_processStagingOperations", []];
        
        // Check if any active groups should return to garrison
        {
            private _groupId = _x;
            private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
            
            if (!isNull (_groupData getOrDefault ["realGroup", grpNull])) then {
                private _nearestEnemy = leader (_groupData get "realGroup") findNearestEnemy (leader (_groupData get "realGroup"));
                
                if (isNull _nearestEnemy || {_nearestEnemy distance (leader (_groupData get "realGroup")) > 800}) then {
                    _self call ["_returnGroupToGarrison", [_groupId, "ATTACK"]];
                };
            };
        } forEach (_self get "_activeAttackGroups");
        
        {
            private _groupId = _x;
            private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
            
            if (!isNull (_groupData getOrDefault ["realGroup", grpNull])) then {
                private _nearestEnemy = leader (_groupData get "realGroup") findNearestEnemy (leader (_groupData get "realGroup"));
                
                if (isNull _nearestEnemy || {_nearestEnemy distance (leader (_groupData get "realGroup")) > 1000}) then {
                    _self call ["_returnGroupToGarrison", [_groupId, "DEFEND"]];
                };
            };
        } forEach (_self get "_activeDefenseGroups");

        // Process any queued air support tasks
        (_self get "_airTaskOrder") call ["_processTasks", []];

        // Update last update time
        _self set ["_lastUpdate", _currentTime];
    }]
]];

// Initialize Commander
_aiCommander set ["_commanderUpdateInterval", 300];

// Initialize groups
_aiCommander call ["_initializeGroups", []];

// Start the commander loop
[_aiCommander] spawn {
    params ["_commander"];
    
    while {true} do {
        _commander call ["_update", []];
        sleep 60;
    };
};

// Return the commander object
_aiCommander 