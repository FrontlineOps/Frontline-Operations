class FLO {
    class Functions {
        file = "Functions";

        class ICS               {};
        class MissionSave       {};
        class MissionStartup    {};
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
        class aiCommander                       {};
        class aiCommanderUnitCapabilityAnalyzer {};
    };

    class Actions {
        file = "Functions\AI\Actions";

        class attackArea        {};
        class defendArea        {};
        class patrolArea        {};
        class reconArea         {};
        class taskAttack        {};
        class taskDefend        {};
        class taskPatrol        {};
        class addWaypoint       {};
        class reconAreaAction   {};
        class getTargetType     {};
    };

    class Virtualization {
        file = "Functions\Virtualization";
        
        class initVirtualization             {};
        class createVirtualGroupMarker       {};
        class createVirtualWaypointMarkers   {};
        class virtualGroupsUpdateLoop        {};
        class activateVirtualGroup           {};
        class deactivateVirtualGroup         {};
        class createVirtualGroup             {};
        class updateVirtualGroupWaypoints    {};
        class initializeObjectiveGroups      {};
        class toggleVirtualizationDebug      {};
        class distributeVirtualGroups        {};
        class testVirtualMovement            {};
        class testVirtualMovementAdvanced    {};
    };

    class Logistics {
        file = "Functions\Logistics";

        class opforResources        {};
        class intelSystem           {};
        class logisticsNetwork      {};
    };

    class Arsenal {
        file = "Functions\Arsenal";

        class restrictedArsenal     {};
    };
    
    class Objective {
        file = "Functions\Objective";

        class finalizeObjectiveFlip   {};
        class flipObjective           {};
        class setupCaptureSystem      {};
    };

    class Utilities {
        file = "Functions\Utilities";

        class findNearestMarker   {};
        class log                 {};
        class addReward           {};
        class notification        {};
    };
};
