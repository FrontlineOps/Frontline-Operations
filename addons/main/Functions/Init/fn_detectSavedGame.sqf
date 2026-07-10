/*
 * Function: FLO_fnc_detectSavedGame
 * Author: Frontline Operations Development Group
 * Description:
 *   Detects if the admin explicitly requested saved progress, validates the
 *   save, and extracts mission configuration.
 *   Called BEFORE Phase 1 to determine if we should skip faction dialog.
 *
 * Arguments: None
 *
 * Returns:
 *   ARRAY - [hasSave, configData]
 *     hasSave: BOOL - true if valid save exists
 *     configData: HASHMAP or NIL - FLO_MissionConfig equivalent from save
 *
 * Note: This function does NOT load entities (vehicles, objects, etc.)
 *       It only extracts config needed to initialize factions.
 */

if (!isServer) exitWith { [false, nil] };

["SAVE_DETECT", 3, "Checking for saved game data..."] call FLO_fnc_log;

private _launchMode = missionNamespace getVariable ["FLO_CampaignLaunchMode", 0];

if (_launchMode isEqualTo 2) exitWith {
    ["SAVE_DETECT", 3, "Reset saved progress requested through CBA campaign launch mode"] call FLO_fnc_log;
    missionProfileNamespace setVariable ["FLO_MissionData", nil];
    saveMissionProfileNamespace;

    [false, nil]
};

if (_launchMode != 1) exitWith {
    ["SAVE_DETECT", 3, "Fresh setup selected through CBA campaign launch mode - saved progress will not auto-load"] call FLO_fnc_log;
    [false, nil]
};

// Try to load saved data
private _saveData = missionProfileNamespace getVariable ["FLO_MissionData", nil];

// Validate save data exists and is proper type
if (isNil "_saveData") exitWith {
    ["SAVE_DETECT", 3, "No saved game data found"] call FLO_fnc_log;
    [false, nil]
};

if (!(_saveData isEqualType createHashMap)) exitWith {
    ["SAVE_DETECT", 2, "Save data exists but is invalid type - treating as fresh start"] call FLO_fnc_log;
    [false, nil]
};

// Check for required keys to validate save integrity
private _requiredKeys = ["time", "markers", "saveVersion"];
private _hasRequired = true;
{
    if !(_x in _saveData) then {
        ["SAVE_DETECT", 2, format ["Save missing required key: %1", _x]] call FLO_fnc_log;
        _hasRequired = false;
    };
} forEach _requiredKeys;

if (!_hasRequired) exitWith {
    ["SAVE_DETECT", 2, "Save data incomplete - treating as fresh start"] call FLO_fnc_log;
    [false, nil]
};

private _supportedSaveVersions = [18, 19, 20, 21, 22, 23];
private _saveVersion = _saveData get "saveVersion";
if !(_saveVersion in _supportedSaveVersions) exitWith {
    [
        "SAVE_DETECT",
        2,
        format ["Save version %1 is not supported by mission schemas %2 - treating as fresh start", _saveVersion, _supportedSaveVersions]
    ] call FLO_fnc_log;
    [false, nil]
};

private _missingCampaignKeys = [];
if (_saveVersion in [20, 21, 22, 23]) then {
    private _requiredCampaignKeys = ["config", "objectives", "virtualGroups", "campaignOperation"];
    if (_saveVersion >= 21) then {
        _requiredCampaignKeys append ["sideResources", "logisticsNetworkBySide"];
    };
    if (_saveVersion >= 22) then { _requiredCampaignKeys pushBack "baseDeploymentState"; };
    _missingCampaignKeys = _requiredCampaignKeys select { !(_x in _saveData) };
};
if (_missingCampaignKeys isNotEqualTo []) exitWith {
    ["SAVE_DETECT", 2, format ["Version %1 save missing campaign keys: %2", _saveVersion, _missingCampaignKeys]] call FLO_fnc_log;
    [false, nil]
};

// Extract mission configuration from save
// These are the handles that were set during initial faction dialog
private _savedConfig = createHashMap;

// Get the config sub-hashmap
private _configData = _saveData getOrDefault ["config", createHashMap];

private _handleKeys = [
    ["friendlyHandle", "FLO_FriendlyHandle"],
    ["enemyHandle", "FLO_EnemyHandle"],
    ["civilianHandle", "FLO_CivilianHandle"],
    ["westDifficultyHandle", "FLO_WestDifficultyHandle"],
    ["eastDifficultyHandle", "FLO_EastDifficultyHandle"],
    ["westGTNAttackCoverageHandle", "FLO_WestGTN_AttackCoverageHandle"],
    ["eastGTNAttackCoverageHandle", "FLO_EastGTN_AttackCoverageHandle"],
    ["westGTNDefenseCoverageHandle", "FLO_WestGTN_DefenseCoverageHandle"],
    ["eastGTNDefenseCoverageHandle", "FLO_EastGTN_DefenseCoverageHandle"],
    ["westGTNTempoHandle", "FLO_WestGTN_TempoHandle"],
    ["eastGTNTempoHandle", "FLO_EastGTN_TempoHandle"],
    ["westGTNForceGrowthHandle", "FLO_WestGTN_ForceGrowthHandle"],
    ["eastGTNForceGrowthHandle", "FLO_EastGTN_ForceGrowthHandle"],
    ["westGTNGarrisonHandle", "FLO_WestGTN_GarrisonHandle"],
    ["eastGTNGarrisonHandle", "FLO_EastGTN_GarrisonHandle"],
    ["reputationHandle", "FLO_ReputationHandle"]
];

private _requiredConfigKeys = [
    "friendlyHandle",
    "enemyHandle",
    "civilianHandle",
    "westDifficultyHandle",
    "eastDifficultyHandle",
    "westGTNAttackCoverageHandle",
    "eastGTNAttackCoverageHandle",
    "westGTNDefenseCoverageHandle",
    "eastGTNDefenseCoverageHandle",
    "westGTNTempoHandle",
    "eastGTNTempoHandle",
    "westGTNForceGrowthHandle",
    "eastGTNForceGrowthHandle",
    "westGTNGarrisonHandle",
    "eastGTNGarrisonHandle",
    "reputationHandle",
    "objectiveSizeThreshold",
    "virtualizationDistance",
    "virtualizationUnitCap",
    "startingTerritoryWestRatio",
    "enemyPrec"
];

private _migrationError = "";
if (_saveVersion < 21) then {
    if !("moneyHandle" in _configData) then {
        _migrationError = "Legacy save config is missing moneyHandle";
    } else {
        private _legacyMoney = _configData get "moneyHandle";
        if !(_legacyMoney isEqualType createHashMap && {"value" in _legacyMoney}) then {
            _migrationError = "Legacy save moneyHandle is malformed";
        } else {
            private _legacyMoneyValue = _legacyMoney get "value";
            if !(_legacyMoneyValue isEqualType 0 && {_legacyMoneyValue >= 0}) then {
                _migrationError = format ["Legacy save money value is invalid: %1", _legacyMoneyValue];
            };
        };
    };

    _configData set ["startingResources", 5000];

    if !("startPosition" in _configData) then {
        private _migratedStartPosition = [];
        if (
            "logisticsNetworkBySide" in _saveData
            && {"objectives" in _saveData}
        ) then {
            private _legacyNetworks = _saveData get "logisticsNetworkBySide";
            private _legacyObjectives = _saveData get "objectives";
            if (_legacyNetworks isEqualType createHashMap && {"WEST" in _legacyNetworks}) then {
                private _legacyWestNetwork = _legacyNetworks get "WEST";
                if (_legacyWestNetwork isEqualType createHashMap && {"hqObjectiveId" in _legacyWestNetwork}) then {
                    private _legacyHqObjectiveId = _legacyWestNetwork get "hqObjectiveId";
                    if (_legacyHqObjectiveId in _legacyObjectives) then {
                        _migratedStartPosition = +((_legacyObjectives get _legacyHqObjectiveId) get "position");
                    };
                };
            };
        };

        if (_migratedStartPosition isEqualTo []) then {
            private _savedMarkers = _saveData get "markers";
            {
                if ((toLower _x) find "respawn_west" == 0) exitWith {
                    _migratedStartPosition = +((_savedMarkers get _x) get "pos");
                };
            } forEach (keys _savedMarkers);
        };

        if (_migratedStartPosition isEqualTo []) then {
            _migrationError = "Legacy save has no recoverable WEST start position";
        } else {
            _configData set ["startPosition", _migratedStartPosition];
        };
    };
} else {
    _requiredConfigKeys append ["startingResources", "startPosition"];
};

if (_migrationError != "") exitWith {
    ["SAVE_DETECT", 2, _migrationError] call FLO_fnc_log;
    [false, nil]
};

private _missingConfigKeys = _requiredConfigKeys select { !(_x in _configData) };
if (_missingConfigKeys isNotEqualTo []) exitWith {
    ["SAVE_DETECT", 2, format ["Save config missing required keys: %1", _missingConfigKeys]] call FLO_fnc_log;
    [false, nil]
};

private _foundHandles = 0;
{
    _x params ["_saveKey", "_varName"];
    if (_saveKey in _configData) then {
        private _value = _configData get _saveKey;
        _savedConfig set [_varName, _value];
        _foundHandles = _foundHandles + 1;
    };
} forEach _handleKeys;

if (_foundHandles != count _handleKeys) exitWith {
    ["SAVE_DETECT", 2, format ["Only found %1/%2 required config handles - treating as fresh start", _foundHandles, count _handleKeys]] call FLO_fnc_log;
    [false, nil]
};

// Also extract structure types if saved (for FOB/OP initialization)
if ("structureTypes" in _saveData) then {
    _savedConfig set ["structureTypes", _saveData get "structureTypes"];
};

// Store the raw save data globally for later phases to access
FLO_SavedGameData = _saveData;
publicVariable "FLO_SavedGameData";

["SAVE_DETECT", 3, format ["Valid save found with %1 faction handles", _foundHandles]] call FLO_fnc_log;
private _missionConfig = createHashMap;
{
    _missionConfig set [_x, _configData get _x];
} forEach (keys _configData);
_missionConfig set ["enemyPresence", _configData get "enemyPrec"];

["SAVE_DETECT", 5, format ["Loaded config: %1", _missionConfig]] call FLO_fnc_log;

[true, _missionConfig]
