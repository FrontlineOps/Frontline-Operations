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
FLO_VirtualizationUnitCap = 200;
publicVariable "FLO_VirtualizationUnitCap";

// Check if this is a saved game (FLO_IsLoadedSave flag set by Phase 0)
if (!isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave}) exitWith {
    diag_log "[FLO_INIT_P1] Loading from saved game - using saved config";

    // Restore faction handles from saved game data
    // The save stores config under "config" sub-hashmap
    if (!isNil "FLO_SavedGameData") then {
        private _savedData = FLO_SavedGameData;
        // Config is stored under "config" key, not at root level
        private _configData = _savedData get "config";

        diag_log format ["[FLO_INIT_P1] Loading config from save - found %1 keys in config", count keys _configData];

        // Restore required config fields from saved config
        FLO_FriendlyHandle = _configData get "friendlyHandle";
        FLO_EnemyHandle = _configData get "enemyHandle";
        FLO_CivilianHandle = _configData get "civilianHandle";
        FLO_ReputationHandle = _configData get "reputationHandle";
        FLO_DifficultyHandle = _configData get "difficultyHandle";
        FLO_GTN_AttackLaneHandle = _configData get "gtnAttackLaneHandle";
        FLO_GTN_DefenseCoverageHandle = _configData get "gtnDefenseCoverageHandle";
        FLO_GTN_TempoHandle = _configData get "gtnTempoHandle";
        FLO_GTN_ForceGrowthHandle = _configData get "gtnForceGrowthHandle";
        FLO_GTN_GarrisonHandle = _configData get "gtnGarrisonHandle";
        FLO_MoneyHandle = _configData get "moneyHandle";
        EnemyPrec = _configData get "enemyPrec";
        FLO_ObjectiveSizeThreshold = _configData get "objectiveSizeThreshold";
        FLO_VirtualizationDistance = _configData get "virtualizationDistance";
        FLO_VirtualizationUnitCap = _configData get "virtualizationUnitCap";

        publicVariable "FLO_FriendlyHandle";
        publicVariable "FLO_EnemyHandle";
        publicVariable "FLO_CivilianHandle";
        publicVariable "FLO_ReputationHandle";
        publicVariable "FLO_DifficultyHandle";
        publicVariable "FLO_GTN_AttackLaneHandle";
        publicVariable "FLO_GTN_DefenseCoverageHandle";
        publicVariable "FLO_GTN_TempoHandle";
        publicVariable "FLO_GTN_ForceGrowthHandle";
        publicVariable "FLO_GTN_GarrisonHandle";
        publicVariable "FLO_MoneyHandle";
        publicVariable "EnemyPrec";
        publicVariable "FLO_ObjectiveSizeThreshold";
        publicVariable "FLO_VirtualizationDistance";
        publicVariable "FLO_VirtualizationUnitCap";

        diag_log format ["[FLO_INIT_P1] Restored handles from save: Friendly=%1, Enemy=%2",
            FLO_FriendlyHandle get "name",
            FLO_EnemyHandle get "name"
        ];
    };

    diag_log format [
        "[FLO_INIT_P1] Restored world settings: objectiveSizeThreshold=%1 virtualizationDistance=%2m virtualizationUnitCap=%3",
        FLO_ObjectiveSizeThreshold,
        FLO_VirtualizationDistance,
        FLO_VirtualizationUnitCap
    ];

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
private _requiredFields = [
    "friendlyHandle",
    "enemyHandle",
    "civilianHandle",
    "reputationHandle",
    "difficultyHandle",
    "gtnAttackLaneHandle",
    "gtnDefenseCoverageHandle",
    "gtnTempoHandle",
    "gtnForceGrowthHandle",
    "gtnGarrisonHandle",
    "moneyHandle",
    "enemyPresence",
    "objectiveSizeThreshold",
    "virtualizationDistance",
    "virtualizationUnitCap",
    "startPosition"
];
private _missingFields = _requiredFields select { !(_x in FLO_MissionConfig) };

if (count _missingFields > 0) exitWith {
    FLO_InitError = format ["Mission config missing required fields: %1", _missingFields];
    publicVariable "FLO_InitError";
    diag_log format ["[FLO_INIT_P1] ERROR: %1", FLO_InitError];
    false
};

// Extract and set global handles
FLO_FriendlyHandle = FLO_MissionConfig get "friendlyHandle";
FLO_EnemyHandle = FLO_MissionConfig get "enemyHandle";
FLO_CivilianHandle = FLO_MissionConfig get "civilianHandle";

publicVariable "FLO_FriendlyHandle";
publicVariable "FLO_EnemyHandle";
publicVariable "FLO_CivilianHandle";

// Set required config values
FLO_ReputationHandle = FLO_MissionConfig get "reputationHandle";
FLO_DifficultyHandle = FLO_MissionConfig get "difficultyHandle";
FLO_GTN_AttackLaneHandle = FLO_MissionConfig get "gtnAttackLaneHandle";
FLO_GTN_DefenseCoverageHandle = FLO_MissionConfig get "gtnDefenseCoverageHandle";
FLO_GTN_TempoHandle = FLO_MissionConfig get "gtnTempoHandle";
FLO_GTN_ForceGrowthHandle = FLO_MissionConfig get "gtnForceGrowthHandle";
FLO_GTN_GarrisonHandle = FLO_MissionConfig get "gtnGarrisonHandle";
FLO_MoneyHandle = FLO_MissionConfig get "moneyHandle";
EnemyPrec = FLO_MissionConfig get "enemyPresence";

publicVariable "FLO_ReputationHandle";
publicVariable "FLO_DifficultyHandle";
publicVariable "FLO_GTN_AttackLaneHandle";
publicVariable "FLO_GTN_DefenseCoverageHandle";
publicVariable "FLO_GTN_TempoHandle";
publicVariable "FLO_GTN_ForceGrowthHandle";
publicVariable "FLO_GTN_GarrisonHandle";
publicVariable "FLO_MoneyHandle";
publicVariable "EnemyPrec";

private _objectiveSizeThreshold = FLO_MissionConfig get "objectiveSizeThreshold";
FLO_ObjectiveSizeThreshold = _objectiveSizeThreshold;
publicVariable "FLO_ObjectiveSizeThreshold";

private _virtualizationDistance = FLO_MissionConfig get "virtualizationDistance";
FLO_VirtualizationDistance = _virtualizationDistance;
publicVariable "FLO_VirtualizationDistance";
private _virtualizationUnitCap = FLO_MissionConfig get "virtualizationUnitCap";
FLO_VirtualizationUnitCap = _virtualizationUnitCap;
publicVariable "FLO_VirtualizationUnitCap";
diag_log format [
    "[FLO_INIT_P1] World settings: objectiveSizeThreshold=%1 virtualizationDistance=%2m virtualizationUnitCap=%3",
    FLO_ObjectiveSizeThreshold,
    FLO_VirtualizationDistance,
    FLO_VirtualizationUnitCap
];

// Mark starting location as done
StartingLocationDone = true;
publicVariable "StartingLocationDone";

diag_log format ["[FLO_INIT_P1] Mission config received: Friendly=%1, Enemy=%2, Civilian=%3",
    FLO_FriendlyHandle get "name",
    FLO_EnemyHandle get "name",
    FLO_CivilianHandle get "name"
];

true
