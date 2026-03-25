/*
 * Function: FLO_fnc_detectSavedGame
 * Author: Frontline Operations Development Group
 * Description:
 *   Detects if a saved game exists and extracts mission configuration.
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

// Check FreshStart parameter first
private _freshStart = "FreshStart" call BIS_fnc_getParamValue;
if (_freshStart isEqualTo 1) exitWith {
    ["SAVE_DETECT", 3, "Fresh start requested via mission parameter - ignoring saves"] call FLO_fnc_log;
    
    // Clear any existing save data
    missionProfileNamespace setVariable ["FLO_MissionData", nil];
    saveMissionProfileNamespace;
    
    [false, nil]
};

// Try to load saved data
private _saveData = missionProfileNamespace getVariable ["FLO_MissionData", nil];

// Validate save data exists and is proper type
if (isNil "_saveData") exitWith {
    ["SAVE_DETECT", 3, "No saved game data found"] call FLO_fnc_log;
    [false, nil]
};

if !(_saveData isEqualType createHashMap) exitWith {
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

private _expectedSaveVersion = 13;
private _saveVersion = _saveData get "saveVersion";
if (_saveVersion != _expectedSaveVersion) exitWith {
    [
        "SAVE_DETECT",
        2,
        format ["Save version %1 does not match mission schema %2 - treating as fresh start", _saveVersion, _expectedSaveVersion]
    ] call FLO_fnc_log;
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
    ["difficultyHandle", "FLO_DifficultyHandle"],
    ["gtnAttackLaneHandle", "FLO_GTN_AttackLaneHandle"],
    ["gtnDefenseCoverageHandle", "FLO_GTN_DefenseCoverageHandle"],
    ["gtnTempoHandle", "FLO_GTN_TempoHandle"],
    ["gtnForceGrowthHandle", "FLO_GTN_ForceGrowthHandle"],
    ["gtnGarrisonHandle", "FLO_GTN_GarrisonHandle"],
    ["moneyHandle", "FLO_MoneyHandle"],
    ["reputationHandle", "FLO_ReputationHandle"]
];

private _requiredConfigKeys = [
    "friendlyHandle",
    "enemyHandle",
    "civilianHandle",
    "difficultyHandle",
    "gtnAttackLaneHandle",
    "gtnDefenseCoverageHandle",
    "gtnTempoHandle",
    "gtnForceGrowthHandle",
    "gtnGarrisonHandle",
    "moneyHandle",
    "reputationHandle",
    "objectiveSizeThreshold",
    "virtualizationDistance",
    "enemyPrec"
];

private _missingConfigKeys = _requiredConfigKeys select { !(_x in _configData) };
if (count _missingConfigKeys > 0) exitWith {
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

// Create FLO_MissionConfig equivalent for Phase Manager
private _missionConfig = createHashMapFromArray [
    ["bluforFaction", _savedConfig get "FLO_FriendlyHandle"],
    ["opforFaction", _savedConfig get "FLO_EnemyHandle"],
    ["civFaction", _savedConfig get "FLO_CivilianHandle"],
    ["difficulty", _savedConfig get "FLO_DifficultyHandle"],
    ["startingFunds", _savedConfig get "FLO_MoneyHandle"],
    ["startingReputation", _savedConfig get "FLO_ReputationHandle"],
    ["isLoadedSave", true]  // Flag to indicate this is from a save
];

["SAVE_DETECT", 3, format ["Valid save found with %1 faction handles", _foundHandles]] call FLO_fnc_log;
["SAVE_DETECT", 5, format ["Loaded config: %1", _missionConfig]] call FLO_fnc_log;

[true, _missionConfig]
