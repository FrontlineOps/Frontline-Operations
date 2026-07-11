/*
 * Function: FLO_fnc_applyMissionConfigLocally
 * Author: Frontline Operations Development Group
 * Description:
 *   Hydrates legacy client-side config globals from the authoritative
 *   FLO_MissionConfig bundle so startup does not need to publicVariable
 *   every handle separately.
 *
 * Arguments: None
 *
 * Return Value:
 *   BOOL
 */

if (isNil "FLO_MissionConfig") exitWith { false };

private _config = FLO_MissionConfig;

FLO_FriendlyHandle = _config get "friendlyHandle";
FLO_EnemyHandle = _config get "enemyHandle";
FLO_CivilianHandle = _config get "civilianHandle";

if (isNil "FLO_ReputationHandle") then {
    FLO_ReputationHandle = _config get "reputationHandle";
};

if (isNil "FLO_WestDifficultyHandle") then {
    FLO_WestDifficultyHandle = _config get "westDifficultyHandle";
};

if (isNil "FLO_EastDifficultyHandle") then {
    FLO_EastDifficultyHandle = _config get "eastDifficultyHandle";
};

if (isNil "FLO_WestGTN_AttackCoverageHandle") then {
    FLO_WestGTN_AttackCoverageHandle = _config get "westGTNAttackCoverageHandle";
};

if (isNil "FLO_EastGTN_AttackCoverageHandle") then {
    FLO_EastGTN_AttackCoverageHandle = _config get "eastGTNAttackCoverageHandle";
};

if (isNil "FLO_WestGTN_DefenseCoverageHandle") then {
    FLO_WestGTN_DefenseCoverageHandle = _config get "westGTNDefenseCoverageHandle";
};

if (isNil "FLO_EastGTN_DefenseCoverageHandle") then {
    FLO_EastGTN_DefenseCoverageHandle = _config get "eastGTNDefenseCoverageHandle";
};

if (isNil "FLO_WestGTN_TempoHandle") then {
    FLO_WestGTN_TempoHandle = _config get "westGTNTempoHandle";
};

if (isNil "FLO_EastGTN_TempoHandle") then {
    FLO_EastGTN_TempoHandle = _config get "eastGTNTempoHandle";
};

if (isNil "FLO_WestGTN_ForceGrowthHandle") then {
    FLO_WestGTN_ForceGrowthHandle = _config get "westGTNForceGrowthHandle";
};

if (isNil "FLO_EastGTN_ForceGrowthHandle") then {
    FLO_EastGTN_ForceGrowthHandle = _config get "eastGTNForceGrowthHandle";
};

if (isNil "FLO_WestGTN_GarrisonHandle") then {
    FLO_WestGTN_GarrisonHandle = _config get "westGTNGarrisonHandle";
};

if (isNil "FLO_EastGTN_GarrisonHandle") then {
    FLO_EastGTN_GarrisonHandle = _config get "eastGTNGarrisonHandle";
};

FLO_DifficultyHandle = FLO_EastDifficultyHandle;
FLO_GTN_AttackCoverageHandle = FLO_EastGTN_AttackCoverageHandle;
FLO_GTN_DefenseCoverageHandle = FLO_EastGTN_DefenseCoverageHandle;
FLO_GTN_TempoHandle = FLO_EastGTN_TempoHandle;
FLO_GTN_ForceGrowthHandle = FLO_EastGTN_ForceGrowthHandle;
FLO_GTN_GarrisonHandle = FLO_EastGTN_GarrisonHandle;

EnemyPrec = _config get "enemyPresence";
FLO_ObjectiveSizeThreshold = _config get "objectiveSizeThreshold";
FLO_VirtualizationDistance = _config get "virtualizationDistance";
FLO_VirtualizationUnitCap = _config get "virtualizationUnitCap";
FLO_StartingTerritoryWestRatio = _config get "startingTerritoryWestRatio";

true
