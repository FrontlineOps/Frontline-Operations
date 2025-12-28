/*
 * Function: FLO_fnc_initPhase4_Virtualization
 * Author: Frontline Operations Development Group
 * Description:
 *   Phase 4: Initialize virtualization system and create OPFOR groups.
 *
 * Arguments: None
 * Returns: Boolean - True if virtualization initialized successfully
 */

if (!isServer) exitWith { false };

diag_log "[FLO_INIT_P4] Initializing virtualization...";

// Check if already initialized (saved game)
if (!isNil "InitializationOG" && {InitializationOG}) exitWith {
    diag_log "[FLO_INIT_P4] Virtualization already initialized (saved game)";
    
    // Restart the update loop
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

