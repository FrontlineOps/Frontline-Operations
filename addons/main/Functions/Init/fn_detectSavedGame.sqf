/*
 * Detects an explicitly requested save, migrates supported schemas, and
 * returns the authoritative mission configuration used by Phase 1.
 */

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
    ["SAVE_DETECT", 2, "Save data has an invalid type; opening fresh setup"] call FLO_fnc_log;
    [false, nil]
};

private _requiredRootKeys = ["time", "markers", "saveVersion"];
private _missingRootKeys = _requiredRootKeys select { !(_x in _saveData) };
if (_missingRootKeys isNotEqualTo []) exitWith {
    ["SAVE_DETECT", 2, format ["Save is missing required root keys: %1", _missingRootKeys]] call FLO_fnc_log;
    [false, nil]
};

private _supportedSaveVersions = [18, 19, 20, 21, 22, 23, 24];
private _saveVersion = _saveData get "saveVersion";
if !(_saveVersion in _supportedSaveVersions) exitWith {
    ["SAVE_DETECT", 2, format [
        "Save version %1 is unsupported; supported versions are %2",
        _saveVersion,
        _supportedSaveVersions
    ]] call FLO_fnc_log;
    [false, nil]
};

private _missingCampaignKeys = [];
if (_saveVersion in [20, 21, 22, 23, 24]) then {
    private _requiredCampaignKeys = ["config", "objectives", "virtualGroups", "campaignOperation"];
    if (_saveVersion >= 21) then {
        _requiredCampaignKeys append ["sideResources", "logisticsNetworkBySide"];
    };
    if (_saveVersion >= 22) then {
        _requiredCampaignKeys pushBack "baseDeploymentState";
    };
    _missingCampaignKeys = _requiredCampaignKeys select { !(_x in _saveData) };
};
if (_missingCampaignKeys isNotEqualTo []) exitWith {
    ["SAVE_DETECT", 2, format [
        "Version %1 save is missing campaign keys: %2",
        _saveVersion,
        _missingCampaignKeys
    ]] call FLO_fnc_log;
    [false, nil]
};

if !("config" in _saveData) exitWith {
    ["SAVE_DETECT", 2, "Save has no mission configuration"] call FLO_fnc_log;
    [false, nil]
};
private _configData = _saveData get "config";
if !(_configData isEqualType createHashMap) exitWith {
    ["SAVE_DETECT", 2, "Saved mission configuration is not a HashMap"] call FLO_fnc_log;
    [false, nil]
};

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
        if ("logisticsNetworkBySide" in _saveData && {"objectives" in _saveData}) then {
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
};

if (_migrationError != "") exitWith {
    ["SAVE_DETECT", 2, _migrationError] call FLO_fnc_log;
    [false, nil]
};

private _legacyFactionMigrationError = "";
if (_saveVersion < 24) then {
    private _legacyFactionKeys = ["friendlyHandle", "enemyHandle", "civilianHandle"];
    private _missingLegacyFactionKeys = _legacyFactionKeys select { !(_x in _configData) };
    if (_missingLegacyFactionKeys isNotEqualTo []) then {
        _legacyFactionMigrationError = format [
            "Legacy save is missing faction handles: %1",
            _missingLegacyFactionKeys
        ];
    } else {
        private _legacyBluforHandle = _configData get "friendlyHandle";
        private _legacyOpforHandle = _configData get "enemyHandle";
        private _legacyCivilianHandle = _configData get "civilianHandle";
        try {
            if (([_legacyBluforHandle] call FLO_fnc_factionHandleSide) != 1) then {
                throw format [
                    "Legacy friendly faction %1 is not native BLUFOR",
                    _legacyBluforHandle get "name"
                ];
            };
            if (([_legacyOpforHandle] call FLO_fnc_factionHandleSide) != 0) then {
                throw format [
                    "Legacy enemy faction %1 is not native OPFOR",
                    _legacyOpforHandle get "name"
                ];
            };
            if (([_legacyCivilianHandle] call FLO_fnc_factionHandleSide) != 3) then {
                throw format [
                    "Legacy civilian faction %1 is not native civilian",
                    _legacyCivilianHandle get "name"
                ];
            };
        } catch {
            _legacyFactionMigrationError = format [
                "Save version %1 cannot migrate to native faction sides: %2",
                _saveVersion,
                _exception
            ];
        };

        if (_legacyFactionMigrationError == "") then {
            if ((_legacyBluforHandle get "name") isEqualTo "CUSTOM_PLAYER_FACTION") then {
                _legacyBluforHandle set ["name", "CUSTOM_BLUFOR_FACTION"];
            };
            _legacyBluforHandle set ["side", 1];
            _legacyOpforHandle set ["side", 0];
            _legacyCivilianHandle set ["side", 3];

            _configData set ["bluforHandle", _legacyBluforHandle];
            _configData set ["opforHandle", _legacyOpforHandle];
            _configData set ["civilianHandle", _legacyCivilianHandle];
            _configData set ["playerSideKey", "WEST"];
            _configData deleteAt "friendlyHandle";
            _configData deleteAt "enemyHandle";

            ["SAVE_DETECT", 3, format [
                "Migrated mission save %1 faction roles to native-side config schema 24",
                _saveVersion
            ]] call FLO_fnc_log;
        };
    };
};

if (_legacyFactionMigrationError != "") exitWith {
    ["SAVE_DETECT", 2, _legacyFactionMigrationError + ". Opening fresh setup."] call FLO_fnc_log;
    [false, nil]
};

private _requiredConfigKeys = [
    "bluforHandle",
    "opforHandle",
    "civilianHandle",
    "playerSideKey",
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
    "enemyPrec",
    "startingResources",
    "startPosition"
];
private _missingConfigKeys = _requiredConfigKeys select { !(_x in _configData) };
if (_missingConfigKeys isNotEqualTo []) exitWith {
    ["SAVE_DETECT", 2, format ["Save config is missing required keys: %1", _missingConfigKeys]] call FLO_fnc_log;
    [false, nil]
};

private _nativeConfigError = "";
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
    _nativeConfigError = _exception;
};
if (_nativeConfigError != "") exitWith {
    ["SAVE_DETECT", 2, format ["Saved faction configuration is invalid: %1", _nativeConfigError]] call FLO_fnc_log;
    [false, nil]
};

_saveData set ["config", _configData];
FLO_SavedGameData = _saveData;
publicVariable "FLO_SavedGameData";

private _missionConfig = createHashMap;
{
    _missionConfig set [_x, _configData get _x];
} forEach (keys _configData);
_missionConfig set ["enemyPresence", _configData get "enemyPrec"];

["SAVE_DETECT", 3, format [
    "Validated mission save version %1 for player side %2",
    _saveVersion,
    _configData get "playerSideKey"
]] call FLO_fnc_log;

[true, _missionConfig]
