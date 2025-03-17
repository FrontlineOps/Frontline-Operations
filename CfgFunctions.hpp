class FLO {
    class Functions {
        file = "Functions";

        class MissionSave       {};
        class MissionFrontline  {};
        class MissionStartup    {};
        class CDVS              {};
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
        class calculateQRFResponse              {};
        class requestQRF                        {};
        class requestOffensiveOps               {};
        class heliInsert                        {};
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

    class Logistics {
        file = "Functions\Logistics";

        class opforResources        {};
        class intelSystem           {};
        class logisticsNetwork      {};
    };

    class TaskForce {
        file = "Functions\TaskForce";

        class TaskForceSystem      {};
        class TaskForceDefenseLine {};
    };

    class Arsenal {
        file = "Functions\Arsenal";

        class restrictedArsenal     {};
    };
    
    class Objective {
        file = "Functions\Objective";
        
        class garrisonManager         {};
        class vehicleGarrison         {};
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
        class getRandomMagazine   {};
    };
    
    class Misc {
        file = "Functions\Misc";
        
        class ragequitBlocker     {};
        class disableSystemChat   {};
    };
};
