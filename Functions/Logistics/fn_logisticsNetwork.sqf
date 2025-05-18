/*
 * Function: FLO_fnc_logisticsNetwork
 * Author: Frontline Operations Development Group
 * Description:
 * Simple logistics system that replaces destroyed virtual groups.
 * Monitors virtual groups and creates replacements when needed.
*/

if (!isServer) exitWith {};

// Initialize the Logistics Network object if it doesn't exist
if (isNil "FLO_Logistics_Network") then {
    private _logisticsNetworkClass = [
        ["#type", "LogisticsNetwork"],
        
        ["lastUpdate", time],
        ["initialComposition", createHashMap],
        
        ["#create", {
            _self set ["lastUpdate", time];
            
            // Wait for virtualization system to initialize
            waitUntil { !isNil "FLO_virtualGroups" && {!isNil "InitializationOG"} && {InitializationOG}};
            
            // Store initial group composition
            private _allGroups = FLO_virtualGroups get "_groups";
            private _initialComposition = createHashMap;
            
            {
                private _groupType = _y get "groupType";
                _initialComposition set [_groupType, (_initialComposition getOrDefault [_groupType, 0]) + 1];
            } forEach _allGroups;
            
            _self set ["initialComposition", _initialComposition];
            
            ["LOGISTICS", 3, format["Network initialized with composition: %1", _initialComposition]] call FLO_fnc_log;
        
            // Start the update loop
            [] spawn {
                while {true} do {
                    FLO_Logistics_Network call ["checkAndReplaceGroups", []];
                    sleep 300; // Check every 5 minutes
                };
            };
        }],
        
        ["checkAndReplaceGroups", {
            // Get all groups
            private _allGroups = FLO_virtualGroups get "_groups";
            private _destroyedGroups = [];
            private _currentComposition = createHashMap;
            
            // Count current groups by type
            {
                private _groupType = _y get "groupType";
                _currentComposition set [_groupType, (_currentComposition getOrDefault [_groupType, 0]) + 1];
            } forEach _allGroups;
            
            // Compare with initial composition and find missing types
            private _initialComposition = _self get "initialComposition";
            {
                private _groupType = _x;
                private _currentCount = _currentComposition getOrDefault [_groupType, 0];
                private _targetCount = _initialComposition getOrDefault [_groupType, 0];
                
                // If we have fewer groups of this type than initial, add them to destroyed list
                for "_i" from _currentCount to (_targetCount - 1) do {
                    _destroyedGroups pushBack ["", _groupType];
                };
                
            } forEach (keys _initialComposition);
            
            // Replace destroyed groups if we have resources
            if (count _destroyedGroups > 0) then {
                private _resources = FLO_OPFOR_Resources call ["getResources", []];
                
                // Find valid spawn objectives (OPFOR objectives at least 3km from players)
                private _allPotentialSpawns = allMapMarkers select {
                    private _marker = _x;
                    markerColor _marker in ["colorOPFOR", "ColorEAST"] && 
                    markerType _marker in ["o_support", "n_support", "o_installation", "n_installation", 
                                        "loc_Power", "o_recon", "o_service", "o_antiair", "loc_Ruin"] &&
                    {
                        private _pos = getMarkerPos _marker;
                        private _nearPlayers = allPlayers select {_x distance2D _pos < 3000};
                        count _nearPlayers == 0
                    }
                };

                // Sort objectives by average distance to all players and take the closest valid ones
                private _spawnObjectives = [];
                if (count _allPotentialSpawns > 0) then {
                    _spawnObjectives = [_allPotentialSpawns, [], {
                        private _pos = getMarkerPos _x;
                        private _totalDist = 0;
                        {
                            _totalDist = _totalDist + (_x distance2D _pos);
                        } forEach allPlayers;
                        _totalDist / (count allPlayers max 1)
                    }, "ASCEND"] call BIS_fnc_sortBy;
                    
                    // Take the top 5 closest objectives (that are still at least 3km away)
                    _spawnObjectives = _spawnObjectives select [0, 5];
                };
                
                // Find valid reinforcement positions (OPFOR objectives near BLUFOR activity)
                private _reinforcePositions = allMapMarkers select {
                    private _marker = _x;
                    markerColor _marker in ["colorOPFOR", "ColorEAST"] && 
                    markerType _marker in ["o_support", "n_support", "o_installation", "n_installation", 
                                        "loc_Power", "o_recon", "o_service", "o_antiair", "loc_Ruin"] &&
                    {
                        private _pos = getMarkerPos _marker;
                        private _nearBlufor = allMapMarkers select {
                            markerColor _x in ["ColorBLUFOR", "ColorWEST", "ColorYellow"] && 
                            markerType _x in ["b_installation", "b_support", "b_hq"] &&
                            (getMarkerPos _x) distance2D _pos < 2000
                        };
                        count _nearBlufor > 0
                    }
                };
                
                // Initialize or get the reinforcement tracking
                if (isNil "FLO_Logistics_ReinforcementCount") then {
                    FLO_Logistics_ReinforcementCount = createHashMap;
                };

                // Update counts for objectives that no longer exist
                private _toRemove = [];
                {
                    if (!(_x in _reinforcePositions)) then {
                        _toRemove pushBack _x;
                    };
                } forEach (keys FLO_Logistics_ReinforcementCount);
                
                {
                    FLO_Logistics_ReinforcementCount deleteAt _x;
                } forEach _toRemove;

                // Initialize counts for new objectives
                {
                    if !(_x in FLO_Logistics_ReinforcementCount) then {
                        FLO_Logistics_ReinforcementCount set [_x, 0];
                    };
                } forEach _reinforcePositions;
                
                {
                    _x params ["", "_groupType"];
                    
                    // Calculate group cost based on type
                    private _groupCost = switch (_groupType) do {
                        case "infantry": { 4 };
                        case "motorized": { 9 };
                        case "mechanized": { 12 };
                        case "armor": { 16 };
                        case "helicopter": { 19 };
                        case "air": { 24 };
                        case "artillery": { 14 };
                        default { 4 };
                    };
                    
                    if (_resources >= _groupCost && count _spawnObjectives > 0 && count _reinforcePositions > 0) then {
                        // Select random spawn position from farthest positions
                        private _spawnObjective = selectRandom _spawnObjectives;
                        
                        // Find the least reinforced position
                        private _reinforceObjective = [_reinforcePositions, [], {
                            FLO_Logistics_ReinforcementCount getOrDefault [_x, 0]
                        }, "ASCEND"] call BIS_fnc_sortBy select 0;
                        
                        // Increment the reinforcement count for this objective
                        FLO_Logistics_ReinforcementCount set [_reinforceObjective, 
                            (FLO_Logistics_ReinforcementCount getOrDefault [_reinforceObjective, 0]) + 1];
                        
                        private _spawnPos = getMarkerPos _spawnObjective;
                        private _reinforcePos = getMarkerPos _reinforceObjective;
                        
                        // Add random offset to reinforcement position (100-600m spread)
                        private _spreadDistance = (random 500) + 100; // Random distance between 100-300m
                        private _spreadDir = random 360; // Random direction
                        private _offsetX = _spreadDistance * (cos _spreadDir);
                        private _offsetY = _spreadDistance * (sin _spreadDir);
                        private _reinforcePos = _reinforcePos vectorAdd [_offsetX, _offsetY, 0];
                        
                        // Get correct unit count for this group type
                        private _unitCount = [_groupType] call FLO_fnc_getGroupTypeCount;
                        // Spend resources before creating the group
                        if ((FLO_OPFOR_Resources call ["spendResources", [_groupCost, "reinforcement"]]) isEqualTo true) then {
                            // Create the replacement group with correct unit count
                            private _newGroupId = [_spawnPos, _groupType, nil, _reinforceObjective, _unitCount] call FLO_fnc_createVirtualGroup;
                            
                            if (_newGroupId != "") then {
                                // Mark the group as reinforcing
                                private _groupData = (FLO_virtualGroups get "_groups") get _newGroupId;
                                _groupData set ["isReinforcing", true];
                                
                                // Set up waypoints to move to reinforce position with spread
                                private _waypoints = [[_reinforcePos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 20]];
                                [_newGroupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
                                
                                // Add to AI Commander's garrison if it exists
                                if (!isNil "FLO_AI_Commander") then {
                                    private _garrisonedGroups = FLO_AI_Commander get "_garrisonedGroups";
                                    _garrisonedGroups pushBack _newGroupId;
                                    
                                    private _groupData = (FLO_virtualGroups get "_groups") get _newGroupId;
                                    _groupData set ["garrisonPosition", _reinforcePos];
                                };
                                
                                ["LOGISTICS", 3, format["Created replacement %1 group, spawning at %2, moving to %3", 
                                    _groupType, _spawnObjective, _reinforceObjective]] call FLO_fnc_log;
                                
                                // Deduct from available resources
                                _resources = _resources - _groupCost;
                            };
                        };
                    };
                } forEach _destroyedGroups;
            };
        }]
    ];
    
    // Create and initialize the network
    FLO_Logistics_Network = createHashMapObject [_logisticsNetworkClass];
};