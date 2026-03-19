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
        ["add", [_groupId, _pos, _groupData get "side"]] call FLO_fnc_virtualizationSpatialIndex;
        if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
            [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
        };

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
            if ([_groupData] call FLO_fnc_gtnCombatAffectsClassification) then {
                [true] call FLO_fnc_gtnCombatMarkClassificationDirty;
            };

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
                private _oldPosition = _groupData get "position";
                private _groupType = _groupData get "groupType";
                private _side = _groupData get "side";
                private _trackCombatSeed = (_side in [east, west]) && {(_groupData get "attachedTo") == ""} && {_groupType in ["infantry", "motorized", "mechanized", "armor", "mobile_aa"]};
                private _seedCellSize = if (isNil "FLO_GTN_CombatState") then { 150 } else { FLO_GTN_CombatState get "classificationSeedCellSize" };

                _groupData set ["position", _newPosition];

                // Update spatial index (only if position changed significantly)
                ["update", [_groupId, _newPosition, _groupData get "side"]] call FLO_fnc_virtualizationSpatialIndex;

                if (_trackCombatSeed) then {
                    private _oldSeedCellKey = format [
                        "%1_%2",
                        floor ((_oldPosition select 0) / _seedCellSize),
                        floor ((_oldPosition select 1) / _seedCellSize)
                    ];
                    private _newSeedCellKey = format [
                        "%1_%2",
                        floor ((_newPosition select 0) / _seedCellSize),
                        floor ((_newPosition select 1) / _seedCellSize)
                    ];
                    if (_oldSeedCellKey != _newSeedCellKey) then {
                        [false] call FLO_fnc_gtnCombatMarkClassificationDirty;
                    };
                };
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
            if (
                (_groupData get "side") in [east, west]
                && {(_groupData get "attachedTo") == ""}
                && {[(_groupData get "groupType")] call FLO_fnc_gtnCombatIsSupportProvider}
            ) then {
                [false] call FLO_fnc_gtnCombatMarkClassificationDirty;
            };

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
            if (
                (_groupData get "side") in [east, west]
                && {(_groupData get "attachedTo") == ""}
                && {[(_groupData get "groupType")] call FLO_fnc_gtnCombatIsSupportProvider}
            ) then {
                [false] call FLO_fnc_gtnCombatMarkClassificationDirty;
            };

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
