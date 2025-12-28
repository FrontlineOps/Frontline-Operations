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

// Check if loading from saved game with virtual groups
if (!isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave} && {!isNil "FLO_SavedGameData"}) then {
    private _savedData = FLO_SavedGameData;

    if ("virtualGroups" in _savedData) then {
        diag_log "[FLO_INIT_P4] Loading virtual groups from save...";

        // Initialize virtualization system first
        [] call FLO_fnc_initVirtualization;

        private _savedGroups = _savedData get "virtualGroups";
        private _loadedCount = 0;

        if (!isNil "_savedGroups" && {_savedGroups isEqualType createHashMap}) then {
            {
                private _groupId = _x;
                private _groupData = _savedGroups get _groupId;

                if (!isNil "_groupData") then {
                    // Create the virtual group
                    private _newId = [
                        _groupData getOrDefault ["position", [0,0,0]],
                        _groupData getOrDefault ["groupType", "infantry_squad"],
                        nil,
                        _groupData getOrDefault ["objective", ""],
                        _groupData getOrDefault ["unitCount", 4],
                        _groupData getOrDefault ["side", east]
                    ] call FLO_fnc_createVirtualGroup;

                    if (_newId != "") then {
                        // Restore additional state
                        private _groups = FLO_virtualGroups get "_groups";
                        private _newData = _groups get _newId;

                        if (!isNil "_newData") then {
                            _newData set ["state", _groupData getOrDefault ["state", "idle"]];
                            _newData set ["waypoints", _groupData getOrDefault ["waypoints", []]];
                            _newData set ["currentWaypointIndex", _groupData getOrDefault ["currentWaypointIndex", 0]];
                            _newData set ["garrisonPosition", _groupData getOrDefault ["garrisonPosition", []]];
                            _newData set ["garrisonObjective", _groupData getOrDefault ["garrisonObjective", ""]];
                            _loadedCount = _loadedCount + 1;
                        };
                    };
                };
            } forEach (keys _savedGroups);

            diag_log format ["[FLO_INIT_P4] Restored %1 virtual groups from save", _loadedCount];
        };

        // Mark as initialized and start loop
        InitializationOG = true;
        publicVariable "InitializationOG";

        [] spawn FLO_fnc_virtualGroupsUpdateLoop;

        // Exit early - we loaded from save
    };
};

// Check if already initialized (from save load above)
if (!isNil "InitializationOG" && {InitializationOG}) exitWith {
    diag_log "[FLO_INIT_P4] Virtualization already initialized";

    // Restart the update loop if not running
    if (isNil "FLO_VirtualGroupsUpdateLoopRunning" || {!FLO_VirtualGroupsUpdateLoopRunning}) then {
        diag_log "[FLO_INIT_P4] Restarting virtual groups update loop";
        [] spawn FLO_fnc_virtualGroupsUpdateLoop;
    };

    true
};

// Verify objectives exist
if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) exitWith {
    FLO_InitError = "Cannot initialize virtualization - no objectives indexed";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P4] ERROR: %1", FLO_InitError];
    false
};

// Verify faction arrays exist
if (isNil "East_Units" || isNil "East_Ground_Vehicles_Light") exitWith {
    FLO_InitError = "Cannot initialize virtualization - faction arrays not loaded";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P4] ERROR: %1", FLO_InitError];
    false
};

// Initialize the virtualization system
diag_log "[FLO_INIT_P4] Calling FLO_fnc_initVirtualization...";
[] call FLO_fnc_initVirtualization;

// Initialize objective groups (OPFOR garrison creation)
diag_log "[FLO_INIT_P4] Creating objective groups...";
private _initResult = [] call FLO_fnc_initializeObjectiveGroups;

// Verify groups were created
if (isNil "FLO_VirtualGroups" || {count keys FLO_VirtualGroups == 0}) then {
    diag_log "[FLO_INIT_P4] WARNING: No virtual groups created - map may have no OPFOR spawn points";
};

// Log statistics
private _groupCount = if (!isNil "FLO_VirtualGroups") then { count keys FLO_VirtualGroups } else { 0 };
diag_log format ["[FLO_INIT_P4] Created %1 virtual groups", _groupCount];

// Start the virtual groups update loop
diag_log "[FLO_INIT_P4] Starting virtual groups update loop...";
[] spawn FLO_fnc_virtualGroupsUpdateLoop;

// Mark initialization complete
InitializationOG = true;
publicVariable "InitializationOG";

diag_log "[FLO_INIT_P4] Virtualization phase complete";
true

