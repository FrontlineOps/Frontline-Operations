/*
 * Function: FLO_fnc_initPhase1_MissionConfig
 * Author: Frontline Operations Development Group
 * Description:
 *   Phase 1: Wait for mission configuration from the commander's faction dialog.
 *   Handles both fresh starts (wait for dialog) and saved game loads.
 *
 * Arguments: None
 * Returns: Boolean - True if config received successfully
 */

if (!isServer) exitWith { false };

diag_log "[FLO_INIT_P1] Waiting for mission configuration...";

// Check if this is a saved game (FLO_MissionConfig already exists)
if (!isNil "FLO_MissionConfig" && {count keys FLO_MissionConfig > 0}) exitWith {
    diag_log "[FLO_INIT_P1] Loading from saved game - config already exists";
    
    // Restore handles from saved config
    if (isNil "FLO_FriendlyHandle") then {
        FLO_FriendlyHandle = FLO_MissionConfig getOrDefault ["friendlyHandle", createHashMapFromArray [["name", "NATO _ Woodland"]]];
        publicVariable "FLO_FriendlyHandle";
    };
    if (isNil "FLO_EnemyHandle") then {
        FLO_EnemyHandle = FLO_MissionConfig getOrDefault ["enemyHandle", createHashMapFromArray [["name", "CSAT _ Woodland"]]];
        publicVariable "FLO_EnemyHandle";
    };
    if (isNil "FLO_CivilianHandle") then {
        FLO_CivilianHandle = FLO_MissionConfig getOrDefault ["civilianHandle", createHashMapFromArray [["name", "Greek Civilians"]]];
        publicVariable "FLO_CivilianHandle";
    };
    
    // Mark starting location as done for saved games
    StartingLocationDone = true;
    publicVariable "StartingLocationDone";
    
    true
};

// Fresh start - wait for commander to complete faction dialog
diag_log "[FLO_INIT_P1] Fresh start detected - waiting for faction dialog";

// Initialize the config variable that the dialog will populate
FLO_MissionConfig = createHashMap;
publicVariable "FLO_MissionConfig";

// Wait for the mission config to be set by fn_factionDialogStart
private _startTime = diag_tickTime;
private _timeout = 600; // 10 minute timeout for faction selection

waitUntil {
    sleep 0.5;
    
    private _configReady = !isNil "FLO_MissionConfig" && {count keys FLO_MissionConfig > 0};
    private _timedOut = (diag_tickTime - _startTime) > _timeout;
    
    if (_timedOut && !_configReady) then {
        diag_log "[FLO_INIT_P1] WARNING: Still waiting for faction dialog after 10 minutes...";
    };
    
    _configReady || _timedOut
};

// Check if we got the config
if (isNil "FLO_MissionConfig" || {count keys FLO_MissionConfig == 0}) exitWith {
    FLO_InitError = "Mission configuration timeout - no faction selected";
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P1] ERROR: %1", FLO_InitError];
    false
};

// Validate required config fields
private _requiredFields = ["friendlyHandle", "enemyHandle", "civilianHandle"];
private _missingFields = _requiredFields select { !(_x in FLO_MissionConfig) };

if (count _missingFields > 0) exitWith {
    FLO_InitError = format ["Mission config missing required fields: %1", _missingFields];
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P1] ERROR: %1", FLO_InitError];
    false
};

// Extract and set global handles for backwards compatibility
FLO_FriendlyHandle = FLO_MissionConfig get "friendlyHandle";
FLO_EnemyHandle = FLO_MissionConfig get "enemyHandle";
FLO_CivilianHandle = FLO_MissionConfig get "civilianHandle";

publicVariable "FLO_FriendlyHandle";
publicVariable "FLO_EnemyHandle";
publicVariable "FLO_CivilianHandle";

// Set other config values
if ("reputationHandle" in FLO_MissionConfig) then {
    FLO_ReputationHandle = FLO_MissionConfig get "reputationHandle";
    publicVariable "FLO_ReputationHandle";
};

if ("difficultyHandle" in FLO_MissionConfig) then {
    FLO_DifficultyHandle = FLO_MissionConfig get "difficultyHandle";
    publicVariable "FLO_DifficultyHandle";
};

if ("moneyHandle" in FLO_MissionConfig) then {
    FLO_MoneyHandle = FLO_MissionConfig get "moneyHandle";
    publicVariable "FLO_MoneyHandle";
};

if ("enemyPresence" in FLO_MissionConfig) then {
    EnemyPrec = FLO_MissionConfig get "enemyPresence";
    publicVariable "EnemyPrec";
};

// Mark starting location as done
StartingLocationDone = true;
publicVariable "StartingLocationDone";

diag_log format ["[FLO_INIT_P1] Mission config received: Friendly=%1, Enemy=%2, Civilian=%3",
    FLO_FriendlyHandle get "name",
    FLO_EnemyHandle get "name",
    FLO_CivilianHandle get "name"
];

true

