/*
 * Function: FLO_fnc_initPhase5_MissionSystems
 * Author: Frontline Operations Development Group
 * Description:
 *   Phase 5: Start all mission systems (side missions, AI commander, etc.)
 *   This runs AFTER objectives are indexed and virtualization is complete.
 *
 * Arguments: None
 * Returns: Boolean - True if systems started successfully
 */

if (!isServer) exitWith { false };

diag_log "[FLO_INIT_P5] Starting mission systems...";

// Verify prerequisites
if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) exitWith {
    FLO_InitError = "Cannot start mission systems - no objectives";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P5] ERROR: %1", FLO_InitError];
    false
};

if (isNil "InitializationOG" || {!InitializationOG}) exitWith {
    FLO_InitError = "Cannot start mission systems - virtualization not complete";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P5] ERROR: %1", FLO_InitError];
    false
};

// ============================================
// OPFOR Resource System
// ============================================
diag_log "[FLO_INIT_P5] Starting OPFOR resource system...";
if (!isNil "FLO_fnc_opforResources") then {
    [] spawn FLO_fnc_opforResources;
    diag_log "[FLO_INIT_P5] OPFOR resources started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_opforResources not found";
};

// ============================================
// Logistics Network
// ============================================
diag_log "[FLO_INIT_P5] Starting logistics network...";
if (!isNil "FLO_fnc_logisticsNetwork") then {
    [] spawn FLO_fnc_logisticsNetwork;
    diag_log "[FLO_INIT_P5] Logistics network started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_logisticsNetwork not found";
};

// ============================================
// AI Commander
// ============================================
diag_log "[FLO_INIT_P5] Starting AI commander...";
if (!isNil "FLO_fnc_aiCommander") then {
    [] spawn FLO_fnc_aiCommander;
    diag_log "[FLO_INIT_P5] AI commander started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_aiCommander not found";
};

// ============================================
// Side Mission System
// ============================================
diag_log "[FLO_INIT_P5] Registering side mission templates...";

// Register all side mission templates
if (!isNil "FLO_fnc_sideMissionTemplate") then {
    // Register supply convoy template
    if (!isNil "FLO_fnc_smSupplyConvoy") then {
        ["register", "supply_convoy", ["supply_convoy", FLO_fnc_smSupplyConvoy, 30, 60, ["logistics", "convoy"], ["all"], nil]] call FLO_fnc_sideMissionTemplate;
    };
    
    // Register more templates here as they are created
    // ["register", "hvt_elimination", [...]] call FLO_fnc_sideMissionTemplate;
    // ["register", "intel_recovery", [...]] call FLO_fnc_sideMissionTemplate;
    
    diag_log "[FLO_INIT_P5] Side mission templates registered";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_sideMissionTemplate not found";
};

diag_log "[FLO_INIT_P5] Starting side mission manager...";
if (!isNil "FLO_fnc_sideMissionManager") then {
    ["start"] call FLO_fnc_sideMissionManager;
    diag_log "[FLO_INIT_P5] Side mission manager started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_sideMissionManager not found";
};

// ============================================
// Intel System
// ============================================
diag_log "[FLO_INIT_P5] Starting intel system...";
if (!isNil "FLO_fnc_intelSystem") then {
    [] spawn FLO_fnc_intelSystem;
    diag_log "[FLO_INIT_P5] Intel system started";
} else {
    diag_log "[FLO_INIT_P5] WARNING: FLO_fnc_intelSystem not found";
};

// ============================================
// Config Cache (if not already initialized)
// ============================================
if (isNil "FLO_ConfigCache") then {
    diag_log "[FLO_INIT_P5] Initializing config cache...";
    if (!isNil "FLO_fnc_objectiveConfig") then {
        ["init"] call FLO_fnc_objectiveConfig;
        diag_log "[FLO_INIT_P5] Config cache initialized";
    };
};

// ============================================
// Pathfinding System
// ============================================
diag_log "[FLO_INIT_P5] Initializing pathfinding...";
if (!isNil "FLO_fnc_initRoadGraph") then {
    [] spawn FLO_fnc_initRoadGraph;
    diag_log "[FLO_INIT_P5] Road graph initialization started";
};

if (!isNil "FLO_fnc_initPFScheduler") then {
    [] spawn FLO_fnc_initPFScheduler;
    diag_log "[FLO_INIT_P5] Pathfinding scheduler started";
};

diag_log "[FLO_INIT_P5] Mission systems phase complete";
true

