class FLO {
    class Functions {
        file = "\z\flo\addons\main\Functions";

        class MissionSave       {};
        class MissionStartup    {};
        class MissionLoad       {preInit = 1;};
        class initializeFOB     {};
        class initializeOP      {};
    };

    // === INITIALIZATION PHASE SYSTEM ===
    class Init {
        file = "\z\flo\addons\main\Functions\Init";

        class applyMissionConfigLocally {};
        class registerSettings      {};
        class detectSavedGame       {};
        class initFactionSplitMixedInfantryPool {};
        class initMissionConfigEvents {};
        class initPhaseManager      {};
        class initPhase1_MissionConfig {};
        class initPhase2_Factions   {};
        class initPhase3_Objectives {};
        class initPhase4_Virtualization {};
        class initPhase5_MissionSystems {};
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
        class gtnBuildFriendlyCommanderGroupMarkers {};
        class gtnBuildFriendlySupplyNodeMarkers {};
        class gtnBuildFriendlySupportMarkers {};
        class gtnCommanderSupplyMarkersToggle {};
        class gtnCollectIntelPickupRevealCandidates {};
        class gtnCommanderIntelMarkerType {};
        class gtnInjectCombatEventContacts {};
        class gtnPublishCommanderIntel {};
        class gtnRefreshCommanderSupplyToggleAction {};
        class gtnRevealIntelPickup {};
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

    class GTNTasks {
        file = "\z\flo\addons\main\Functions\AI\GTN\Tasks";

        class gtnPlayerTaskBridge {};
        class gtnTaskScoreObjectiveForPlayers {};
        class gtnTaskCollectDestroyTargets {};
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

    class Objective {
        file = "\z\flo\addons\main\Functions\Objective";

        class objectiveConfig           {};
        class buildObjectiveLinks       {};
        class objectiveIndexer          {};
        class dbscanCluster             {};
        class buildObjectiveGraph       {};
        class flipObjective             {};
        class seedObjectiveOwnership    {};
        class monitorObjectiveDominance {};
        class startObjectiveGraph       {};
    };

    class ObjectiveUtilities {
        file = "\z\flo\addons\main\Functions\Objective\Utilities";

        class buildObjectiveRuntimeState {};
        class getRandomObjectivePos   {};
        class getNearestObjective     {};
        class initObjectiveRuntimeStateEvents {};
        class getObjectiveNearPlayer  {};
        class getObjectivePosition    {};
        class isPositionInObjective   {};
        class createObjectiveMarker   {};
        class publishObjectiveRuntimeState {};
        class refreshRespawnMarkersByTerritory {};
        class syncObjectiveRuntimeState {};
        class updateObjectiveCaptureState {};
    };

    #include "Functions\AI\GTN\Minefields\CfgFunctions.hpp"

    #include "Functions\Logistics\CfgFunctions.hpp"

    class MoneyState {
        file = "\z\flo\addons\main\Functions\Money";

        class addMoney                  {};
        class initMoneyStateEvents      {};
        class publishMoneyState         {};
        class syncMoneyState            {};
    };

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
        class storeCheckout {};
        class storeClearCargo {};
        class storeDeployBase {};
        class storeDropGearItems {};
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
        class storeUpdateDialog {};
        class storeValidateAccess {};
        class storeWeaponAttachments {};
        class storeWebAction {};
    };

    class Base {
        file = "\z\flo\addons\main\Functions\Base";

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
        class factionClassifyVehicle {};
        class factionGetGroupConfigs {};
        class factionGetCompositionDefaults {};
        class factionGetObjectiveGroupFieldSpecs {};
        class factionGetTuningFieldSpecs {};
        class factionApplyTuningOverrides {};
        class factionBuildTuningHandle {};
        class factionPickUnitByRole {};
        class factionSanitizeCompositionForCatalog {};
    };

    class UtilitiesDebug {
        file = "\z\flo\addons\main\Functions\Utilities\Debug";
        class log                       {};
        class netDebugDump             {};
        class netDebugRecord           {};
        class netDebugSnapshot         {};
    };

    class UtilitiesSystem {
        file = "\z\flo\addons\main\Functions\Utilities\System";
        class createUUID                {};
        class heartbeat                 {};
    };

    class UtilitiesUI {
        file = "\z\flo\addons\main\Functions\Utilities\UI";
        class showDynamicText           {};
        class sendRewardNotification    {};
        class sendNotification          {};
        class displayNotification       {};
    };

    class UtilitiesGame {
        file = "\z\flo\addons\main\Functions\Utilities\Game";
        class addReward                 {};
        class getRandomMagazine         {};
        class addIntelServer            {};
        class militaryIntel             {};
        class adjustAggression          {};
        class adjustReputation          {};
        class configureObjectActionsLocal {};
    };

    class UtilitiesVehicle {
        file = "\z\flo\addons\main\Functions\Utilities\Vehicle";
        class placeVehicleWithCrew      {};
        class vehicleConfigureRequestedVehicle {};
    };

    class UtilitiesAftermath {
        file = "\z\flo\addons\main\Functions\Utilities\Aftermath";
        class aftermathCleanupManager   {};
        class aftermathCleanupRun       {};
        class aftermathIsPositionInHotObjective {};
        class aftermathRegisterEntity   {};
        class aftermathShouldCleanupEntity {};
        class aftermathShouldPreserveEvidence {};
        class vehicleCleanupBuildContext {};
        class vehicleCleanupDiscoverCandidates {};
        class vehicleCleanupManager     {};
        class vehicleCleanupProcessCandidates {};
        class vehicleCleanupRun         {};
        class vehicleShouldCleanup      {};
    };

    class Misc {
        file = "\z\flo\addons\main\Functions\Misc";

        class ragequitBlocker     {};
        class disableSystemChat   {};
    };

    class UI {
        file = "\z\flo\addons\main\Functions\UI";
        class safeConfirm             {};
        class shouldOpenFactionDialog {};
        class openFactionDialog       {};
        class factionDialogOnLoad     {};
        class factionDialogOnUnload   {};
        class factionDialogCreateObjectiveGroupControls {};
        class factionDialogFillCompositionDefaults {};
        class factionDialogNormalizeMultiSelection {};
        class factionDialogPopulate   {};
        class factionDialogShowCompositionTab {};
        class factionDialogStart      {};
        class captureUI               {};
        class initCaptureUIEvents     {};
    };

    #include "Functions\Pathfinding\CfgFunctions.hpp"
};
