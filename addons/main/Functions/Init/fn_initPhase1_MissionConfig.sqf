/*
 * Phase 1 receives one authoritative native-side campaign configuration.
 * Fresh setup and Continue converge here before any faction state is loaded.
 */

if (!isServer) exitWith { false };

["INIT", 3, "Phase 1 waiting for mission configuration"] call FLO_fnc_log;
FLO_VirtualizationUnitCap = 200;

private _loadedSave = !isNil "FLO_IsLoadedSave" && {FLO_IsLoadedSave};
if (!_loadedSave) then {
    FLO_MissionConfig = createHashMap;
    publicVariable "FLO_MissionConfig";

    private _lastWaitLog = diag_tickTime;
    waitUntil {
        sleep 0.5;
        private _ready = !isNil "FLO_MissionConfig"
            && {FLO_MissionConfig isEqualType createHashMap}
            && {(keys FLO_MissionConfig) isNotEqualTo []};

        if (!_ready && {(diag_tickTime - _lastWaitLog) > 60}) then {
            ["INIT", 3, "Phase 1 still waiting for an admin to submit mission setup"] call FLO_fnc_log;
            _lastWaitLog = diag_tickTime;
        };
        _ready
    };
} else {
    ["INIT", 3, "Phase 1 using migrated saved mission configuration"] call FLO_fnc_log;
};

if (
    isNil "FLO_MissionConfig"
    || {!(FLO_MissionConfig isEqualType createHashMap)}
    || {(keys FLO_MissionConfig) isEqualTo []}
) exitWith {
    FLO_InitError = "Mission configuration wait ended without setup data";
    publicVariable "FLO_InitError";
    ["INIT", 1, FLO_InitError] call FLO_fnc_log;
    false
};

private _requiredFields = [
    "bluforHandle",
    "opforHandle",
    "civilianHandle",
    "playerSideKey",
    "reputationHandle",
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
    "startingResources",
    "enemyPresence",
    "objectiveSizeThreshold",
    "virtualizationDistance",
    "virtualizationUnitCap",
    "startingTerritoryWestRatio",
    "startPosition"
];
private _missingFields = _requiredFields select { !(_x in FLO_MissionConfig) };
if (_missingFields isNotEqualTo []) exitWith {
    FLO_InitError = format ["Mission config missing required fields: %1", _missingFields];
    publicVariable "FLO_InitError";
    ["INIT", 1, FLO_InitError] call FLO_fnc_log;
    false
};

private _configError = "";
private _playerSideKey = FLO_MissionConfig get "playerSideKey";
try {
    if (([FLO_MissionConfig get "bluforHandle"] call FLO_fnc_factionHandleSide) != 1) then {
        throw "BLUFOR faction handle is not config side 1";
    };
    if (([FLO_MissionConfig get "opforHandle"] call FLO_fnc_factionHandleSide) != 0) then {
        throw "OPFOR faction handle is not config side 0";
    };
    if (([FLO_MissionConfig get "civilianHandle"] call FLO_fnc_factionHandleSide) != 3) then {
        throw "Civilian faction handle is not config side 3";
    };
    if !(_playerSideKey in ["WEST", "EAST"]) then {
        throw format ["Unsupported player side key %1", _playerSideKey];
    };
} catch {
    _configError = _exception;
};
if (_configError != "") exitWith {
    FLO_InitError = format ["Mission faction configuration rejected: %1", _configError];
    publicVariable "FLO_InitError";
    ["INIT", 1, FLO_InitError] call FLO_fnc_log;
    false
};

FLO_BluforHandle = FLO_MissionConfig get "bluforHandle";
FLO_OpforHandle = FLO_MissionConfig get "opforHandle";
FLO_CivilianHandle = FLO_MissionConfig get "civilianHandle";
FLO_ActivePlayerSide = [_playerSideKey] call FLO_fnc_campaignSideFromKey;
publicVariable "FLO_ActivePlayerSide";

FLO_ReputationHandle = FLO_MissionConfig get "reputationHandle";
FLO_WestDifficultyHandle = FLO_MissionConfig get "westDifficultyHandle";
FLO_EastDifficultyHandle = FLO_MissionConfig get "eastDifficultyHandle";
FLO_WestGTN_AttackCoverageHandle = FLO_MissionConfig get "westGTNAttackCoverageHandle";
FLO_EastGTN_AttackCoverageHandle = FLO_MissionConfig get "eastGTNAttackCoverageHandle";
FLO_WestGTN_DefenseCoverageHandle = FLO_MissionConfig get "westGTNDefenseCoverageHandle";
FLO_EastGTN_DefenseCoverageHandle = FLO_MissionConfig get "eastGTNDefenseCoverageHandle";
FLO_WestGTN_TempoHandle = FLO_MissionConfig get "westGTNTempoHandle";
FLO_EastGTN_TempoHandle = FLO_MissionConfig get "eastGTNTempoHandle";
FLO_WestGTN_ForceGrowthHandle = FLO_MissionConfig get "westGTNForceGrowthHandle";
FLO_EastGTN_ForceGrowthHandle = FLO_MissionConfig get "eastGTNForceGrowthHandle";
FLO_WestGTN_GarrisonHandle = FLO_MissionConfig get "westGTNGarrisonHandle";
FLO_EastGTN_GarrisonHandle = FLO_MissionConfig get "eastGTNGarrisonHandle";

FLO_WestFactionTuningHandle = createHashMap;
if ("westFactionTuningHandle" in FLO_MissionConfig) then {
    FLO_WestFactionTuningHandle = FLO_MissionConfig get "westFactionTuningHandle";
};
FLO_EastFactionTuningHandle = createHashMap;
if ("eastFactionTuningHandle" in FLO_MissionConfig) then {
    FLO_EastFactionTuningHandle = FLO_MissionConfig get "eastFactionTuningHandle";
};

FLO_DifficultyHandle = FLO_EastDifficultyHandle;
FLO_GTN_AttackCoverageHandle = FLO_EastGTN_AttackCoverageHandle;
FLO_GTN_DefenseCoverageHandle = FLO_EastGTN_DefenseCoverageHandle;
FLO_GTN_TempoHandle = FLO_EastGTN_TempoHandle;
FLO_GTN_ForceGrowthHandle = FLO_EastGTN_ForceGrowthHandle;
FLO_GTN_GarrisonHandle = FLO_EastGTN_GarrisonHandle;

EnemyPrec = FLO_MissionConfig get "enemyPresence";
FLO_ObjectiveSizeThreshold = FLO_MissionConfig get "objectiveSizeThreshold";
FLO_VirtualizationDistance = FLO_MissionConfig get "virtualizationDistance";
FLO_VirtualizationUnitCap = FLO_MissionConfig get "virtualizationUnitCap";
FLO_StartingTerritoryWestRatio = FLO_MissionConfig get "startingTerritoryWestRatio";

StartingLocationDone = true;
publicVariable "StartingLocationDone";

["INIT", 3, format [
    "Phase 1 committed native factions: BLUFOR=%1 OPFOR=%2 CIVILIAN=%3 playerSide=%4",
    FLO_BluforHandle get "name",
    FLO_OpforHandle get "name",
    FLO_CivilianHandle get "name",
    _playerSideKey
]] call FLO_fnc_log;

true
