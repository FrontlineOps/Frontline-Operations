/*
 * Function: FLO_fnc_initPhase3_Objectives
 * Author: Frontline Operations Development Group
 * Description:
 *   Phase 3: Index all map objectives on the server.
 *   If loading from save, restores objectives from saved data.
 *   This is now done SERVER-SIDE instead of via client remoteExec.
 *
 * Arguments: None
 * Returns: Boolean - True if objectives indexed successfully
 */

if (!isServer) exitWith { false };

diag_log "[FLO_INIT_P3] Initializing objectives...";

// Check if loading from saved game
if (!isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave} && {!isNil "FLO_SavedGameData"}) then {
    private _savedData = FLO_SavedGameData;

    // Check if objectives exist in save
    if ("objectives" in _savedData) then {
        FLO_Objectives = _savedData get "objectives";
        publicVariable "FLO_Objectives";

        diag_log format ["[FLO_INIT_P3] Restored %1 objectives from save", count FLO_Objectives];
    };
};

// If we already have objectives (from save), just start monitoring
if (!isNil "FLO_Objectives" && {count FLO_Objectives > 0}) exitWith {
    diag_log format ["[FLO_INIT_P3] Using saved objectives: %1 total", count FLO_Objectives];

    // Verify we have virtual objectives too
    if (isNil "FLO_VirtualObjectives") then {
        diag_log "[FLO_INIT_P3] Indexing virtual objectives from existing FLO_Objectives";
        [] call FLO_fnc_indexVirtualObjectives;
    };

    // Build/rebuild objective graph (road connections may have changed)
    diag_log "[FLO_INIT_P3] Rebuilding objective graph for saved game...";
    [false] call FLO_fnc_buildObjectiveGraph;

    // Start systems
    [] spawn FLO_fnc_startObjectiveGraph;
    [] spawn FLO_fnc_monitorObjectiveDominance;

    true
};

// Initialize objectives as HashMap
FLO_Objectives = createHashMap;
publicVariable "FLO_Objectives";

// Run the objective indexer directly on server
diag_log "[FLO_INIT_P3] Calling FLO_fnc_indexObjectives...";

private _indexResult = [] call FLO_fnc_indexObjectives;

// Verify objectives were indexed
if (isNil "FLO_Objectives") exitWith {
    FLO_InitError = "Objective indexing returned nil";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P3] ERROR: %1", FLO_InitError];
    false
};

if !(FLO_Objectives isEqualType createHashMap) exitWith {
    FLO_InitError = format ["Objective indexing returned wrong type: %1", typeName FLO_Objectives];
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P3] ERROR: %1", FLO_InitError];
    false
};

if (count keys FLO_Objectives == 0) exitWith {
    FLO_InitError = "Objective indexing returned no objectives";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P3] ERROR: %1", FLO_InitError];
    false
};

diag_log format ["[FLO_INIT_P3] Indexed %1 objectives", count keys FLO_Objectives];

// Index virtual objectives
diag_log "[FLO_INIT_P3] Calling FLO_fnc_indexVirtualObjectives...";
[] call FLO_fnc_indexVirtualObjectives;

if (isNil "FLO_VirtualObjectives") then {
    diag_log "[FLO_INIT_P3] WARNING: No virtual objectives created";
    FLO_VirtualObjectives = [];
    publicVariable "FLO_VirtualObjectives";
};

diag_log format ["[FLO_INIT_P3] Created %1 virtual objectives", count FLO_VirtualObjectives];

// Build objective graph
diag_log "[FLO_INIT_P3] Building objective graph...";
[] call FLO_fnc_buildObjectiveGraph;

// Start objective graph
diag_log "[FLO_INIT_P3] Starting objective graph...";
[] spawn FLO_fnc_startObjectiveGraph;

// Start dominance monitoring
diag_log "[FLO_INIT_P3] Starting objective dominance monitoring...";
[] spawn FLO_fnc_monitorObjectiveDominance;

diag_log format ["[FLO_INIT_P3] Objectives phase complete: %1 objectives, %2 virtual objectives",
    count keys FLO_Objectives,
    count FLO_VirtualObjectives
];

true

