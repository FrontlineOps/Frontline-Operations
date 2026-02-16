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
private _requiredKeys = ["time", "markers"];
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

// Extract mission configuration from save
// These are the handles that were set during initial faction dialog
private _savedConfig = createHashMap;

// Get the config sub-hashmap
private _configData = _saveData getOrDefault ["config", createHashMap];

// Try to get saved faction handles from the config sub-hashmap
private _handleKeys = [
    ["friendlyHandle", "FLO_FriendlyHandle"],
    ["enemyHandle", "FLO_EnemyHandle"],
    ["civilianHandle", "FLO_CivilianHandle"],
    ["difficultyHandle", "FLO_DifficultyHandle"],
    ["gtnAttackHandle", "FLO_GTN_AttackHandle"],
    ["gtnDefenseHandle", "FLO_GTN_DefenseHandle"],
    ["gtnTempoHandle", "FLO_GTN_TempoHandle"],
    ["moneyHandle", "FLO_MoneyHandle"],
    ["reputationHandle", "FLO_ReputationHandle"]
];

private _foundHandles = 0;
{
    _x params ["_saveKey", "_varName"];
    if (_saveKey in _configData) then {
        private _value = _configData get _saveKey;
        _savedConfig set [_varName, _value];
        _foundHandles = _foundHandles + 1;
    };
} forEach _handleKeys;

// We need at least the faction handles to proceed
if (_foundHandles < 3) exitWith {
    ["SAVE_DETECT", 2, format ["Only found %1/3 required faction handles - treating as fresh start", _foundHandles]] call FLO_fnc_log;
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
    ["bluforFaction", _savedConfig getOrDefault ["FLO_FriendlyHandle", 1]],
    ["opforFaction", _savedConfig getOrDefault ["FLO_EnemyHandle", 1]],
    ["civFaction", _savedConfig getOrDefault ["FLO_CivilianHandle", 1]],
    ["difficulty", _savedConfig getOrDefault ["FLO_DifficultyHandle", 2]],
    ["startingFunds", _savedConfig getOrDefault ["FLO_MoneyHandle", 5000]],
    ["startingReputation", _savedConfig getOrDefault ["FLO_ReputationHandle", 50]],
    ["isLoadedSave", true]  // Flag to indicate this is from a save
];

["SAVE_DETECT", 3, format ["Valid save found with %1 faction handles", _foundHandles]] call FLO_fnc_log;
["SAVE_DETECT", 5, format ["Loaded config: %1", _missionConfig]] call FLO_fnc_log;

[true, _missionConfig]
