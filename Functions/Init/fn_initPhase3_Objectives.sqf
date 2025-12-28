/*
 * Function: FLO_fnc_initPhase3_Objectives
 * Author: Frontline Operations Development Group
 * Description:
 *   Phase 3: Index all map objectives on the server.
 *   This is now done SERVER-SIDE instead of via client remoteExec.
 *
 * Arguments: None
 * Returns: Boolean - True if objectives indexed successfully
 */

if (!isServer) exitWith { false };

diag_log "[FLO_INIT_P3] Indexing map objectives...";

// Check if already indexed (saved game)
if (!isNil "FLO_Objectives" && {count FLO_Objectives > 0}) exitWith {
    diag_log format ["[FLO_INIT_P3] Objectives already indexed (saved game): %1 objectives", count FLO_Objectives];
    
    // Verify we have virtual objectives too
    if (isNil "FLO_VirtualObjectives") then {
        diag_log "[FLO_INIT_P3] Indexing virtual objectives from existing FLO_Objectives";
        [] call FLO_fnc_indexVirtualObjectives;
    };
    
    true
};

// Initialize objectives array
FLO_Objectives = [];
publicVariable "FLO_Objectives";

// Run the objective indexer directly on server
diag_log "[FLO_INIT_P3] Calling FLO_fnc_indexObjectives...";

private _indexResult = [] call FLO_fnc_indexObjectives;

// Verify objectives were indexed
if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) exitWith {
    FLO_InitError = "Objective indexing returned no objectives";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P3] ERROR: %1", FLO_InitError];
    false
};

diag_log format ["[FLO_INIT_P3] Indexed %1 objectives", count FLO_Objectives];

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

// Start objective graph (dominance tracking)
diag_log "[FLO_INIT_P3] Starting objective graph...";
[] spawn FLO_fnc_startObjectiveGraph;

// Start dominance monitoring
diag_log "[FLO_INIT_P3] Starting objective dominance monitoring...";
[] spawn FLO_fnc_monitorObjectiveDominance;

diag_log format ["[FLO_INIT_P3] Objectives phase complete: %1 objectives, %2 virtual objectives", 
    count FLO_Objectives, 
    count FLO_VirtualObjectives
];

true

