class FLO {
    class Functions {
        file = "Functions";

        class MissionSave       {};
        class MissionStartup    {};
        class MissionLoad       {preInit = 1;};
        class initializeFOB     {};
        class initializeOP      {};
    };

    class AI {
        file = "Functions\AI";

        class artilleryAssetManager             {};
        class airAssetManager                   {};
        class requestVirtualArtillery           {};
        class precisionStrike                   {};
        class airTaskOrder                      {};
        class aiCommander                       {};
        class aiCommanderUnitCapabilityAnalyzer {};
    };
    
    class Interactions {
        file = "Functions\AI\Interactions";

        class civilianRelations {};
        class civilianInvestigate {};
    };

    class Virtualization {
        file = "Functions\Virtualization";
        
        class initVirtualization              {};
        class createVirtualGroupMarker        {};
        class createVirtualWaypointMarkers    {};
        class virtualGroupsUpdateLoop         {};
        class activateVirtualGroup            {};
        class deactivateVirtualGroup          {};
        class createVirtualGroup              {};
        class updateVirtualGroupWaypoints     {};
        class initializeObjectiveGroups       {};
        class toggleVirtualizationDebug       {};
        class distributeVirtualGroups         {};
        class activateSavedVirtualGroup       {};
        class createVirtualCivilianPopulation {};
    };

    class VirtualizationUtilities {
        file = "Functions\Virtualization\Utilities";
        
        class filterNonCivGroups {};
        class getGroupTypeCount  {};
        class getRoadParkingPos  {};
        class getSafeUnvirtualizePos {};
    };

    class Objective {
        file = "Functions\Objective";
        
        class indexObjectives           {};
        class indexVirtualObjectives    {};
        class buildObjectiveGraph       {};
        class flipObjective             {};
        class monitorObjectiveDominance {};
        class startObjectiveGraph       {};
    };

    class ObjectiveUtilities {
        file = "Functions\Objective\Utilities";
        
        class getRandomObjectivePos {};
        class getNearestObjective   {};
        class getObjectivePath      {};
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
    };

    class SideMissions {
        file = "Functions\SideMissions";

        class registerSideMission       {};
        class startSideMission          {};
        class registerDefaultMissions   {};
        class sideMissionPilot          {};
        class sideMissionSquad          {};
        class sideMissionConvoy         {};
        class sideMissionCustomConvoy   {};
        class sideMissionPatrol         {};
        class sideMissionSabotage       {};
        class sideMissionPOW            {};
        class sideMissionIntel          {};
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

    class Pathfinding {
        file = "Functions\Pathfinding";

        class initPFScheduler   {preInit = 1;};
        class initSearch        {preInit = 1;};
        class initRoadGraph     {preInit = 1;};
        class findRoadPath      {};
        class findRoadPathSync  {};
    };
};
