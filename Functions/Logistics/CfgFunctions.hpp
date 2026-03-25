class Logistics {
    file = "Functions\Logistics";

    class sideResources {};
    class logisticsNetwork {};
    class vehicleMarket {};
};

class LogisticsSideResources {
    file = "Functions\Logistics\SideResources";

    class sideResourcesAddResources {};
    class sideResourcesCalculateCost {};
    class sideResourcesCalculateObjectiveIncome {};
    class sideResourcesCalculateStartingResources {};
    class sideResourcesCanAfford {};
    class sideResourcesCreate {};
    class sideResourcesPublishState {};
    class sideResourcesSerialize {};
    class sideResourcesSpendResources {};
    class sideResourcesStartMainLoop {};
    class sideResourcesTick {};
};

class LogisticsNetwork {
    file = "Functions\Logistics\Network";

    class logisticsNetworkApplyObjectiveCaptureGrowth {};
    class logisticsNetworkBuildInboundObjectiveCounts {};
    class logisticsNetworkBuildRecentDispatchCounts {};
    class logisticsNetworkCanDispatchToObjective {};
    class logisticsNetworkCheckAndReplace {};
    class logisticsNetworkCreate {};
    class logisticsNetworkCreateReplacement {};
    class logisticsNetworkFindRearObjectives {};
    class logisticsNetworkFindReinforcementTargets {};
    class logisticsNetworkFindSpawnPosition {};
    class logisticsNetworkGetComposition {};
    class logisticsNetworkGetRearAATargets {};
    class logisticsNetworkObjectiveHasStaticAA {};
    class logisticsNetworkPickBestTarget {};
    class logisticsNetworkPickDeliveryObjective {};
    class logisticsNetworkPickSpawnSourceObjective {};
    class logisticsNetworkRecordReplacement {};
    class logisticsNetworkRecordTargetDispatch {};
    class logisticsNetworkRefreshManagedSide {};
    class logisticsNetworkSetManagedSide {};
    class logisticsNetworkStartMainLoop {};
};
