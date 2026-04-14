class PathfindingCore {
    file = "Functions\Pathfinding\Core";

    class initPFState { preInit = 1; };
    class initPFScheduler { preInit = 1; };
};

class PathfindingRouting {
    file = "Functions\Pathfinding\Routing";

    class buildWaterAwarePath {};
    class findWaterDetour {};
    class findRoadPath {};
    class pathSegmentWaterProfile {};
};

class PathfindingDebug {
    file = "Functions\Pathfinding\Debug";

    class pfProbe {};
    class pathfindingProbe {};
    class pfSourceProbe {};
};
