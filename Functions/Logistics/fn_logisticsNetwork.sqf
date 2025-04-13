/*
 * Function: FLO_fnc_logisticsNetwork
 * Author: Frontline Operations Development Group
 * Description:
 * Simple logistics system that replaces destroyed virtual groups at objectives.
 * Monitors objectives and creates replacement groups when needed.
*/

if (!isServer) exitWith {};

// Initialize the Logistics Network object if it doesn't exist
if (isNil "FLO_Logistics_Network") then {
    private _logisticsNetworkClass = [
        ["#type", "LogisticsNetwork"],
        
        ["lastUpdate", time],
        
        ["#create", {
            _self set ["lastUpdate", time];
            ["LOGISTICS", 3, "Network initialized"] call FLO_fnc_log;
        
            // Start the update loop
            [] spawn {
                while {true} do {
                    FLO_Logistics_Network call ["checkAndReplaceGroups", []];
                    sleep 300; // Check every 5 minutes
                };
            };
        }],
        
        ["checkAndReplaceGroups", {
            // Get all OPFOR objectives
            private _opforObjectives = allMapMarkers select {
                markerColor _x in ["colorOPFOR", "ColorEAST"] && 
                markerType _x in ["o_support", "n_support", "o_installation", "n_installation", 
                                  "loc_Power", "o_recon", "o_service", "o_antiair", "loc_Ruin"]
            };
            
            {
                private _objective = _x;
                private _objectivePos = getMarkerPos _objective;
                
                // Find all groups assigned to this objective
                private _existingGroups = [];
                private _allGroups = FLO_virtualGroups get "_groups";
                
                {
                    private _groupId = _x;
                    private _groupData = _y;
                    
                    if (_groupData get "objective" == _objective) then {
                        _existingGroups pushBack _groupId;
                    };
                } forEach _allGroups;
                
                // Check for destroyed groups
                private _destroyedCount = 0;
                private _destroyedGroupTypes = [];
                {
                    private _groupId = _x;
                    private _groupData = _allGroups get _groupId;
                    private _realGroup = _groupData getOrDefault ["realGroup", grpNull];
                    
                    if (!isNull _realGroup && {({alive _x} count units _realGroup) == 0}) then {
                        _destroyedCount = _destroyedCount + 1;
                        _destroyedGroupTypes pushBack (_groupData get "groupType");
                        ["LOGISTICS", 3, format["Group %1 at objective %2 was destroyed", _groupId, _objective]] call FLO_fnc_log;
                        dialog format["Group %1 at objective %2 was destroyed", _groupId, _objective];
                    };
                } forEach _existingGroups;
                
                // Replace destroyed groups if we have resources
                if (_destroyedCount > 0) then {
                    private _resources = FLO_OPFOR_Resources call ["getResources", []];
                    private _markerType = markerType _objective;
                    
                    {
                        private _groupType = _x;
                        
                        // Calculate group cost based on type and objective
                        private _groupCost = switch (_markerType) do {
                            case "o_installation";
                            case "n_installation": { 8 };
                            case "o_support";
                            case "n_support": { 6 };
                            default { 4 };
                        };
                        
                        // Add vehicle/aircraft cost based on group type
                        private _typeCost = switch (_groupType) do {
                            case "infantry": { 0 };
                            case "motorized": { 5 };
                            case "mechanized": { 8 };
                            case "armor": { 12 };
                            case "helicopter": { 15 };
                            case "air": { 20 };
                            default { 0 };
                        };
                        _groupCost = _groupCost + _typeCost;
                        
                        if (_resources >= _groupCost) then {
                            // Calculate spawn position on nearest map edge
                            private _spawnPos = [_objectivePos] call FLO_fnc_findEdgeSpawnPos;
                            
                            // Create the replacement group with same type
                            private _groupId = [_spawnPos, _groupType, nil, _objective, _groupCost] call FLO_fnc_createVirtualGroup;
                            
                            if (_groupId != "") then {
                                // Set up waypoints to move to objective
                                private _waypoints = [[_objectivePos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN"]];
                                [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
                                
                                // Add to AI Commander's garrison
                                if (!isNil "FLO_AI_Commander") then {
                                    private _garrisonedGroups = FLO_AI_Commander get "_garrisonedGroups";
                                    _garrisonedGroups pushBack _groupId;
                                    
                                    private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
                                    _groupData set ["garrisonPosition", _objectivePos];
                                };
                                
                                // Spend resources
                                FLO_OPFOR_Resources call ["spendResources", [_groupCost, "reinforcement"]];
                                ["LOGISTICS", 3, format["Created replacement group %1 (%2) at %3", _groupId, _groupType, _objective]] call FLO_fnc_log;
                                diag_log format["Created replacement group %1 (%2) at %3", _groupId, _groupType, _objective];
                                
                                // Deduct from available resources
                                _resources = _resources - _groupCost;
                            };
                        };
                    } forEach _destroyedGroupTypes;
                };
            } forEach _opforObjectives;
        }]
    ];
    
    // Create and initialize the network
    FLO_Logistics_Network = createHashMapObject [_logisticsNetworkClass];
};