class PathfindingCore {
    file = "\z\flo\addons\main\Functions\Pathfinding\Core";

    class initPFState { preInit = 1; };
    class initPFScheduler { preInit = 1; };
};

class PathfindingRouting {
    file = "\z\flo\addons\main\Functions\Pathfinding\Routing";

    class buildWaterAwarePath {};
    class findWaterDetour {};
    class findRoadPath {};
    class pathSegmentWaterProfile {};
};

class PathfindingDebug {
    file = "\z\flo\addons\main\Functions\Pathfinding\Debug";

    class pfProbe {};
    class pathfindingProbe {};
    class pfSourceProbe {};
};
