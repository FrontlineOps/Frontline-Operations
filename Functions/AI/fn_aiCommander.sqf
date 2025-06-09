/*
 * Function: FLO_fnc_aiCommander
 * Author: Azraeelian Angel
 * Description:
 * Creates an AI Commander that controls overall OPFOR operations.
 * Manages virtual groups for attacking BLUFOR and defending objectives.
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
    ["_maxAttackingGroups", 0],  // Will be set in initialize
    ["_maxDefendingGroups", 6],  // Maximum number of groups that can be defending/QRF simultaneously
    ["_minGarrisonGroups", 2],   // Minimum number of groups that must remain in garrison
    ["_attackStageTime", 120],

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

    ["_assignGroupToAttack", {
        params ["_targetPos", "_targetType"];
        
        // Recalculate max attacking groups based on current player count
        _self set ["_maxAttackingGroups", _self call ["_calculateMaxAttackingGroups", []]];
        
        // Check if we're at the attack group limit
        if (count (_self get "_activeAttackGroups") >= (_self get "_maxAttackingGroups")) exitWith {
            ["AI Commander", 3, format["Maximum attacking groups reached (%1 groups)", _self get "_maxAttackingGroups"]] call FLO_fnc_log;
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
        
        // Sort groups by distance to target
        private _sortedGroups = [_availableGroups, [], {
            private _groupData = _virtualGroups get _x;
            private _groupPos = _groupData get "position";
            _groupPos distance2D _targetPos
        }, "ASCEND"] call BIS_fnc_sortBy;
        
        // Calculate how many groups we can assign
        private _availableCount = count _availableGroups - (_self get "_minGarrisonGroups");
        private _remainingSlots = (_self get "_maxAttackingGroups") - count (_self get "_activeAttackGroups");
        private _groupsToAssign = _availableCount min _remainingSlots min 4; // Assign up to 4 groups per target
        
        // Assign groups
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
                    ["AI Commander", 3, format["Intercepted reinforcing group %1 for attack mission", _selectedGroupId]] call FLO_fnc_log;
                };
                
                // Update group assignments
                private _garrisonedGroups = _self get "_garrisonedGroups";
                private _activeAttackGroups = _self get "_activeAttackGroups";
                _garrisonedGroups deleteAt (_garrisonedGroups find _selectedGroupId);
                _activeAttackGroups pushBack _selectedGroupId;
                
                // Set up staging waypoints for unified push
                private _ops = _self get "_attackOperations";
                private _op = _ops getOrDefault [_targetType, nil];
                if (isNil "_op") then {
                    _op = createHashMap;
                    _op set ["objectiveId", _targetType];
                    _op set ["objectivePos", _targetPos];
                    private _dir = random 360;
                    private _dist = 400 + random 200;
                    _op set ["stagingPos", _targetPos getPos [_dist, _dir]];
                    _op set ["groups", []];
                    _op set ["startTime", diag_tickTime];
                    _op set ["attackStarted", false];
                };

                private _stage = _op get "stagingPos";
                private _waypoints = [[_stage, "MOVE", "AWARE", "NORMAL", "WEDGE", "YELLOW", 10]];
                [_selectedGroupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;

                private _grpArr = _op get "groups";
                _grpArr pushBack _selectedGroupId;
                _op set ["groups", _grpArr];
                _ops set [_targetType, _op];
                _self set ["_attackOperations", _ops];

                _groupData set ["currentOrder", "STAGE"];
                _groupData set ["attackObjective", _targetType];
                
                _assignedGroups pushBack _selectedGroupId;
                ["AI Commander", 3, format["Assigned group %1 to attack %2", _selectedGroupId, _targetType]] call FLO_fnc_log;
            };
        };
        
        count _assignedGroups > 0
    }],

    ["_assignGroupToDefend", {
        params ["_targetPos", "_reason", "_objectiveId"];
        
        // Check if we're at the defense group limit
        if (count (_self get "_activeDefenseGroups") >= (_self get "_maxDefendingGroups")) exitWith {
            ["AI Commander", 3, "Maximum defending groups reached"] call FLO_fnc_log;
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
        
        // Sort groups by distance to target
        private _sortedGroups = [_availableGroups, [], {
            private _groupData = _virtualGroups get _x;
            private _groupPos = _groupData get "position";
            _groupPos distance2D _targetPos
        }, "ASCEND"] call BIS_fnc_sortBy;
        
        // Calculate how many groups we can assign
        private _availableCount = count _availableGroups - (_self get "_minGarrisonGroups");
        private _remainingSlots = (_self get "_maxDefendingGroups") - count (_self get "_activeDefenseGroups");
        private _groupsToAssign = _availableCount min _remainingSlots min 3; // Assign up to 3 groups per defense point
        
        // Assign groups
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
                    ["AI Commander", 3, format["Intercepted reinforcing group %1 for defense mission", _selectedGroupId]] call FLO_fnc_log;
                };
                
                // Update group assignments
                private _garrisonedGroups = _self get "_garrisonedGroups";
                private _activeDefenseGroups = _self get "_activeDefenseGroups";
                _garrisonedGroups deleteAt (_garrisonedGroups find _selectedGroupId);
                _activeDefenseGroups pushBack _selectedGroupId;
                
                // Set up defense waypoints
                private _waypoints = [
                    [_targetPos, "MOVE", "COMBAT", "NORMAL", "WEDGE", "YELLOW", 30]  // Medium radius for defense positions
                ];
                [_selectedGroupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;

                // Attach group to this objective for future garrisoning
                _groupData set ["garrisonObjective", _objectiveId];
                _groupData set ["garrisonPosition", [_objectiveId] call FLO_fnc_getRandomObjectivePos];
                
                _assignedGroups pushBack _selectedGroupId;
                ["AI Commander", 3, format["Assigned group %1 to defend - %2", _selectedGroupId, _reason]] call FLO_fnc_log;
            };
        };
        
        count _assignedGroups > 0
    }],

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

    ["_processAttackOperations", {
        private _ops = _self get "_attackOperations";
        private _stageTime = _self get "_attackStageTime";
        private _toRemove = [];

        {
            private _id = _x;
            private _op = _y;
            private _groups = _op get "groups";
            private _started = _op get "attackStarted";
            private _stagePos = _op get "stagingPos";
            private _objPos = _op get "objectivePos";
            if (!_started) then {
                private _ready = [];
                {
                    private _gData = (FLO_virtualGroups get "_groups") get _x;
                    if (isNil "_gData") then { continue }; 
                    private _pos = _gData get "position";
                    if (_pos distance2D _stagePos < 50) then { _ready pushBack _x; };
                } forEach _groups;
                if ((count _ready) >= (count _groups) || {diag_tickTime - (_op get "startTime") > _stageTime}) then {
                    {
                        private _gData = (FLO_virtualGroups get "_groups") get _x;
                        if (isNil "_gData") then { continue };
                        private _w = [[_objPos, "SAD", "AWARE", "NORMAL", "WEDGE", "RED", 50]];
                        [_x, _w, true] call FLO_fnc_updateVirtualGroupWaypoints;
                        _gData set ["currentOrder", "ATTACK"];
                    } forEach _groups;
                    _op set ["attackStarted", true];
                    // Call artillery to soften the target before the assault
                    _self call ["_callArtillerySupport", [_objPos, 6]];
                };
            } else {
                private _alive = _groups select { _x in (_self get "_activeAttackGroups") };
                if (count _alive == 0) then { _toRemove pushBack _id; };
            };
            _ops set [_id, _op];
        } forEach _ops;

        { _ops deleteAt _x; } forEach _toRemove;
        _self set ["_attackOperations", _ops];
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
            _self call ["_assignGroupToDefend", [_pos, format["Objective %1 under attack (%2 enemies)", _id, _strength], _id]];
        } forEach _defenseThreats;
        
        // Then handle attack threats
        {
            _x params ["_type", "_id", "_pos", "_strength"];
            _self call ["_assignGroupToAttack", [_pos, _id]];
        } forEach _attackThreats;

        // Process staging and launch of attack operations
        _self call ["_processAttackOperations", []];
        
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