/*
 * Function: FLO_fnc_initVirtualization
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes the OPFOR virtualization system.
 *   Creates HashMap for tracking virtualized groups.
 *   Uses unscheduled CBA PerFrameHandler for reliable updates.
 *
 * Arguments:
 * 0: Activation Distance <NUMBER> - Distance at which virtual groups activate (default 2000m)
 *
 * Return Value:
 * Virtual Groups HashMap <HASHMAP>
 *
 * Example:
 * [2000] call FLO_fnc_initVirtualization;
 */

params [["_activationDistance", 2000, [0]]];

["VIRTUALIZATION", 3, format["Initializing Virtualization System (activation: %1m)", _activationDistance]] call FLO_fnc_log;

// ============================================================================
// CREATE MAIN DATA STRUCTURE
// ============================================================================
FLO_virtualGroups = createHashMapObject [[
    // Data storage
    ["_groups", createHashMap],
    ["_activationDistance", _activationDistance],
    ["_enabled", true],
    ["_debugMode", false],  // Managed by FLO_fnc_virtualizationDebugManager

    // Enable/disable the virtualization system
    ["_setEnabled", {
        params ["_self", "_enable"];
        _self set ["_enabled", _enable];

        if (_enable) then {
            ["start"] call FLO_fnc_virtualizationUpdatePFH;
        } else {
            ["stop"] call FLO_fnc_virtualizationUpdatePFH;
        };

        ["VIRTUALIZATION", 3, format["Virtualization %1", if (_enable) then {"enabled"} else {"disabled"}]] call FLO_fnc_log;
    }],

    // Get a specific group
    ["_getGroup", {
        params ["_self", "_groupId"];
        (_self get "_groups") getOrDefault [_groupId, nil]
    }],

    // Add a group to the system
    ["_addGroup", {
        params ["_self", "_groupId", "_groupData"];
        (_self get "_groups") set [_groupId, _groupData];

        // Add to spatial index - position must exist
        private _pos = _groupData get "position";
        ["add", [_groupId, _pos]] call FLO_fnc_virtualizationSpatialIndex;

        // Fire event for other systems (GTN, AI Commander)
        ["FLO_Virtualization_GroupAdded", [_groupId, _groupData]] call CBA_fnc_localEvent;
    }],

    // Remove a group from the system
    ["_removeGroup", {
        params ["_self", "_groupId"];
        private _groups = _self get "_groups";
        private _groupData = _groups getOrDefault [_groupId, nil];

        if (!isNil "_groupData") then {
            // Remove from spatial index
            ["remove", [_groupId]] call FLO_fnc_virtualizationSpatialIndex;

            // Clean up debug markers
            ["cleanup", _groupId] call FLO_fnc_virtualizationDebugManager;

            // Remove from storage
            _groups deleteAt _groupId;

            // Fire event for other systems
            ["FLO_Virtualization_GroupRemoved", [_groupId]] call CBA_fnc_localEvent;

            ["VIRTUALIZATION", 4, format["Removed group %1", _groupId]] call FLO_fnc_log;
        };
    }],

    // Update position of a virtual group
    ["_updateGroupPosition", {
        params ["_self", "_groupId", "_newPosition"];
        private _groupData = (_self get "_groups") getOrDefault [_groupId, nil];

        if (!isNil "_groupData") then {
            // Validate position
            if ((_newPosition select 0) > 100 || (_newPosition select 1) > 100) then {
                _groupData set ["position", _newPosition];

                // Update spatial index (only if position changed significantly)
                ["update", [_groupId, _newPosition]] call FLO_fnc_virtualizationSpatialIndex;
            };
        };
    }],

    // Reserve a group for a mission (prevents deactivation)
    ["_reserveGroup", {
        params ["_self", "_groupId", ["_missionType", "unknown"]];
        private _groupData = (_self get "_groups") getOrDefault [_groupId, nil];

        if (!isNil "_groupData") then {
            _groupData set ["onMission", true];
            _groupData set ["missionType", _missionType];
            _groupData set ["state", "reserved"];

            ["FLO_Virtualization_GroupReserved", [_groupId, _missionType]] call CBA_fnc_localEvent;
            true
        } else {
            false
        };
    }],

    // Release a group from mission (allows deactivation again)
    ["_releaseGroup", {
        params ["_self", "_groupId"];
        private _groupData = (_self get "_groups") getOrDefault [_groupId, nil];

        if (!isNil "_groupData") then {
            _groupData set ["onMission", false];
            _groupData set ["missionType", ""];
            _groupData set ["state", "idle"];

            ["FLO_Virtualization_GroupReleased", [_groupId]] call CBA_fnc_localEvent;
            true
        } else {
            false
        };
    }],

    // Get groups by criteria
    ["_getGroupsBy", {
        params ["_self", "_criteria"];
        private _groups = _self get "_groups";
        private _result = [];

        {
            private _match = true;
            {
                private _key = _x;
                private _val = _criteria get _key;
                if ((_y getOrDefault [_key, nil]) isNotEqualTo _val) then {
                    _match = false;
                };
            } forEach _criteria;

            if (_match) then {
                _result pushBack [_x, _y];
            };
        } forEach _groups;

        _result
    }]
]];

// ============================================================================
// INITIALIZE SUB-SYSTEMS
// ============================================================================

// Initialize spatial index for fast proximity queries
["init", [500]] call FLO_fnc_virtualizationSpatialIndex;

// Register CBA event handlers for GTN/AI Commander integration
["init"] call FLO_fnc_virtualizationEvents;

// Start update loop (Unscheduled PFH)
["start"] call FLO_fnc_virtualizationUpdatePFH;

// Initialize debug manager
["init"] call FLO_fnc_virtualizationDebugManager;

// Initialize Transport System
call FLO_fnc_transportConfig;
call FLO_fnc_transportPool;
call FLO_fnc_transportMapEdge;

// Set ready flag
FLO_VirtualizationReady = true;
publicVariable "FLO_VirtualizationReady";

["VIRTUALIZATION", 3, "Virtualization System initialized (PFH mode)"] call FLO_fnc_log;

FLO_virtualGroups