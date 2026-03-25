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

        class detectSavedGame       {};
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

        class gtnApplyGroupEngagement {};
        class gtnBuildEnemyEngagementPicture {};
        class gtnBuildObjectiveReserveBands {};
        class gtnDistanceToSegment2D {};
        class gtnEvaluateGroupEngagementTarget {};
        class gtnExecuteTrackCycle {};
        class gtnIsEngagementRouteActive {};
        class gtnPickObjectiveGarrisonPosition {};
        class gtnRestoreStrategicGroupRoute {};
        class gtnSelectGroupEngagementTarget {};
        class gtnUpdateAttackTrackPhases {};
    };

    class GTNIntel {
        file = "Functions\AI\GTN\Intel";

        class gtnBuildCommanderIntelPicture {};
        class gtnCommanderIntelMarkerType {};
        class gtnInjectCombatEventContacts {};
        class gtnPublishCommanderIntel {};
        class gtnSyncCommanderIntelMarkers {};
    };

    class GTNAlerts {
        file = "Functions\AI\GTN\Alerts";

        class gtnCanSideObserveArea {};
        class gtnCanSideDetectAirThreat {};
        class gtnPublishAlert {};
        class gtnSyncAlertMarkers {};
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
        class gtnCollectArtilleryVehicles {};
        class gtnBuildArtilleryFirePlan {};
        class gtnArtilleryGetAvailableGroups {};
        class gtnArtilleryEvaluateObservedTarget {};
        class gtnArtilleryManager       {};
        class gtnArtilleryFireMission   {};
        class gtnArtilleryProcessObservedFireRequests {};
        class gtnArtillerySyncCachedGroup {};
        class gtnArtillerySyncObservedSpotter {};
        class gtnRadarDataLink          {};
    };
    
    // === CIVILIAN SYSTEM ===
    class CivilianCore {
        file = "Functions\Civilian\Core";

        class civilianManager {};
        class civilianConfig {};
    };

    class CivilianSpawning {
        file = "Functions\Civilian\Spawning";

        class spawnCivilians {};
        class activateCivilian {};
    };

    class CivilianBehavior {
        file = "Functions\Civilian\Behavior";

        class civilianActions {};
        class civilianInvestigateAction {};
        class civilianDetainActions {};
        class civilianProtest {};
    };

    class CivilianMissions {
        file = "Functions\Civilian\Missions";

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

        class getRandomObjectivePos   {};
        class getNearestObjective     {};
        class getObjectiveNearPlayer  {};
        class getObjectivePosition    {};
        class isPositionInObjective   {};
        class createObjectiveMarker   {};
        class refreshRespawnMarkersByTerritory {};
    };

    #include "Functions\Logistics\CfgFunctions.hpp"

    class Arsenal {
        file = "Functions\Arsenal";

        class harvestFactionGear        {};
        class isHeavyWeapon             {};
        class restrictedArsenal         {};
        class addCratePurchaseActions   {};
        class cancelCrate               {};
        class checkCratePurchase        {};
        class finalizeCrate             {};
        class getFunds                  {};
        class placeCrate                {};
        class purchaseCrate             {};
        class updateFunds               {};
    };

    class UtilitiesDebug {
        file = "Functions\Utilities\Debug";
        class log                       {};
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
    };

    class UtilitiesVehicle {
        file = "Functions\Utilities\Vehicle";
        class placeVehicleWithCrew      {};
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
        class factionDialogOnLoad     {};
        class factionDialogOnUnload   {};
        class factionDialogPopulate   {};
        class factionDialogStart      {};
        class captureUI               {};
        class initCaptureUIEvents     {};
    };

    #include "Functions\Pathfinding\CfgFunctions.hpp"
};
