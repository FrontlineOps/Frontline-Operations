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

                // All OPFOR objectives
                private _opforObjs = keys FLO_Objectives select {
                    (FLO_Objectives get _x getOrDefault ["owner", east]) isEqualTo east
                };

                if (count _opforObjs == 0) exitWith {};

                // Determine spawn objective farthest from players
                private _spawnObjective = [_opforObjs, [], {
                    private _pos = (FLO_Objectives get _x get "position");
                    private _dist = 0; { _dist = _dist + (_pos distance2D _x); } forEach allPlayers;
                    -_dist
                }, "ASCEND"] call BIS_fnc_sortBy select 0;

                // Objectives with nearby BLUFOR presence
                private _reinforceObjs = _opforObjs select {
                    private _pos = (FLO_Objectives get _x get "position");
                    private _near = allPlayers select { side _x == west && _x distance2D _pos < 2000 };
                    count _near > 0
                };

                if (count _reinforceObjs == 0) exitWith {};

                {
                    _x params ["", "_groupType"];
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

                    if (_resources >= _groupCost) then {
                        private _reinforceObjective = selectRandom _reinforceObjs;
                        private _spawnPos = FLO_Objectives get _spawnObjective get "position";
                        private _reinforcePos = FLO_Objectives get _reinforceObjective get "position";

                        // Waypoints from cached objective link
                        private _path = [_spawnObjective, _reinforceObjective] call FLO_fnc_getObjectivePath;
                        if (count _path == 0) then { _path = [_reinforcePos]; };
                        private _wps = [];
                        { _wps pushBack [_x, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 20]; } forEach _path;

                        private _unitCount = [_groupType] call FLO_fnc_getGroupTypeCount;
                        if ((FLO_OPFOR_Resources call ["spendResources", [_groupCost, "reinforcement"]]) isEqualTo true) then {
                            private _newGroupId = [_spawnPos, _groupType, nil, _reinforceObjective, _unitCount] call FLO_fnc_createVirtualGroup;
                            if (_newGroupId != "") then {
                                private _groupData = (FLO_virtualGroups get "_groups") get _newGroupId;
                                _groupData set ["isReinforcing", true];
                                [_newGroupId, _wps, false] call FLO_fnc_updateVirtualGroupWaypoints;

                                ["LOGISTICS", 3, format["Created replacement %1 group from %2 to %3",
                                    _groupType, _spawnObjective, _reinforceObjective]] call FLO_fnc_log;
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