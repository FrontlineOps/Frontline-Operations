/*
 * Function: FLO_fnc_initPhase4_Virtualization
 * Author: Frontline Operations Development Group
 * Description:
 *   Phase 4: Initialize virtualization system and create OPFOR groups.
 *   If loading from save, restores virtual groups from saved data.
 *
 * Arguments: None
 * Returns: Boolean - True if virtualization initialized successfully
 */

if (!isServer) exitWith { false };

diag_log "[FLO_INIT_P4] Initializing virtualization...";
private _activationDistance = FLO_VirtualizationDistance;
diag_log format ["[FLO_INIT_P4] Using virtualization distance: %1m", _activationDistance];

private _fnc_startRadarDataLink = {
    diag_log "[FLO_INIT_P4] Starting radar data link system...";
    [] spawn FLO_fnc_gtnRadarDataLink;
};

// Check if loading from saved game with virtual groups
if (!isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave} && {!isNil "FLO_SavedGameData"}) then {
    private _savedData = FLO_SavedGameData;

    if ("virtualGroups" in _savedData) then {
        diag_log "[FLO_INIT_P4] Loading virtual groups from save...";

        // Initialize virtualization system first
        [_activationDistance] call FLO_fnc_initVirtualization;

        private _savedGroups = _savedData get "virtualGroups";
        private _loadedCount = 0;
        private _skippedCount = 0;

        if (!isNil "_savedGroups" && {_savedGroups isEqualType createHashMap}) then {
            {
                private _groupId = _x;
                private _groupData = _savedGroups get _groupId;

                if (!isNil "_groupData") then {
                    // Position must exist - if missing, save data is corrupt
                    private _pos = _groupData get "position";
                    private _homeObjective = if ("homeObjective" in _groupData) then {
                        _groupData get "homeObjective"
                    } else {
                        _groupData getOrDefault ["objective", ""]
                    };

                    // Create the virtual group
                    private _newId = [
                        _pos,
                        _groupData getOrDefault ["groupType", "infantry_squad"],
                        nil,
                        _homeObjective,
                        _groupData getOrDefault ["unitCount", 4],
                        _groupData getOrDefault ["side", east]
                    ] call FLO_fnc_createVirtualGroup;

                    if (_newId != "") then {
                        // Restore additional state
                        private _groups = FLO_virtualGroups get "_groups";
                        private _newData = _groups get _newId;

                        if (!isNil "_newData") then {
                            private _state = _groupData getOrDefault ["state", "idle"];
                            private _currentOrder = _groupData getOrDefault ["currentOrder", ""];
                            private _aaDeployState = _groupData getOrDefault ["aaDeployState", ""];
                            private _isReinforcing = (_groupData getOrDefault ["isReinforcing", false]) || {_currentOrder == "REINFORCE"} || {_currentOrder == "AA_DEPLOY" && {_aaDeployState == "MOVING"}};
                            private _reinforcementTargetObjective = _groupData get "reinforcementTargetObjective";
                            private _reinforcementRequestedObjective = _groupData get "reinforcementRequestedObjective";
                            private _reinforcementDeliveryObjective = _groupData get "reinforcementDeliveryObjective";
                            private _reinforcementTargetPos = _groupData getOrDefault ["reinforcementTargetPos", []];
                            if !(_reinforcementTargetPos isEqualType [] && {count _reinforcementTargetPos >= 2}) then {
                                _reinforcementTargetPos = [];
                                if (_reinforcementTargetObjective != "" && {_reinforcementTargetObjective in FLO_Objectives}) then {
                                    private _targetObjective = FLO_Objectives get _reinforcementTargetObjective;
                                    _reinforcementTargetPos = _targetObjective get "position";
                                };
                            };
                            private _pathRequestTarget = _groupData getOrDefault ["pathRequestTarget", []];
                            if !(_pathRequestTarget isEqualType [] && {count _pathRequestTarget >= 2}) then {
                                _pathRequestTarget = [];
                            };
                            private _tempWaypointSettings = _groupData getOrDefault ["tempWaypointSettings", []];
                            if !(_tempWaypointSettings isEqualType [] && {count _tempWaypointSettings >= 7}) then {
                                _tempWaypointSettings = [];
                            };

                            _newData set ["state", _state];

                            // Validate and restore waypoints
                            private _savedWaypoints = _groupData getOrDefault ["waypoints", []];
                            private _validWaypoints = [];

                            if (_savedWaypoints isEqualType []) then {
                                {
                                    // Basic validation - waypoint must be array with position and type
                                    if (_x isEqualType [] && {count _x >= 2}) then {
                                        _validWaypoints pushBack _x;
                                    };
                                } forEach _savedWaypoints;
                            };

                            _newData set ["waypoints", _validWaypoints];
                            _newData set ["currentWaypointIndex", if (count _validWaypoints > 0) then {(_groupData getOrDefault ["currentWaypointIndex", 0]) min (count _validWaypoints - 1)} else {0}];
                            _newData set ["onMission", _isReinforcing];
                            _newData set ["isReinforcing", _isReinforcing];
                            _newData set ["reinforcementTargetPos", _reinforcementTargetPos];
                            _newData set ["reinforcementTargetObjective", _reinforcementTargetObjective];
                            _newData set ["reinforcementRequestedObjective", _reinforcementRequestedObjective];
                            _newData set ["reinforcementDeliveryObjective", _reinforcementDeliveryObjective];
                            _newData set ["pathRequestTarget", _pathRequestTarget];
                            _newData set ["pathRequestTrails", _groupData getOrDefault ["pathRequestTrails", false]];
                            _newData set ["pathRequestSource", _groupData getOrDefault ["pathRequestSource", ""]];
                            _newData set ["tempWaypointSettings", _tempWaypointSettings];
                            _newData set ["alwaysActive", _groupData getOrDefault ["alwaysActive", false]];
                            _newData set ["currentOrder", _currentOrder];
                            _newData set ["noWaypoints", _groupData getOrDefault ["noWaypoints", false]];
                            _newData set ["forceVirtual", _groupData getOrDefault ["forceVirtual", false]];
                            _newData set ["aaDeployState", _aaDeployState];
                            _newData set ["aaDeployTargetPos", _groupData getOrDefault ["aaDeployTargetPos", []]];
                            _newData set ["aaDeployTargetObjective", _groupData getOrDefault ["aaDeployTargetObjective", ""]];
                            _newData set ["isStrategicAA", _groupData getOrDefault ["isStrategicAA", false]];

                            // Validate garrison position before restoring
                            private _garrisonPos = _groupData getOrDefault ["garrisonPosition", []];
                            if (_garrisonPos isEqualType [] && {count _garrisonPos >= 2} && {(_garrisonPos select 0) > 0 || (_garrisonPos select 1) > 0}) then {
                                _newData set ["garrisonPosition", _garrisonPos];
                            } else {
                                // Use the group position as garrison if no valid garrison position
                                _newData set ["garrisonPosition", _pos];
                            };

                            _newData set ["garrisonObjective", _groupData getOrDefault ["garrisonObjective", ""]];
                            _loadedCount = _loadedCount + 1;
                        };
                    };
                };
            } forEach (keys _savedGroups);

            // diag_log format ["[FLO_INIT_P4] Restored %1 virtual groups from save (skipped %2 invalid)", _loadedCount, _skippedCount];
        };

        // Mark as initialized and start PFH
        InitializationOG = true;
        publicVariable "InitializationOG";

        ["start"] call FLO_fnc_virtualizationUpdatePFH;

        diag_log "[FLO_INIT_P4] Virtualization loaded from save - complete";
    };
};

// Check if already initialized (from save load above or previous run)
if (!isNil "InitializationOG" && {InitializationOG}) exitWith {
    diag_log "[FLO_INIT_P4] Virtualization already initialized";

    // Restart PFH if not running
    if (isNil "FLO_VirtualizationPFH_Handle") then {
        diag_log "[FLO_INIT_P4] Restarting virtualization PFH";
        ["start"] call FLO_fnc_virtualizationUpdatePFH;
    };

    call _fnc_startRadarDataLink;

    true
};

// Verify objectives exist
if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) exitWith {
    FLO_InitError = "Cannot initialize virtualization - no objectives indexed";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P4] ERROR: %1", FLO_InitError];
    false
};

// Verify faction catalog exists
if (isNil "FLO_FactionCatalog") exitWith {
    FLO_InitError = "Cannot initialize virtualization - faction catalog not loaded";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P4] ERROR: %1", FLO_InitError];
    false
};

// Initialize the virtualization system
diag_log "[FLO_INIT_P4] Calling FLO_fnc_initVirtualization...";
[_activationDistance] call FLO_fnc_initVirtualization;

// Initialize objective groups for both sides
diag_log "[FLO_INIT_P4] Creating objective groups for EAST/WEST...";
private _sides = missionNamespace getVariable ["FLO_MissionSides", [east, west]];
{
    [_x] call FLO_fnc_initializeObjectiveGroups;
} forEach _sides;

// Verify groups were created
if (isNil "FLO_virtualGroups") then {
    diag_log "[FLO_INIT_P4] WARNING: No virtual groups created - map may have no OPFOR spawn points";
} else {
    private _groups = FLO_virtualGroups get "_groups";
    if (isNil "_groups" || {count keys _groups == 0}) then {
        diag_log "[FLO_INIT_P4] WARNING: Virtual groups HashMap empty - map may have no OPFOR spawn points";
    };
};

// Log statistics
private _groupCount = if (!isNil "FLO_virtualGroups") then {
    count keys (FLO_virtualGroups get "_groups")
} else { 0 };
diag_log format ["[FLO_INIT_P4] Created %1 virtual groups", _groupCount];

// Ensure PFH update loop is running (started by initVirtualization, but verify)
if (isNil "FLO_VirtUpdate" || {!(FLO_VirtUpdate get "running")}) then {
    diag_log "[FLO_INIT_P4] Starting virtualization PFH...";
    ["start"] call FLO_fnc_virtualizationUpdatePFH;
} else {
    diag_log "[FLO_INIT_P4] Virtualization PFH already running";
};

// Initialize virtual transport system
diag_log "[FLO_INIT_P4] Initializing virtual transport system...";
[] call FLO_fnc_transportConfig;
[] call FLO_fnc_transportPool;

call _fnc_startRadarDataLink;

// Mark initialization complete
InitializationOG = true;
publicVariable "InitializationOG";

diag_log "[FLO_INIT_P4] Virtualization phase complete";
true

