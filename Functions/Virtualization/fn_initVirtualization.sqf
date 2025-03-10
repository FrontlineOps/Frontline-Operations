/*
 * Function: FLO_fnc_initVirtualization
 * Author: Frontline Operations Development Group
 * Description:
 * Initializes the OPFOR virtualization system. Creates a HashMap to track all virtualized groups.
 *
 * Arguments:
 * 0: Activation Distance <NUMBER> - Distance in meters at which virtual groups will be activated
 *
 * Return Value:
 * Virtual Groups HashMap <HASHMAP>
 *
 * Example:
 * [2000] call FLO_fnc_initVirtualization;
 */

params [["_activationDistance", 2000, [0]]];

// Log function start
["VIRTUALIZATION", 3, "Initializing OPFOR Virtualization System"] call FLO_fnc_log;

// Create main virtualization HashMap
if (isNil "FLO_virtualGroups") then {
    FLO_virtualGroups = createHashMapObject [
        [
            ["_groups", createHashMap],          // All virtualized groups
            ["_activationDistance", _activationDistance],
            ["_enabled", true],
            ["_debugMode", false],
            ["_objectiveGroups", createHashMap], // Groups mapped to objectives
            
            // Method to enable/disable the system
            ["_setEnabled", {
                params ["_self", "_enableState"];
                _self set ["_enabled", _enableState];
                ["VIRTUALIZATION", 3, format["Virtualization system %1", if (_enableState) then {"enabled"} else {"disabled"}]] call FLO_fnc_log;
            }],
            
            // Method to set debug mode
            ["_setDebugMode", {
                params ["_self", "_debugState"];
                _self set ["_debugMode", _debugState];
                ["VIRTUALIZATION", 3, format["Debug mode %1", if (_debugState) then {"enabled"} else {"disabled"}]] call FLO_fnc_log;
                
                // If enabling debug mode, create map markers for all virtual groups
                if (_debugState) then {
                    {
                        [_x, _y] call FLO_fnc_createVirtualGroupMarker;
                    } forEach (_self get "_groups");
                } else {
                    // Remove all debug markers
                    {
                        deleteMarker format["vgroup_%1", _x];
                    } forEach (_self get "_groups");
                };
            }],
            
            // Method to get a specific group
            ["_getGroup", {
                params ["_self", "_groupId"];
                (_self get "_groups") getOrDefault [_groupId, objNull]
            }],
            
            // Method to add a group to the system
            ["_addGroup", {
                params ["_self", "_groupId", "_groupData"];
                (_self get "_groups") set [_groupId, _groupData];
                
                // If in debug mode, create a marker for this group
                if (_self get "_debugMode") then {
                    [_groupId, _groupData] call FLO_fnc_createVirtualGroupMarker;
                };
                
                // If the group is associated with an objective, add it to objectiveGroups
                private _objective = _groupData getOrDefault ["objective", ""];
                if (_objective != "") then {
                    private _objectiveGroups = _self get "_objectiveGroups";
                    private _groups = _objectiveGroups getOrDefault [_objective, []];
                    _groups pushBack _groupId;
                    _objectiveGroups set [_objective, _groups];
                };
                
                ["VIRTUALIZATION", 3, format["Added virtual group %1", _groupId]] call FLO_fnc_log;
            }],
            
            // Method to remove a group from the system
            ["_removeGroup", {
                params ["_self", "_groupId"];
                private _groupData = (_self get "_groups") getOrDefault [_groupId, objNull];
                
                if (!isNull _groupData) then {
                    // Remove from objective groups if needed
                    private _objective = _groupData getOrDefault ["objective", ""];
                    if (_objective != "") then {
                        private _objectiveGroups = _self get "_objectiveGroups";
                        private _groups = _objectiveGroups getOrDefault [_objective, []];
                        _groups = _groups - [_groupId];
                        _objectiveGroups set [_objective, _groups];
                    };
                    
                    // Remove marker if debug mode is enabled
                    if (_self get "_debugMode") then {
                        deleteMarker format["vgroup_%1", _groupId];
                    };
                    
                    // Remove group from main hashmap
                    (_self get "_groups") deleteAt _groupId;
                    ["VIRTUALIZATION", 3, format["Removed virtual group %1", _groupId]] call FLO_fnc_log;
                };
            }],
            
            // Method to update position of a virtual group
            ["_updateGroupPosition", {
                params ["_self", "_groupId", "_newPosition"];
                private _groupData = (_self get "_groups") getOrDefault [_groupId, objNull];
                
                if (!isNull _groupData) then {
                    _groupData set ["position", _newPosition];
                    
                    // Update marker if debug mode is enabled
                    if (_self get "_debugMode") then {
                        private _marker = format["vgroup_%1", _groupId];
                        if (getMarkerColor _marker != "") then {
                            _marker setMarkerPos _newPosition;
                        };
                    };
                };
            }],
            
            // Method to get all groups for a specific objective
            ["_getObjectiveGroups", {
                params ["_self", "_objectiveType"];
                (_self get "_objectiveGroups") getOrDefault [_objectiveType, []]
            }]
        ]
    ];
    
    // Initialize update loop for checking activation distances
    [] spawn FLO_fnc_virtualGroupsUpdateLoop;
    
    ["VIRTUALIZATION", 3, "OPFOR Virtualization System initialized"] call FLO_fnc_log;
};

// Return the virtualization object
FLO_virtualGroups 