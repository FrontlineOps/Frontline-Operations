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
        class gtnReleaseCompletedAttackAssignments {};
        class gtnRequestFrontlineCAP {};
        class gtnRequestFrontlineCAS {};
    };

    class GTNCoreLogic {
        file = "Functions\AI\GTN\Core\Logic";

        class gtnBuildObjectiveReserveBands {};
        class gtnExecuteTrackCycle {};
        class gtnPickObjectiveGarrisonPosition {};
        class gtnUpdateAttackTrackPhases {};
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

    // === INTELLIGENCE SYSTEM ===
    class IntelCore {
        file = "Functions\Intelligence\Core";

        class intelSystem {};
    };

    class IntelReveals {
        file = "Functions\Intelligence\Reveals";

        class revealRandomEnemyGroup    {};
        class revealArtilleryBattery    {};
        class revealCommanderObjective  {};
        class incomingAircraftAlert     {};
    };

    class IntelSources {
        file = "Functions\Intelligence\Sources";

        class militaryIntel    {};
        class civilianIntel    {};
        class backgroundEvents {};
    };

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
    };

    // === SIDE MISSIONS - CORE SYSTEM ===
    class SideMissionCore {
        file = "Functions\SideMissions\Core";

        class sideMissionState          {};
        class sideMissionRegistry       {};
        class sideMissionTemplate       {};
        class sideMissionManager        {};
        class sideMissionEntityTracker  {};
        class sideMissionHandleRescue   {};
        class sideMissionTaskCreate     {};
        class sideMissionTaskUpdate     {};
        class sideMissionTaskCleanup    {};
        class sideMissionTemplatesInit  {};
        class startSideMission          {};
    };

    // === SIDE MISSIONS - TEMPLATES ===
    class SideMissionTemplates {
        file = "Functions\SideMissions\Templates";

        class templatePilotRescue       {};
        class templateSquadRescue       {};
        class templateConvoyInterdiction {};
        class templateHVTConvoy         {};
        class templatePatrolSweep       {};
        class templatePOWRescue         {};
        class templateIntelGathering    {};
    };

    class SideMissionUtilities {
        file = "Functions\SideMissions\Utilities";

        class addIntelItems      {};
        class findMissionHouse   {};
        class convoyController   {};
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
