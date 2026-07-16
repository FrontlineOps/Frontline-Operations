/* Validates an explicitly requested save against the exact current universe version and shape. */
if (!isServer) exitWith { [false, nil] };

["SAVE_DETECT", 3, "Checking for saved game data"] call FLO_fnc_log;
private _launchMode = missionNamespace getVariable ["FLO_CampaignLaunchMode", 0];

if (_launchMode isEqualTo 2) exitWith {
    ["SAVE_DETECT", 3, "Reset saved progress requested"] call FLO_fnc_log;
    missionProfileNamespace setVariable ["FLO_MissionData", nil];
    saveMissionProfileNamespace;
    [false, nil]
};
if (_launchMode != 1) exitWith {
    ["SAVE_DETECT", 3, "Fresh setup selected; saved progress will not auto-load"] call FLO_fnc_log;
    [false, nil]
};

private _saveData = missionProfileNamespace getVariable ["FLO_MissionData", nil];
if (isNil "_saveData") exitWith {
    ["SAVE_DETECT", 3, "No saved game data found"] call FLO_fnc_log;
    [false, nil]
};
if !(_saveData isEqualType createHashMap) exitWith {
    ["SAVE_DETECT", 2, "Saved campaign has an invalid payload type and was not loaded"] call FLO_fnc_log;
    [false, nil]
};

if !("saveVersion" in _saveData) exitWith {
    ["SAVE_DETECT", 2, "Saved campaign has no universal save version and was not loaded"] call FLO_fnc_log;
    [false, nil]
};
private _saveVersion = _saveData get "saveVersion";
if !(_saveVersion isEqualType 0) exitWith {
    ["SAVE_DETECT", 2, format [
        "Saved campaign version has invalid type %1 and was not loaded",
        typeName _saveVersion
    ]] call FLO_fnc_log;
    [false, nil]
};
private _currentSaveVersion = FLO_MissionSaveVersion;
if (_saveVersion != _currentSaveVersion) exitWith {
    ["SAVE_DETECT", 2, format [
        "Saved campaign version %1 is incompatible with current version %2 and was not loaded",
        _saveVersion,
        _currentSaveVersion
    ]] call FLO_fnc_log;
    [false, nil]
};

private _requiredRootTypes = [
    ["time", []],
    ["markers", createHashMap],
    ["vehicles", createHashMap],
    ["objects", createHashMap],
    ["crates", createHashMap],
    ["minefields", []],
    ["minefieldObjectiveCooldowns", createHashMap],
    ["fobs", []],
    ["ops", []],
    ["config", createHashMap],
    ["objectives", createHashMap],
    ["virtualGroups", createHashMap],
    ["aiCommanders", createHashMap],
    ["sideResources", createHashMap],
    ["logisticsNetworkBySide", createHashMap],
    ["baseDeploymentState", createHashMap],
    ["idsLogisticsEntities", []]
];
{
    _x params ["_key", "_prototype"];
    if !(_key in _saveData) then {
        private _error = format ["Current mission save is missing required root field %1", _key];
        ["SAVE_DETECT", 1, _error] call FLO_fnc_log;
        throw _error;
    };
    private _value = _saveData get _key;
    if !(_value isEqualType _prototype) then {
        private _error = format [
            "Current mission save root field %1 has invalid type %2",
            _key,
            typeName _value
        ];
        ["SAVE_DETECT", 1, _error] call FLO_fnc_log;
        throw _error;
    };
} forEach _requiredRootTypes;
private _requiredRootKeys = ["saveVersion"] + (_requiredRootTypes apply {_x # 0});
private _unexpectedRootKeys = (keys _saveData) select {!(_x in _requiredRootKeys)};
if (_unexpectedRootKeys isNotEqualTo []) then {
    private _error = format ["Current mission save has unexpected root fields %1", _unexpectedRootKeys];
    ["SAVE_DETECT", 1, _error] call FLO_fnc_log;
    throw _error;
};

private _configData = _saveData get "config";
private _requiredConfigTypes = [
    ["bluforHandle", createHashMap],
    ["opforHandle", createHashMap],
    ["civilianHandle", createHashMap],
    ["playerSideKey", ""],
    ["reputationHandle", createHashMap],
    ["westDifficultyHandle", createHashMap],
    ["eastDifficultyHandle", createHashMap],
    ["westGTNAttackCoverageHandle", createHashMap],
    ["eastGTNAttackCoverageHandle", createHashMap],
    ["westGTNDefenseCoverageHandle", createHashMap],
    ["eastGTNDefenseCoverageHandle", createHashMap],
    ["westGTNTempoHandle", createHashMap],
    ["eastGTNTempoHandle", createHashMap],
    ["westGTNForceGrowthHandle", createHashMap],
    ["eastGTNForceGrowthHandle", createHashMap],
    ["westGTNGarrisonHandle", createHashMap],
    ["eastGTNGarrisonHandle", createHashMap],
    ["westFactionTuningHandle", createHashMap],
    ["eastFactionTuningHandle", createHashMap],
    ["startingResources", 0],
    ["objectiveSizeThreshold", 0],
    ["virtualizationDistance", 0],
    ["virtualizationUnitCap", 0],
    ["startingTerritoryWestRatio", 0],
    ["startPosition", []]
];
{
    _x params ["_key", "_prototype"];
    if !(_key in _configData) then {
        private _error = format ["Current mission configuration is missing required field %1", _key];
        ["SAVE_DETECT", 1, _error] call FLO_fnc_log;
        throw _error;
    };
    private _value = _configData get _key;
    if !(_value isEqualType _prototype) then {
        private _error = format [
            "Current mission configuration field %1 has invalid type %2",
            _key,
            typeName _value
        ];
        ["SAVE_DETECT", 1, _error] call FLO_fnc_log;
        throw _error;
    };
} forEach _requiredConfigTypes;
private _requiredConfigKeys = _requiredConfigTypes apply {_x # 0};
private _unexpectedConfigKeys = (keys _configData) select {!(_x in _requiredConfigKeys)};
if (_unexpectedConfigKeys isNotEqualTo []) then {
    private _error = format ["Current mission configuration has unexpected fields %1", _unexpectedConfigKeys];
    ["SAVE_DETECT", 1, _error] call FLO_fnc_log;
    throw _error;
};
if ((count (_configData get "startPosition")) < 2) then {
    private _error = "Current mission configuration startPosition is malformed";
    ["SAVE_DETECT", 1, _error] call FLO_fnc_log;
    throw _error;
};

private _configError = "";
try {
    if (([_configData get "bluforHandle"] call FLO_fnc_factionHandleSide) != 1) then {
        throw "Saved BLUFOR handle is not config side 1";
    };
    if (([_configData get "opforHandle"] call FLO_fnc_factionHandleSide) != 0) then {
        throw "Saved OPFOR handle is not config side 0";
    };
    if (([_configData get "civilianHandle"] call FLO_fnc_factionHandleSide) != 3) then {
        throw "Saved civilian handle is not config side 3";
    };
    if !((_configData get "playerSideKey") in ["WEST", "EAST"]) then {
        throw format ["Saved player side %1 is invalid", _configData get "playerSideKey"];
    };
} catch {
    _configError = _exception;
};
if (_configError != "") then {
    private _error = format ["Current mission faction configuration is invalid: %1", _configError];
    ["SAVE_DETECT", 1, _error] call FLO_fnc_log;
    throw _error;
};

FLO_SavedGameData = _saveData;
publicVariable "FLO_SavedGameData";
private _missionConfig = createHashMap;
{
    _missionConfig set [_x, _configData get _x];
} forEach (keys _configData);

["SAVE_DETECT", 3, format [
    "Validated current mission save version %1 for player side %2",
    _saveVersion,
    _configData get "playerSideKey"
]] call FLO_fnc_log;
[true, _missionConfig]
