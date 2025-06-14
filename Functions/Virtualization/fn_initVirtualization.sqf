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
                        // Create position marker
                        [_x, _y] call FLO_fnc_createVirtualGroupMarker;
                        
                        // Create waypoint markers if the group has waypoints
                        private _waypoints = _y getOrDefault ["waypoints", []];
                        private _currentWaypointIndex = _y getOrDefault ["currentWaypointIndex", 0];
                        
                        if (count _waypoints > 0) then {
                            [_x, _waypoints, _currentWaypointIndex] call FLO_fnc_createVirtualWaypointMarkers;
                        };
                    } forEach (_self get "_groups");
                } else {
                    // Remove all debug markers
                    {
                        // Remove group markers
                        deleteMarker format["vgroup_%1", _x];
                        
                        // Remove waypoint markers
                        private _waypointMarkerPrefix = format["vwp_%1_", _x];
                        {
                            if ((_x find _waypointMarkerPrefix) isEqualTo 0) then {
                                deleteMarker _x;
                            };
                        } forEach allMapMarkers;
                    } forEach (_self get "_groups");
                };
            }],
            
            // Method to get a specific group
            ["_getGroup", {
                params ["_self", "_groupId"];
                (_self get "_groups") get _groupId
            }],
            
            // Method to add a group to the system
            ["_addGroup", {
                params ["_self", "_groupId", "_groupData"];
                (_self get "_groups") set [_groupId, _groupData];
                
                // If in debug mode, create a marker for this group
                if (_self get "_debugMode") then {
                    [_groupId, _groupData] call FLO_fnc_createVirtualGroupMarker;
                };
                
                ["VIRTUALIZATION", 3, format["Added virtual group %1", _groupId]] call FLO_fnc_log;
            }],
            
            // Method to remove a group from the system
            ["_removeGroup", {
                params ["_self", "_groupId"];
                private _groupData = (_self get "_groups") get _groupId;
                
                if (!(_groupData isEqualTo createHashMap)) then {
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
                private _groupData = (_self get "_groups") get _groupId;
                
                if (!(_groupData isEqualTo createHashMap)) then {
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

            ["Serialize", {
                createHashMapFromArray [
                    ["_groups", _self get "_groups"]
                ];
            }],

            ["Deserialize", {
                params ["_dto"];
                _self set ["_groups", _dto get "_groups"];
            }]
        ]
    ];

    // Load data from data map
    private _dto = FLO_dataMap get ["FLO_virtualGroups"];
    if !(isNil "_dto") then {FLO_virtualGroups call ["deserialize", [_dto]]};
    
    // Initialize update loop for checking activation distances
    [] spawn FLO_fnc_virtualGroupsUpdateLoop;
    
    ["VIRTUALIZATION", 3, "OPFOR Virtualization System initialized"] call FLO_fnc_log;
};

// Return the virtualization object
FLO_virtualGroups