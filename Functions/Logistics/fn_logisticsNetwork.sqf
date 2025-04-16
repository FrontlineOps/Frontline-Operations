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
                
                // Find valid spawn objectives (OPFOR objectives with no players within 2km)
                private _spawnObjectives = allMapMarkers select {
                    private _marker = _x;
                    markerColor _marker in ["colorOPFOR", "ColorEAST"] && 
                    markerType _marker in ["o_support", "n_support", "o_installation", "n_installation", 
                                        "loc_Power", "o_recon", "o_service", "o_antiair", "loc_Ruin"] &&
                    {
                        private _pos = getMarkerPos _marker;
                        private _nearPlayers = allPlayers select {_x distance2D _pos < 2000};
                        count _nearPlayers == 0
                    }
                };
                
                // Find valid target objectives (closer to BLUFOR activity but not too close)
                private _targetObjectives = allMapMarkers select {
                    private _marker = _x;
                    markerColor _marker in ["colorOPFOR", "ColorEAST"] && 
                    markerType _marker in ["o_support", "n_support", "o_installation", "n_installation", 
                                        "loc_Power", "o_recon", "o_service", "o_antiair", "loc_Ruin"] &&
                    {
                        private _pos = getMarkerPos _marker;
                        private _nearPlayers = allPlayers select {_x distance2D _pos < 2000};
                        private _nearBlufor = allMapMarkers select {
                            markerColor _x in ["ColorBLUFOR", "ColorWEST"] && 
                            (getMarkerPos _x) distance2D _pos < 3000
                        };
                        count _nearPlayers == 0 && count _nearBlufor > 0
                    }
                };
                
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
                    
                    if (_resources >= _groupCost && count _spawnObjectives > 0) then {
                        // Select random spawn and target objectives
                        private _spawnObjective = selectRandom _spawnObjectives;
                        private _targetObjective = if (count _targetObjectives > 0) then {
                            selectRandom _targetObjectives
                        } else {
                            selectRandom _spawnObjectives
                        };
                        
                        private _spawnPos = getMarkerPos _spawnObjective;
                        private _targetPos = getMarkerPos _targetObjective;
                        
                        // Create the replacement group
                        private _newGroupId = [_spawnPos, _groupType, nil, _targetObjective, _groupCost] call FLO_fnc_createVirtualGroup;
                        
                        if (_newGroupId != "") then {
                            // Set up waypoints to move to target objective
                            private _waypoints = [[_targetPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 20]];
                            // Using Pathfinding Here makes a scope error @Crashdome
                            // Error Local variable in global space on line 244 in fn_updateVirtualGroupWaypoints.sqf
                            [_newGroupId, _waypoints, false] call FLO_fnc_updateVirtualGroupWaypoints;
                            
                            // Add to AI Commander's garrison if it exists
                            if (!isNil "FLO_AI_Commander") then {
                                private _garrisonedGroups = FLO_AI_Commander get "_garrisonedGroups";
                                _garrisonedGroups pushBack _newGroupId;
                                
                                private _groupData = (FLO_virtualGroups get "_groups") get _newGroupId;
                                _groupData set ["garrisonPosition", _targetPos];
                            };
                            
                            // Spend resources
                            FLO_OPFOR_Resources call ["spendResources", [_groupCost, "reinforcement"]];
                            ["LOGISTICS", 3, format["Created replacement %1 group, spawning at %2, moving to %3", 
                                _groupType, _spawnObjective, _targetObjective]] call FLO_fnc_log;
                            
                            // Deduct from available resources
                            _resources = _resources - _groupCost;
                        };
                    };
                } forEach _destroyedGroups;
            };
        }]
    ];
    
    // Create and initialize the network
    FLO_Logistics_Network = createHashMapObject [_logisticsNetworkClass];
};