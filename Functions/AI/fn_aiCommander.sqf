/*
 * Function: FLO_fnc_aiCommander
 * Author: Azraeelian Angel
 * Description:
 * Creates an AI Commander that controls overall OPFOR operations.
 * Sets operation modes (Attack, Defend, Skirmish) and coordinates task forces.
 *
 * Arguments:
 * 0: Operation Mode <STRING> - "ATTACK", "DEFEND", "SKIRMISH" (Optional, default: "DEFEND")
 *
 * Return Value:
 * AI Commander HashMap Object <HASHMAP>
 *
 * Example:
 * ["ATTACK"] call FLO_fnc_aiCommander;
 */

params [["_operationMode", "ATTACK", [""]]];

// Log function start
["AI Commander", 3, format["Starting AI Commander with operation mode: %1", _operationMode]] call FLO_fnc_log;

// Initialize variables
private _lastCommanderUpdate = diag_tickTime;
private _commanderUpdateInterval = 300; // 5 minutes between strategy updates
private _currentThreatLevel = 0;
private _threatThreshold = 0.6;

// Operation limits
private _maxAttackingGroups = 4;  // Maximum number of groups that can be attacking simultaneously
private _maxDefendingGroups = 6;  // Maximum number of groups that can be defending/QRF simultaneously
private _minGarrisonGroups = 2;   // Minimum number of groups that must remain in garrison

// Set up the Commander object using a HashMap
private _aiCommander = createHashMapObject [[
    ["_operationMode", _operationMode],
    ["_threatLevel", _currentThreatLevel],
    ["_lastUpdate", _lastCommanderUpdate],
    ["_activeAttackGroups", []],
    ["_activeDefenseGroups", []],
    ["_garrisonedGroups", []],

    ["_initializeGroups", {
        // Get all virtual groups from the virtualization system
        private _allGroups = FLO_virtualGroups get "_groups";
        private _garrisonedGroups = [];

        {
            private _groupId = _x;
            private _groupData = _y;
            
            // Initially, all groups are considered garrisoned
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
        
        // Check if we're at the attack group limit
        if (count (_self get "_activeAttackGroups") >= _maxAttackingGroups) exitWith {
            ["AI Commander", 3, "Maximum attacking groups reached"] call FLO_fnc_log;
            false
        };
        
        // Find available garrison group closest to target
        private _availableGroups = _self get "_garrisonedGroups";
        if (count _availableGroups == 0) exitWith {
            ["AI Commander", 3, "No available groups for attack"] call FLO_fnc_log;
            false
        };
        
        // Get all virtual groups
        private _virtualGroups = FLO_virtualGroups get "_groups";
        
        // Sort groups by distance to target
        private _sortedGroups = [_availableGroups, [], {
            private _groupData = _virtualGroups get _x;
            private _groupPos = _groupData get "position";
            _groupPos distance2D _targetPos
        }, "ASCEND"] call BIS_fnc_sortBy;
        
        // Get closest suitable group
        private _selectedGroupId = _sortedGroups select 0;
        
        // Update group assignments
        private _garrisonedGroups = _self get "_garrisonedGroups";
        private _activeAttackGroups = _self get "_activeAttackGroups";
        _garrisonedGroups deleteAt (_garrisonedGroups find _selectedGroupId);
        _activeAttackGroups pushBack _selectedGroupId;
        
        // Set up attack waypoints
        private _waypoints = [
            [_targetPos, "SAD", "AWARE", "NORMAL", "WEDGE", "RED"]
        ];
        [_selectedGroupId, _waypoints] call FLO_fnc_updateVirtualGroupWaypoints;
        
        ["AI Commander", 3, format["Assigned group %1 to attack %2", _selectedGroupId, _targetType]] call FLO_fnc_log;
        true
    }],

    ["_assignGroupToDefend", {
        params ["_targetPos", "_reason"];
        
        // Check if we're at the defense group limit
        if (count (_self get "_activeDefenseGroups") >= _maxDefendingGroups) exitWith {
            ["AI Commander", 3, "Maximum defending groups reached"] call FLO_fnc_log;
            false
        };
        
        // Find available garrison group
        private _availableGroups = _self get "_garrisonedGroups";
        if (count _availableGroups == 0) exitWith {
            ["AI Commander", 3, "No available groups for defense"] call FLO_fnc_log;
            false
        };
        
        // Get all virtual groups
        private _virtualGroups = FLO_virtualGroups get "_groups";
        
        // Sort groups by distance to target
        private _sortedGroups = [_availableGroups, [], {
            private _groupData = _virtualGroups get _x;
            private _groupPos = _groupData get "position";
            _groupPos distance2D _targetPos
        }, "ASCEND"] call BIS_fnc_sortBy;
        
        // Get closest suitable group
        private _selectedGroupId = _sortedGroups select 0;
        
        // Update group assignments
        private _garrisonedGroups = _self get "_garrisonedGroups";
        private _activeDefenseGroups = _self get "_activeDefenseGroups";
        _garrisonedGroups deleteAt (_garrisonedGroups find _selectedGroupId);
        _activeDefenseGroups pushBack _selectedGroupId;
        
        // Set up defense waypoints
        private _waypoints = [
            [_targetPos, "HOLD", "COMBAT", "NORMAL", "WEDGE", "YELLOW"]
        ];
        [_selectedGroupId, _waypoints] call FLO_fnc_updateVirtualGroupWaypoints;
        
        ["AI Commander", 3, format["Assigned group %1 to defend - %2", _selectedGroupId, _reason]] call FLO_fnc_log;
        true
    }],

    ["_returnGroupToGarrison", {
        params ["_groupId", "_currentRole"];
        
        // Get the group's data
        private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
        if (_groupData isEqualTo createHashMap) exitWith {
            ["AI Commander", 3, format["Failed to return group %1 to garrison - group not found", _groupId]] call FLO_fnc_log;
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
            [_garrisonPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN"]
        ];
        [_groupId, _waypoints] call FLO_fnc_updateVirtualGroupWaypoints;
        
        ["AI Commander", 3, format["Returned group %1 to garrison from %2 role", _groupId, _currentRole]] call FLO_fnc_log;
    }],

    ["_assessThreats", {
        private _threats = [];
        
        // Check for BLUFOR units near objectives
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
                _threats pushBack ["OBJECTIVE", _objective, _objectivePos, count _nearBlufor];
            };
        } forEach _opforObjectives;
        
        // Check for BLUFOR groups in the field
        private _bluforGroups = allGroups select {side _x == west};
        {
            private _group = _x;
            private _units = units _group select {alive _x && !(captive _x)};
            if (count _units > 2) then {
                _threats pushBack ["GROUP", str _group, getPos (leader _group), count _units];
            };
        } forEach _bluforGroups;
        
        _threats
    }],

    ["_update", {
        private _currentTime = diag_tickTime;
        private _lastUpdate = _self get "_lastUpdate";
        private _updateInterval = _self get "_commanderUpdateInterval";
        
        // Only update periodically
        if (_currentTime - _lastUpdate < _updateInterval) exitWith {};
        
        // Get current threats
        private _threats = _self call ["_assessThreats", []];
        
        // Handle threats based on operation mode
        switch (_self get "_operationMode") do {
            case "ATTACK": {
                // In attack mode, prioritize attacking BLUFOR groups and objectives
                {
                    _x params ["_type", "_id", "_pos", "_strength"];
                    
                    if (_type == "GROUP" && {random 1 > 0.3}) then {
                        _self call ["_assignGroupToAttack", [_pos, "BLUFOR Group"]];
                    };
                } forEach _threats;
            };
            
            case "DEFEND": {
                // In defend mode, prioritize defending objectives under attack
                {
                    _x params ["_type", "_id", "_pos", "_strength"];
                    
                    if (_type == "OBJECTIVE") then {
                        _self call ["_assignGroupToDefend", [_pos, format["Objective %1 under attack", _id]]];
                    };
                } forEach _threats;
            };
            
            case "SKIRMISH": {
                // Mix of attack and defense based on situation
                {
                    _x params ["_type", "_id", "_pos", "_strength"];
                    
                    if (_type == "OBJECTIVE") then {
                        _self call ["_assignGroupToDefend", [_pos, format["Objective %1 under attack", _id]]];
                    } else {
                        if (random 1 > 0.7) then {
                            _self call ["_assignGroupToAttack", [_pos, "BLUFOR Group"]];
                        };
                    };
                } forEach _threats;
            };
        };
        
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
_aiCommander set ["_threatThreshold", 0.6];

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