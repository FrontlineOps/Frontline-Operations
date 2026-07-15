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
private _phaseT0 = diag_tickTime;
private _activationDistance = FLO_VirtualizationDistance;
private _activationUnitCap = FLO_VirtualizationUnitCap;
diag_log format ["[FLO_INIT_P4] Using virtualization distance: %1m activeUnitCap=%2", _activationDistance, _activationUnitCap];

if (!isNil "InitializationOG" && {InitializationOG}) exitWith {
    diag_log "[FLO_INIT_P4] Virtualization already initialized (PFH start deferred to Phase 5)";

    call FLO_fnc_gtnAirInitializeOffMapReserves;
    call FLO_fnc_gtnAirDefenseStartContactWorker;
    true
};

private _initializedFromSave = false;

// Check if loading from saved game with virtual groups
if (!isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave} && {!isNil "FLO_SavedGameData"}) then {
    private _savedData = FLO_SavedGameData;

    if ("virtualGroups" in _savedData) then {
        diag_log "[FLO_INIT_P4] Loading virtual groups from save...";

        // Initialize virtualization system first
        private _initT0 = diag_tickTime;
        [_activationDistance, _activationUnitCap, false] call FLO_fnc_initVirtualization;
        private _initMs = (diag_tickTime - _initT0) * 1000;

        private _savedGroups = _savedData get "virtualGroups";
        private _restoreT0 = diag_tickTime;
        private _loadedCount = [_savedGroups] call FLO_fnc_virtualizationRestoreRegistry;
        private _restoreMs = (diag_tickTime - _restoreT0) * 1000;
        diag_log format ["[FLO_INIT_P4] Restored %1 virtual groups from save", _loadedCount];

        // Mark as initialized; PFH start is deferred to Phase 5 so startup
        // work does not compete with virtualization updates.
        InitializationOG = true;
        publicVariable "InitializationOG";
        _initializedFromSave = true;

        diag_log "[FLO_INIT_P4] Virtualization loaded from save - complete";
        diag_log format [
            "[FLO][PERF] Phase4 saved groups=%1 init=%2 ms restore=%3 ms total=%4 ms",
            _loadedCount,
            _initMs,
            _restoreMs,
            (diag_tickTime - _phaseT0) * 1000
        ];
    };
};

if (_initializedFromSave) exitWith {
    call FLO_fnc_gtnAirInitializeOffMapReserves;
    call FLO_fnc_gtnAirDefenseStartContactWorker;
    true
};

// Verify objectives exist
if (isNil "FLO_Objectives" || {FLO_Objectives isEqualTo []}) exitWith {
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
private _initT0 = diag_tickTime;
[_activationDistance, _activationUnitCap, false] call FLO_fnc_initVirtualization;
private _initMs = (diag_tickTime - _initT0) * 1000;

// Initialize objective groups for both sides
diag_log "[FLO_INIT_P4] Creating objective groups for EAST/WEST...";
private _sides = missionNamespace getVariable ["FLO_MissionSides", [east, west]];
private _seedT0 = diag_tickTime;
{
    [_x] call FLO_fnc_initializeObjectiveGroups;
} forEach _sides;
private _seedMs = (diag_tickTime - _seedT0) * 1000;

// Verify groups were created
if (isNil "FLO_VirtualForceRegistry") then {
    diag_log "[FLO_INIT_P4] WARNING: No virtual groups created - map may have no OPFOR spawn points";
} else {
    private _groups = call FLO_fnc_virtualizationGetGroupMap;
    if (isNil "_groups" || {(keys _groups) isEqualTo []}) then {
        diag_log "[FLO_INIT_P4] WARNING: Virtual groups HashMap empty - map may have no OPFOR spawn points";
    };
};

// Log statistics
private _groupCount = if (!isNil "FLO_VirtualForceRegistry") then {
    count keys (call FLO_fnc_virtualizationGetGroupMap)
} else { 0 };
diag_log format ["[FLO_INIT_P4] Created %1 virtual groups", _groupCount];

private _reconcileT0 = diag_tickTime;
[] call FLO_fnc_virtualizationReconcileTransportState;
private _reconcileMs = (diag_tickTime - _reconcileT0) * 1000;

call FLO_fnc_gtnAirInitializeOffMapReserves;
call FLO_fnc_gtnAirDefenseStartContactWorker;

// Mark initialization complete
InitializationOG = true;
publicVariable "InitializationOG";

diag_log "[FLO_INIT_P4] Virtualization phase complete";
diag_log format [
    "[FLO][PERF] Phase4 fresh sides=%1 groups=%2 init=%3 ms seed=%4 ms reconcile=%5 ms total=%6 ms",
    _sides,
    _groupCount,
    _initMs,
    _seedMs,
    _reconcileMs,
    (diag_tickTime - _phaseT0) * 1000
];
true

