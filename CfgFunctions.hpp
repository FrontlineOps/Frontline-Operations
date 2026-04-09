class FLO {
    class Functions {
        file = "Functions";

        class MissionSave       {};
        class MissionStartup    {};
        class MissionLoad       {preInit = 1;};
        class initializeFOB     {};
        class initializeOP      {};
    };

    // === INITIALIZATION PHASE SYSTEM ===
    class Init {
        file = "Functions\Init";

        class applyMissionConfigLocally {};
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
    };

    // === GTN (Goal Task Network) SYSTEM ===
    class GTNCore {
        file = "Functions\AI\GTN\Core";

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
        file = "Functions\AI\GTN\Core\Actions";

        class gtnAllocateBaselineGarrisons {};
        class gtnAllocateFrontlineAttacks {};
        class gtnAllocateFrontlineDefense {};
        class gtnManageOpportunisticEngagements {};
        class gtnReleaseCompletedAttackAssignments {};
        class gtnRequestFrontlineCAP {};
        class gtnRequestFrontlineCAS {};
    };

    class GTNCoreLogic {
        file = "Functions\AI\GTN\Core\Logic";

        class gtnAllocateAttackTrackPools {};
        class gtnBuildObjectiveDemandSignature {};
        class gtnBuildObjectiveAssignmentCache {};
        class gtnAdjustEngagementTargetAssignment {};
        class gtnApplyGroupEngagement {};
        class gtnBuildEnemyEngagementPicture {};
        class gtnBuildGroupEngagementContext {};
        class gtnGetSideClientOwners {};
        class gtnMarkCommanderStateDirty {};
        class gtnGetCachedReserveBands {};
        class gtnGetSideCommanderHandle {};
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
        class gtnPickObjectiveGarrisonPosition {};
        class gtnRestoreStrategicGroupRoute {};
        class gtnSelectGroupEngagementTarget {};
        class gtnUpdateAttackTrackPhases {};
    };

    class GTNIntel {
        file = "Functions\AI\GTN\Intel";

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
        file = "Functions\AI\GTN\Alerts";

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
        file = "Functions\AI\GTN\Tasks";

        class gtnPlayerTaskBridge {};
        class gtnTaskScoreObjectiveForPlayers {};
        class gtnTaskCollectDestroyTargets {};
    };

    class GTNPlayerSupport {
        file = "Functions\AI\GTN\PlayerSupport";

        class gtnBuildSupportCooldownKey {};
        class gtnOpenPlayerSupportRequestMap {};
        class gtnProcessPlayerSupportRequests {};
        class gtnRefreshPlayerSupportActions {};
        class gtnResolveSupportObjective {};
        class gtnSubmitPlayerSupportRequest {};
        class gtnValidatePlayerSupportRequest {};
    };

    class GTNResourceManager {
        file = "Functions\AI\GTN\ResourceManager";

        class gtnResourceManager    {};
        class gtnConfig             {};
    };

    class GTNDebug {
        file = "Functions\AI\GTN\Debug";

        class gtnCommanderVisualDebug {};
    };

    class GTNAssets {
        file = "Functions\AI\GTN\Assets";

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
        file = "Functions\Civilian\Core";

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
        file = "Functions\Civilian\Spawning";

        class spawnCivilians {};
        class activateCivilian {};
    };

    class CivilianBehavior {
        file = "Functions\Civilian\Behavior";

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
        file = "Functions\Civilian\Missions";

        class civilianBuildMissionOffer {};
        class civilianMissionResolveAction {};
        class civilianMissionManager {};
        class civilianRequestMission {};
    };

    class CivilianMissionTemplates {
        file = "Functions\Civilian\Missions\Templates";

        class civMission1 {};
        class civMission2 {};
        class civMission3 {};
        class civMission4 {};
    };

    class AITasks {
        file = "Functions\AI\Tasks";

        class taskPatrol {};
    };

    #include "Functions\Virtualization\CfgFunctions.hpp"

    class Objective {
        file = "Functions\Objective";

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
        file = "Functions\Objective\Utilities";

        class buildObjectiveRuntimeState {};
        class getRandomObjectivePos   {};
        class getNearestObjective     {};
        class initObjectiveRuntimeStateEvents {};
        class getObjectiveNearPlayer  {};
        class getObjectivePosition    {};
        class isPositionInObjective   {};
        class createObjectiveMarker   {};
        class refreshRespawnMarkersByTerritory {};
        class syncObjectiveRuntimeState {};
    };

    #include "Functions\Logistics\CfgFunctions.hpp"

    class Arsenal {
        file = "Functions\Arsenal";

        class harvestFactionGear        {};
        class initMoneyStateEvents      {};
        class isHeavyWeapon             {};
        class restrictedArsenal         {};
        class publishMoneyState         {};
        class addCratePurchaseActions   {};
        class cancelCrate               {};
        class checkCratePurchase        {};
        class finalizeCrate             {};
        class getFunds                  {};
        class placeCrate                {};
        class syncMoneyState            {};
        class purchaseCrate             {};
        class updateFunds               {};
    };

    class UtilitiesDebug {
        file = "Functions\Utilities\Debug";
        class log                       {};
        class netDebugDump             {};
        class netDebugRecord           {};
        class netDebugSnapshot         {};
    };

    class UtilitiesSystem {
        file = "Functions\Utilities\System";
        class createUUID                {};
        class heartbeat                 {};
    };

    class UtilitiesUI {
        file = "Functions\Utilities\UI";
        class showDynamicText           {};
        class sendRewardNotification    {};
        class sendNotification          {};
        class displayNotification       {};
    };

    class UtilitiesGame {
        file = "Functions\Utilities\Game";
        class addReward                 {};
        class getRandomMagazine         {};
        class addIntelServer            {};
        class adjustAggression          {};
        class adjustReputation          {};
        class configureObjectActionsLocal {};
    };

    class UtilitiesVehicle {
        file = "Functions\Utilities\Vehicle";
        class placeVehicleWithCrew      {};
        class vehicleConfigureRequestedVehicle {};
        class vehicleCleanupManager     {};
        class vehicleCleanupRun         {};
        class vehicleShouldCleanup      {};
    };

    class Misc {
        file = "Functions\Misc";

        class ragequitBlocker     {};
        class disableSystemChat   {};
    };

    class UI {
        file = "Functions\UI";
        class safeConfirm             {};
        class shouldOpenFactionDialog {};
        class factionDialogOnLoad     {};
        class factionDialogOnUnload   {};
        class factionDialogPopulate   {};
        class factionDialogStart      {};
        class captureUI               {};
        class initCaptureUIEvents     {};
    };

    #include "Functions\Pathfinding\CfgFunctions.hpp"
};
