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

        class gtnWorldState         {};
        class gtnGoalLibrary        {};
        class gtnPlanner            {};
        class gtnExecutor           {};
        class gtnMonitor            {};
        class gtnCommander          {};
        class gtnCapabilityAnalyzer {};
    };

    class GTNResourceManager {
        file = "Functions\AI\GTN\ResourceManager";

        class gtnResourceManager    {};
        class gtnConfig             {};
    };

    class GTNAssets {
        file = "Functions\AI\GTN\Assets";

        class gtnAirAssetManager        {};
        class gtnAirTaskOrder           {};
        class gtnArtilleryManager       {};
        class gtnArtilleryFireMission   {};
    };
    
    class Interactions {
        file = "Functions\AI\Interactions";

        class civilianRelations {};
        class civilianInvestigate {};
        class civilianRequestMission {};
        class civilianMissionManager {};
        class civilianAddDetainActions {};
    };

    class InteractionMissions {
        file = "Functions\AI\Interactions\Missions";

        class civMission1 {};
        class civMission2 {};
        class civMission3 {};
        class civMission4 {};
    };

    class AITasks {
        file = "Functions\AI\Tasks";

        class taskPatrol {};
    };

    class Virtualization {
        file = "Functions\Virtualization";

        class initVirtualization              {};
        class activateVirtualGroup            {};
        class deactivateVirtualGroup          {};
        class createVirtualGroup              {};
        class updateVirtualGroupWaypoints     {};
        class initializeObjectiveGroups       {};
        class distributeVirtualGroups         {};
        class activateSavedVirtualGroup       {};
        class createVirtualCivilianPopulation {};
        class virtualTransport                {};
    };

    // Virtualization Core - PFH-based update system
    class VirtualizationCore {
        file = "Functions\Virtualization\Core";

        class virtualizationUpdatePFH       {};
        class virtualizationProcessGroup    {};
        class virtualizationAdvanceWaypoint {};
        class virtualizationSpatialIndex    {};
        class virtualizationEvents          {};
    };

    // Virtualization Debug - Async debug visualization
    class VirtualizationDebug {
        file = "Functions\Virtualization\Debug";

        class virtualizationDebugManager      {};
        class virtualizationDebugUpdateMarker {};
        class testVirtualizationSystem        {};
    };

    class VirtualizationUtilities {
        file = "Functions\Virtualization\Utilities";

        class filterNonCivGroups      {};
        class getGroupTypeCount       {};
        class getRoadParkingPos       {};
        class getSafeLandPos          {};
        class getSafeUnvirtualizePos  {};
        class validateGroupPosition   {};
    };

    class Objective {
        file = "Functions\Objective";

        class objectiveConfig           {};
        class indexObjectives           {};
        class indexVirtualObjectives    {};
        class buildObjectiveGraph       {};
        class flipObjective             {};
        class monitorObjectiveDominance {};
        class startObjectiveGraph       {};
    };

    class ObjectiveUtilities {
        file = "Functions\Objective\Utilities";

        class getRandomObjectivePos   {};
        class getNearestObjective     {};
        class getObjectivePath        {};
        class getObjectiveNearPlayer  {};
        class getObjectivePosition    {};
        class isPositionInObjective   {};
        class createObjectiveMarker   {};
    };

    class Logistics {
        file = "Functions\Logistics";

        class opforResources        {};
        class intelSystem           {};
        class logisticsNetwork      {};
    };

    class Intelligence {
        file = "Functions\Logistics\Intelligence";

        class militaryIntel {};
        class civilianIntel {};
        class revealRandomEnemyGroup {};
        class backgroundEvents {};
    };

    class Arsenal {
        file = "Functions\Arsenal";

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

    class Utilities {
        file = "Functions\Utilities";

        class log                       {};
        class addReward                 {};
        class getRandomMagazine         {};
        class heartbeat                 {};
        class showDynamicText           {};
        class addIntelServer            {};
        class sendRewardNotification    {};
        class sendNotification          {};
        class displayNotification       {};
        class adjustAggression          {};
        class adjustReputation          {};
        class createUUID                {};
    };

    // === SIDE MISSIONS - CORE SYSTEM ===
    class SideMissionCore {
        file = "Functions\SideMissions\Core";

        class sideMissionState          {};
        class sideMissionRegistry       {};
        class sideMissionTemplate       {};
        class sideMissionManager        {};
        class sideMissionEntityTracker  {};
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

        class addIntelItems    {};
        class findMissionHouse {};
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
        class captureUIUpdate         {};
        class initCaptureUIEvents     {};
    };

    class Pathfinding {
        file = "Functions\Pathfinding";

        class initPFScheduler   {preInit = 1;};
        class initSearch        {preInit = 1;};
        class initRoadGraph     {preInit = 1;};
        class findRoadPath      {};
        class findRoadPathSync  {};
    };
};
