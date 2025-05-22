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

// Utility: Filter out civilian and civilianVehicle groups from a hashmap
private _filterNonCivGroups = {
    params ["_groupsMap"];
    private _result = createHashMap;
    {
        if (!((_y getOrDefault ["groupType", ""]) in ["civilian", "civilianVehicle"])) then {
            _result set [_x, _y];
        };
    } forEach _groupsMap;
    _result
};

// Set up the Commander object using a HashMap
private _aiCommander = createHashMapObject [[
    ["_threatLevel", _currentThreatLevel],
    ["_lastUpdate", _lastCommanderUpdate],
    ["_activeAttackGroups", []],
    ["_activeDefenseGroups", []],
    ["_garrisonedGroups", []],
    ["_maxAttackingGroups", 0],  // Will be set in initialize
    ["_maxDefendingGroups", 6],  // Maximum number of groups that can be defending/QRF simultaneously
    ["_minGarrisonGroups", 2],   // Minimum number of groups that must remain in garrison

    ["_calculateMaxAttackingGroups", {
        private _playerCount = count (allPlayers - entities "HeadlessClient_F");
        
        // No attacks with 1-2 players
        if (_playerCount <= 2) exitWith { 0 };
        
        // Calculate groups: subtract 2 from player count and divide by 2 (rounded down)
        private _maxGroups = floor((_playerCount - 2) / 2);
        
        // Add aggression score
        private _AGGRSCORE = parseNumber (markerText ((allMapMarkers select {markerColor _x == "Color6_FD_F"}) param [0, "", [""]])) ;
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
        private _allGroups = [FLO_virtualGroups get "_groups"] call _filterNonCivGroups;
        private _garrisonedGroups = [];

        {
            private _groupId = _x;
            private _groupData = _y;
            // Only non-civilian groups are considered garrisoned
            _garrisonedGroups pushBack _groupId;
            // Store the original position as the garrison position
            _groupData set ["garrisonPosition", _groupData get "position"];
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
        private _virtualGroups = [FLO_virtualGroups get "_groups"] call _filterNonCivGroups;
        
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
                
                // Set up attack waypoints
                private _waypoints = [
                    [_targetPos, "SAD", "AWARE", "NORMAL", "WEDGE", "RED", 50]  // Larger radius for SAD waypoints
                ];
                [_selectedGroupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
                
                _assignedGroups pushBack _selectedGroupId;
                ["AI Commander", 3, format["Assigned group %1 to attack %2", _selectedGroupId, _targetType]] call FLO_fnc_log;
            };
        };
        
        count _assignedGroups > 0
    }],

    ["_assignGroupToDefend", {
        params ["_targetPos", "_reason"];
        
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
        private _virtualGroups = [FLO_virtualGroups get "_groups"] call _filterNonCivGroups;
        
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
        
        // Get original garrison position
        private _garrisonPos = _groupData getOrDefault ["garrisonPosition", _groupData get "position"];
        
        // Update group assignments
        private _garrisonedGroups = _self get "_garrisonedGroups";
        private _activeGroups = _self get (["_activeAttackGroups", "_activeDefenseGroups"] select (_currentRole == "DEFEND"));
        _activeGroups deleteAt (_activeGroups find _groupId);
        _garrisonedGroups pushBack _groupId;
        
        // Set up return waypoints
        private _waypoints = [
            [_garrisonPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 10]  // Tighter radius for garrison positions
        ];
        [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
        
        ["AI Commander", 3, format["Returned group %1 to garrison from %2 role", _groupId, _currentRole]] call FLO_fnc_log;
    }],

    ["_assessThreats", {
        private _threats = [];
        
        // Check for BLUFOR units near OPFOR objectives
        private _opforObjectives = allMapMarkers select {
                markerColor _x in ["colorOPFOR", "ColorEAST"] && 
            markerType _x in ["o_support", "n_support", "o_installation", "n_installation", "loc_Power", "o_recon", "o_antiair", "loc_Ruin"]
        };
        
        {
            private _objective = _x;
            private _objectivePos = getMarkerPos _objective;
            private _nearBlufor = _objectivePos nearEntities [["Man", "LandVehicle"], 500];
            _nearBlufor = _nearBlufor select {side _x == west && !(captive _x)};
            
            if (count _nearBlufor > 0) then {
                _threats pushBack ["DEFEND", _objective, _objectivePos, count _nearBlufor];
            };
        } forEach _opforObjectives;
        
        // Check for BLUFOR groups in the field
        private _bluforGroups = allGroups select {side _x == west};
        {
            private _group = _x;
            private _units = units _group select {alive _x && !(captive _x)};
            if (count _units > 2) then {
                _threats pushBack ["ATTACK", str _group, getPos (leader _group), count _units];
            };
        } forEach _bluforGroups;
        
        // If no BLUFOR groups found, check BLUFOR objectives for attack
        if (count (_threats select {_x select 0 == "ATTACK"}) == 0) then {
            private _bluforObjectives = allMapMarkers select {
                markerColor _x in ["ColorYellow", "ColorBLUFOR", "ColorWEST"] &&
                markerType _x in ["b_installation", "b_support", "b_hq"]
            };
            
            {
                private _objective = _x;
                private _objectivePos = getMarkerPos _objective;
                _threats pushBack ["ATTACK", _objective, _objectivePos, 1];
            } forEach _bluforObjectives;
        };
        
        // Sort threats by priority (number of enemies)
        _threats = [_threats, [], {_x select 3}, "DESCEND"] call BIS_fnc_sortBy;
        
        _threats
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
            _self call ["_assignGroupToDefend", [_pos, format["Objective %1 under attack (%2 enemies)", _id, _strength]]];
        } forEach _defenseThreats;
        
        // Then handle attack threats
        {
            _x params ["_type", "_id", "_pos", "_strength"];
            _self call ["_assignGroupToAttack", [_pos, _id]];
        } forEach _attackThreats;
        
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