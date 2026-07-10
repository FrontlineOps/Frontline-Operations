class FLO {
    class Functions {
        file = "\z\flo\addons\main\Functions";

        class MissionSave       {};
        class MissionStartup    {};
        class MissionLoad       {preInit = 1;};
        class initializeFOB     {};
        class initializeOP      {};
    };

    class Save {
        file = "\z\flo\addons\main\Functions\Save";

        class saveGetAllCargo {};
        class saveGetCompressedDamage {};
    };

    // === INITIALIZATION PHASE SYSTEM ===
    class Init {
        file = "\z\flo\addons\main\Functions\Init";

        class applyMissionConfigLocally {};
        class registerSettings      {};
        class detectSavedGame       {};
        class initFactionSplitMixedInfantryPool {};
        class initLoadFactionDefinition {};
        class initLoadFactionSelection {};
        class initMissionConfigEvents {};
        class initPhaseManager      {};
        class initPhase1_MissionConfig {};
        class initPhase2_Factions   {};
        class initPhase3_Objectives {};
        class initPhase4_Virtualization {};
        class initPhase5_MissionSystems {};
        class initRestoreTrackedCrew {};
        class initRunPhase {};
        class initSideResourcesUninitialized {};
        class initStartRadarDataLink {};
        class initClientFinalize    {};
        class addonPostInit         {postInit = 1;};
    };

    // === GTN (Goal Task Network) SYSTEM ===
    class GTNCore {
        file = "\z\flo\addons\main\Functions\AI\GTN\Core";

        class gtnSideContext        {};
        class gtnWorldState         {};
        class gtnGoalLibrary        {};
        class gtnPlanner            {};
        class gtnExecutor           {};
        class gtnMonitor            {};
        class gtnCommander          {};
        class gtnCollectTurretWeapons {};
        class gtnCapabilityAnalyzer {};
    };

    class GTNCoreActions {
        file = "\z\flo\addons\main\Functions\AI\GTN\Core\Actions";

        class gtnAllocateBaselineGarrisons {};
        class gtnAllocateFrontlineAttacks {};
        class gtnAllocateFrontlineDefense {};
        class gtnManageOpportunisticEngagements {};
        class gtnReleaseCompletedAttackAssignments {};
        class gtnRequestFrontlineCAP {};
        class gtnRequestFrontlineCAS {};
    };

    class GTNCoreLogic {
        file = "\z\flo\addons\main\Functions\AI\GTN\Core\Logic";

        class gtnAllocateAttackTrackPools {};
        class gtnBuildObjectiveDemandSignature {};
        class gtnBuildFriendlyObjectiveOwnershipSignature {};
        class gtnBuildObjectiveAssignmentCache {};
        class gtnAdjustEngagementTargetAssignment {};
        class gtnApplyGroupEngagement {};
        class gtnBuildEnemyEngagementPicture {};
        class gtnBuildGroupEngagementContext {};
        class gtnGetSideClientOwners {};
        class gtnMarkCommanderStateDirty {};
        class gtnGetCachedReserveBands {};
        class gtnGetSideCommanderHandle {};
        class gtnGetTempoScaledAssignmentLimit {};
        class gtnBuildObservedRealEnemyTarget {};
        class gtnBuildObjectiveReserveBands {};
        class gtnDistanceToSegment2D {};
        class gtnEstimateEngagementTargetLoad {};
        class gtnEvaluateGroupEngagementTarget {};
        class gtnExecuteTrackCycle {};
        class gtnGetAttackPressureProfile {};
        class gtnGroupIsStrategicallyAssignable {};
        class gtnGetEngagementTargetAssignmentCap {};
        class gtnIsEngagementRouteActive {};
        class gtnLogStrategicOrderPerf {};
        class gtnPickObjectiveGarrisonPosition {};
        class gtnRestoreStrategicGroupRoute {};
        class gtnSelectGroupEngagementTarget {};
        class gtnUpdateAttackTrackPhases {};
    };

    class GTNIntel {
        file = "\z\flo\addons\main\Functions\AI\GTN\Intel";

        class gtnApproximateCommanderMarkerPosition {};
        class gtnBuildCommanderIntelPicture {};
        class gtnBuildCommanderIntelPublishSignature {};
        class gtnBuildEnemyLogisticsIntelSnapshot {};
        class gtnBuildFriendlyCommanderGroupMarkers {};
        class gtnBuildFriendlySupportMarkers {};
        class gtnNormalizeIntelSignatureValue {};
        class gtnCollectIntelPickupRevealCandidates {};
        class gtnCommanderIntelMarkerType {};
        class gtnInjectCombatEventContacts {};
        class gtnPublishCommanderIntel {};
        class gtnRevealIntelPickup {};
        class gtnSerializeIntelSignatureRecords {};
        class gtnSyncCommanderIntelMarkers {};
    };

    class GTNAlerts {
        file = "\z\flo\addons\main\Functions\AI\GTN\Alerts";

        class gtnCanSideObserveArea {};
        class gtnCanSideDetectAirThreat {};
        class gtnFlushAlertQueue {};
        class gtnPublishAlert {};
        class gtnSyncAlertMarkers {};
        class gtnSyncAlertBatch {};
        class gtnAlertIncomingArtillery {};
        class gtnAlertIncomingAircraft {};
        class gtnAlertCivilianReport {};
    };

    #include "Functions\AI\GTN\Combat\CfgFunctions.hpp"
    #include "Functions\AI\GTN\Operations\CfgFunctions.hpp"
    #include "Functions\UI\CfgFunctions.hpp"

    class GTNTasks {
        file = "\z\flo\addons\main\Functions\AI\GTN\Tasks";

        class gtnClearPrimaryTaskState {};
        class gtnDeleteTaskIfPresent {};
        class gtnPlayerTaskBridge {};
        class gtnPlayerTaskDescription {};
        class gtnPlayerTaskTitle {};
        class gtnPublishPlayerTask {};
        class gtnMarkTaskFailed {};
        class gtnMarkTaskSucceeded {};
        class gtnTaskEnemySide {};
        class gtnTaskMissing {};
        class gtnTaskNormalizeSide {};
        class gtnTaskSideKey {};
        class gtnTaskTypeFromKind {};
    };

    class GTNPlayerSupport {
        file = "\z\flo\addons\main\Functions\AI\GTN\PlayerSupport";

        class gtnBuildSupportCooldownKey {};
        class gtnOpenPlayerSupportRequestMap {};
        class gtnProcessPlayerSupportRequests {};
        class gtnRegisterPlayerSupportEvents {};
        class gtnRefreshPlayerSupportActions {};
        class gtnResolveSupportObjective {};
        class gtnSubmitPlayerSupportRequest {};
        class gtnSubmitPlayerSupportRequestServer {};
        class gtnValidatePlayerSupportRequest {};
    };

    class GTNResourceManager {
        file = "\z\flo\addons\main\Functions\AI\GTN\ResourceManager";

        class gtnResourceManager    {};
        class gtnConfig             {};
    };

    class GTNDebug {
        file = "\z\flo\addons\main\Functions\AI\GTN\Debug";

        class gtnCommanderDebugClearAll {};
        class gtnCommanderDebugSideColor {};
        class gtnCommanderDebugSideLabel {};
        class gtnCommanderDebugUpsertMarker {};
        class gtnCommanderVisualDebug {};
    };

    class GTNAssets {
        file = "\z\flo\addons\main\Functions\AI\GTN\Assets";

        class gtnAirAssetManager        {};
        class gtnAirTaskOrder           {};
        class gtnBroadcastCommanderRadioMessage {};
        class gtnBroadcastArtilleryRadio {};
        class gtnBuildArtilleryMissionRecord {};
        class gtnCollectArtilleryVehicles {};
        class gtnBuildArtilleryFirePlan {};
        class gtnCommanderRadioMessage {};
        class gtnProcessArtilleryRadioQueue {};
        class gtnQueueArtilleryRadioMission {};
        class gtnArtilleryGetAvailableGroups {};
        class gtnArtilleryEvaluateObservedTarget {};
        class gtnArtilleryManager       {};
        class gtnArtilleryFireMission   {};
        class gtnArtilleryProcessObservedFireRequests {};
        class gtnProcessCounterBatteryRequests {};
        class gtnRecordCounterBatteryExposure {};
        class gtnSupportAssetCanProvideAbstractSupport {};
        class gtnArtillerySyncCachedGroup {};
        class gtnArtillerySyncObservedSpotter {};
        class gtnRadarDataLink          {};
    };
    
    // === CIVILIAN SYSTEM ===
    class CivilianCore {
        file = "\z\flo\addons\main\Functions\Civilian\Core";

        class civilianManager {};
        class bribeMilitia {};
        class civilianConfig {};
        class civilianResolveObjective {};
        class civilianBuildRoleProfile {};
        class civilianBuildAmbientRoute {};
        class civilianBuildObjectivePoiCache {};
        class civilianResolveObjectiveContext {};
        class civilianMergeObjectiveMemory {};
        class civilianIngestCombatEvents {};
        class civilianPropagateObjectiveGossip {};
        class civilianSelectObjectiveMemory {};
        class civilianBuildIntelPackageFromMemory {};
        class civilianBuildIntelPackage {};
        class civilianBuildIntelSubtitle {};
        class civilianPlanRoutine {};
        class civilianApplyRoutinePlan {};
    };

    class CivilianSpawning {
        file = "\z\flo\addons\main\Functions\Civilian\Spawning";

        class spawnCivilians {};
        class activateCivilian {};
    };

    class CivilianBehavior {
        file = "\z\flo\addons\main\Functions\Civilian\Behavior";

        class civilianActions {};
        class civilianConfigureActionsLocal {};
        class civilianInvestigateAction {};
        class civilianRequestIntel {};
        class civilianSelectObjectiveProtesters {};
        class civilianRunProtestBehavior {};
        class civilianDetaineeCommand {};
        class civilianDetainActions {};
        class civilianProtest {};
    };

    class CivilianMissions {
        file = "\z\flo\addons\main\Functions\Civilian\Missions";

        class civilianBuildMissionOffer {};
        class civilianMissionResolveAction {};
        class civilianMissionManager {};
        class civilianRequestMission {};
    };

    class CivilianMissionTemplates {
        file = "\z\flo\addons\main\Functions\Civilian\Missions\Templates";

        class civMission1 {};
        class civMission2 {};
        class civMission3 {};
        class civMission4 {};
    };

    class AITasks {
        file = "\z\flo\addons\main\Functions\AI\Tasks";

        class taskPatrol {};
    };

    #include "Functions\Virtualization\CfgFunctions.hpp"

    #include "Functions\Objective\CfgFunctions.hpp"

    #include "Functions\AI\GTN\Minefields\CfgFunctions.hpp"

    #include "Functions\Economy\CfgFunctions.hpp"

    #include "Functions\Logistics\CfgFunctions.hpp"

    class Store {
        file = "\z\flo\addons\main\Functions\Store";

        class storeAddInventoryItem {};
        class storeAddWebEventHandler {};
        class storeAppendCatalogItem {};
        class storeAppendContainerCargoItems {};
        class storeAppendGearMagazine {};
        class storeAppendGearWeapon {};
        class storeAppendUnitGear {};
        class storeApplyKit {};
        class storeApplyWeaponLine {};
        class storeBuildCatalog {};
        class storeBuildCatalogItem {};
        class storeBuildCategoryPayload {};
        class storeBuildHydratePayload {};
        class storeCategoryForVehicle {};
        class storeCategoryForWeapon {};
        class storeCapabilityForCategory {};
        class storeCheckout {};
        class storeClearCargo {};
        class storeDeployBase {};
        class storeDropGearItems {};
        class storeDropGearAddCount {};
        class storeHandleUiEvent {};
        class storeIsItemBackedMagazine {};
        class storeIsMineMagazine {};
        class storeLegacyVehiclePrice {};
        class storeOpenDialog {};
        class storePreInit { preInit = 1; };
        class storePriceClass {};
        class storeReceiveResponse {};
        class storeRecruitAI {};
        class storeRequestCategory {};
        class storeRequestCheckout {};
        class storeRequestHydrate {};
        class storeSavedKitsDelete {};
        class storeSavedKitsLoad {};
        class storeSavedKitsSave {};
        class storeSendResponse {};
        class storeSpawnVehicle {};
        class storeSpawnSupplyShipment {};
        class storeThroughputCost {};
        class storeUpdateDialog {};
        class storeValidateAccess {};
        class storeWeaponAttachments {};
        class storeWebAction {};
    };

    class Base {
        file = "\z\flo\addons\main\Functions\Base";

        class baseConfigureContainerActions {};
        class baseConfigureMainActions {};
        class baseCreateMarker {};
        class baseCreateTriggers {};
        class baseDeployAddWebEventHandler {};
        class baseDeployBuildSnapshot {};
        class baseDeployHandleUiEvent {};
        class baseDeployInitClient {};
        class baseDeployOpenDialog {};
        class baseDeployPostInit { postInit = 1; };
        class baseDeployPreInit { preInit = 1; };
        class baseDeployReceiveResult {};
        class baseDeployRequest {};
        class baseDeployUpdateDialog {};
        class baseDeployWebAction {};
    };

    class Factions {
        file = "\z\flo\addons\main\Functions\Factions";

        class factionApplyAutoEnemyGlobals {};
        class factionApplyAutoFriendlyGlobals {};
        class factionApplyAutoGlobals {};
        class factionBuildAutoCivilianCatalog {};
        class factionBuildAutoIndex {};
        class factionBuildMergedAutoCivilianCatalog {};
        class factionBuildMergedAutoMilitaryCatalog {};
        class factionBuildAutoMilitaryCatalog {};
        class factionBuildObjectiveGroupFieldSpecs {};
        class factionBuildTuningFieldSpecsFromIdcs {};
        class factionBuildVehiclePoolFromVariables {};
        class factionClassifyVehicle {};
        class factionCollectDirectUnitVariables {};
        class factionCompactNumericText {};
        class factionCompositionDefaultCaps {};
        class factionCompositionDefaultCounts {};
        class factionCompositionDefaultObjectiveGroups {};
        class factionCreateCompositionDefaultHandle {};
        class factionExtractVehicleClasses {};
        class factionGetCustomDefinition {};
        class factionGetGroupConfigs {};
        class factionGetCompositionDefaults {};
        class factionGetObjectiveGroupFieldSpecs {};
        class factionGetTuningFieldSpecs {};
        class factionGetVariableArray {};
        class factionBuildCompositionDefaultsHandle {};
        class factionHandleSource {};
        class factionIsUnsignedInt {};
        class factionMergePairs {};
        class factionApplyTuningOverrides {};
        class factionBuildTuningHandle {};
        class factionPickUnitByRole {};
        class factionSanitizeCompositionForCatalog {};
    };

    #include "Functions\Utilities\CfgFunctions.hpp"

    class Misc {
        file = "\z\flo\addons\main\Functions\Misc";

        class ragequitBlocker     {};
        class disableSystemChat   {};
    };

    #include "Functions\Pathfinding\CfgFunctions.hpp"
};
