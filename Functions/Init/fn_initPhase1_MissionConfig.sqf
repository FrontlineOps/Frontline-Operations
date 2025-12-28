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

// Check if this is a saved game (FLO_IsLoadedSave flag set by Phase 0)
if (!isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave}) exitWith {
    diag_log "[FLO_INIT_P1] Loading from saved game - using saved config";

    // Restore faction handles from saved game data
    // The save stores config under "config" sub-hashmap
    if (!isNil "FLO_SavedGameData") then {
        private _savedData = FLO_SavedGameData;
        // Config is stored under "config" key, not at root level
        private _configData = _savedData getOrDefault ["config", createHashMap];

        diag_log format ["[FLO_INIT_P1] Loading config from save - found %1 keys in config", count keys _configData];

        // Restore faction handles from the config sub-hashmap
        if ("friendlyHandle" in _configData) then {
            FLO_FriendlyHandle = _configData get "friendlyHandle";
            publicVariable "FLO_FriendlyHandle";
        };
        if ("enemyHandle" in _configData) then {
            FLO_EnemyHandle = _configData get "enemyHandle";
            publicVariable "FLO_EnemyHandle";
        };
        if ("civilianHandle" in _configData) then {
            FLO_CivilianHandle = _configData get "civilianHandle";
            publicVariable "FLO_CivilianHandle";
        };
        if ("reputationHandle" in _configData) then {
            FLO_ReputationHandle = _configData get "reputationHandle";
            publicVariable "FLO_ReputationHandle";
        };
        if ("difficultyHandle" in _configData) then {
            FLO_DifficultyHandle = _configData get "difficultyHandle";
            publicVariable "FLO_DifficultyHandle";
        };
        if ("moneyHandle" in _configData) then {
            FLO_MoneyHandle = _configData get "moneyHandle";
            publicVariable "FLO_MoneyHandle";
        };
        if ("enemyPrec" in _configData) then {
            EnemyPrec = _configData get "enemyPrec";
            publicVariable "EnemyPrec";
        };

        diag_log format ["[FLO_INIT_P1] Restored handles from save: Friendly=%1, Enemy=%2",
            if (!isNil "FLO_FriendlyHandle" && {FLO_FriendlyHandle isEqualType createHashMap}) then {FLO_FriendlyHandle get "name"} else {"(not set)"},
            if (!isNil "FLO_EnemyHandle" && {FLO_EnemyHandle isEqualType createHashMap}) then {FLO_EnemyHandle get "name"} else {"(not set)"}
        ];
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

