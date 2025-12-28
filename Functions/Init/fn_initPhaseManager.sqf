/*
 * Function: FLO_fnc_initPhaseManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Central initialization phase manager. Controls the entire mission startup
 *   sequence with proper dependency tracking and error handling.
 *
 *   ALL initialization runs on the server. Clients just wait for completion.
 *
 * Phases:
 *   0: Save Detection - Check for saved game, load config if present
 *   1: Mission Config - Wait for faction dialog OR use saved config
 *   2: Factions - Load faction scripts based on config
 *   3: Objectives - Index objectives OR restore from save
 *   4: Virtualization - Setup virtualization OR restore from save
 *   5: Mission Systems - Start side missions, AI commander, startup systems
 *
 * Global Variables Set:
 *   FLO_InitPhase - Current phase number (0-5, 99=complete, -1=error)
 *   FLO_InitError - Error message if initialization failed
 *   FLO_MissionReady - Final ready flag for clients to check
 *   FLO_IsLoadedSave - True if loading from saved game
 *   FLO_SavedGameData - Raw save data (if loading from save)
 *
 * Arguments: None
 * Returns: Boolean - True if initialization completed successfully
 *
 * Example:
 *   [] call FLO_fnc_initPhaseManager;
 */

if (!isServer) exitWith {
    diag_log "[FLO_INIT] Phase manager called on non-server - ignoring";
    false
};

// Initialize phase tracking
FLO_InitPhase = 0;
FLO_InitError = "";
FLO_MissionReady = false;
FLO_IsLoadedSave = false;
publicVariable "FLO_InitPhase";
publicVariable "FLO_InitError";
publicVariable "FLO_MissionReady";
publicVariable "FLO_IsLoadedSave";

diag_log "[FLO_INIT] ========================================";
diag_log "[FLO_INIT] Phase Manager Starting";
diag_log "[FLO_INIT] ========================================";

// ============================================================================
// PHASE 0: SAVE DETECTION
// ============================================================================

diag_log "[FLO_INIT] === PHASE 0: Save Detection ===";
private _saveResult = [] call FLO_fnc_detectSavedGame;
_saveResult params ["_hasSave", "_savedConfig"];

if (_hasSave) then {
    FLO_IsLoadedSave = true;
    publicVariable "FLO_IsLoadedSave";

    // Set the mission config from save so Phase 1 can use it
    FLO_MissionConfig = _savedConfig;
    publicVariable "FLO_MissionConfig";

    diag_log "[FLO_INIT] Loading from saved game - skipping faction dialog";
} else {
    diag_log "[FLO_INIT] Fresh start - will wait for faction dialog";
};

// Helper function to run a phase with error handling
private _fnc_runPhase = {
    params ["_phaseNum", "_phaseName", "_phaseFunc"];
    
    FLO_InitPhase = _phaseNum;
    publicVariable "FLO_InitPhase";
    
    diag_log format ["[FLO_INIT] === PHASE %1: %2 ===", _phaseNum, _phaseName];
    
    private _startTime = diag_tickTime;
    private _success = false;
    
    try {
        _success = [] call _phaseFunc;
    } catch {
        FLO_InitError = format ["Phase %1 (%2) exception: %3", _phaseNum, _phaseName, _exception];
        diag_log format ["[FLO_INIT] ERROR: %1", FLO_InitError];
        publicVariable "FLO_InitError";
        _success = false;
    };
    
    private _duration = diag_tickTime - _startTime;
    
    if (_success) then {
        diag_log format ["[FLO_INIT] Phase %1 completed in %2 seconds", _phaseNum, _duration toFixed 2];
    } else {
        if (FLO_InitError isEqualTo "") then {
            FLO_InitError = format ["Phase %1 (%2) returned false", _phaseNum, _phaseName];
            publicVariable "FLO_InitError";
        };
        diag_log format ["[FLO_INIT] Phase %1 FAILED after %2 seconds: %3", _phaseNum, _duration toFixed 2, FLO_InitError];
    };
    
    _success
};

// Phase definitions
private _phases = [
    [1, "Mission Config", FLO_fnc_initPhase1_MissionConfig],
    [2, "Factions", FLO_fnc_initPhase2_Factions],
    [3, "Objectives", FLO_fnc_initPhase3_Objectives],
    [4, "Virtualization", FLO_fnc_initPhase4_Virtualization],
    [5, "Mission Systems", FLO_fnc_initPhase5_MissionSystems]
];

// Run all phases in sequence
private _allSuccess = true;
{
    _x params ["_num", "_name", "_func"];
    
    if (_allSuccess) then {
        _allSuccess = [_num, _name, _func] call _fnc_runPhase;
        
        if (!_allSuccess) then {
            diag_log format ["[FLO_INIT] Initialization stopped at phase %1", _num];
            FLO_InitPhase = -1;
            publicVariable "FLO_InitPhase";
        };
    };
} forEach _phases;

// Finalization
if (_allSuccess) then {
    FLO_InitPhase = 99;
    FLO_MissionReady = true;
    publicVariable "FLO_InitPhase";
    publicVariable "FLO_MissionReady";
    
    diag_log "[FLO_INIT] ========================================";
    diag_log "[FLO_INIT] ALL PHASES COMPLETE - MISSION READY";
    diag_log "[FLO_INIT] ========================================";
    
    // Notify all players
    ["FLO_INIT_COMPLETE", []] remoteExec ["FLO_fnc_initClientFinalize", 0];
} else {
    diag_log "[FLO_INIT] ========================================";
    diag_log format ["[FLO_INIT] INITIALIZATION FAILED: %1", FLO_InitError];
    diag_log "[FLO_INIT] ========================================";
    
    // Notify all players of failure
    [FLO_InitError] remoteExec ["hint", 0];
};

_allSuccess

