class FLO {
    class Functions {
        file = "Functions";

        class MissionSave       {};
        class MissionStartup    {};
        class ICS               {};
        class MissionLoad       {preInit = 1;};
        class initializeFOB     {};
        class initializeOP      {};
    };

    class AI {
        file = "Functions\AI";

        class artilleryPrep                     {};
        class airRecon                          {};
        class airSupport                        {};
        class fireObserver                      {};
        class heliInsert                        {};
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
        class indexObjectives                 {};
        class indexVirtualObjectives          {};
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

        class findNearestMarker         {};
        class log                       {};
        class addReward                 {};
        class getRandomMagazine         {};
        class heartbeat                 {};
        class showDynamicText           {};
        class addIntelServer            {};
        class sendRewardNotification    {};
        class sendNotification          {};
        class displayNotification       {};
        class findEdgeSpawnPos          {};
        class getGroupTypeCount         {};
        class adjustAggression          {};
        class adjustReputation          {};
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
    };
};
