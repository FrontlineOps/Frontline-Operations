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
    class logisticsNetworkBuildTargetPicture {};
    class logisticsNetworkBuildInboundObjectiveCounts {};
    class logisticsNetworkBuildBranchDispatchCounts {};
    class logisticsNetworkBuildRecentDispatchCounts {};
    class logisticsNetworkCanDispatchToObjective {};
    class logisticsNetworkCheckAndReplace {};
    class logisticsNetworkDescribeObjectiveSupplyRole {};
    class logisticsNetworkFindSupplyAdvanceObjectives {};
    class logisticsNetworkGetCachedSpawnPosition {};
    class logisticsNetworkFindSupplySourceObjective {};
    class logisticsNetworkCreate {};
    class logisticsNetworkCreateReplacement {};
    class logisticsNetworkFindRearObjectives {};
    class logisticsNetworkFindReinforcementTargets {};
    class logisticsNetworkFindSpawnPosition {};
    class logisticsNetworkGetComposition {};
    class logisticsNetworkGetObjectiveSupplyBranch {};
    class logisticsNetworkGetRearAATargets {};
    class logisticsNetworkObjectiveIsCollapsePressure {};
    class logisticsNetworkObjectiveIsFrontlinePressure {};
    class logisticsNetworkObjectiveHasStaticAA {};
    class logisticsNetworkPickAdvanceTarget {};
    class logisticsNetworkPickBestTarget {};
    class logisticsNetworkPickHQObjective {};
    class logisticsNetworkPickDeliveryObjective {};
    class logisticsNetworkPickPressureTarget {};
    class logisticsNetworkPickRearTarget {};
    class logisticsNetworkPickSpawnSourceObjective {};
    class logisticsNetworkReplenishTransportReserves {};
    class logisticsNetworkRecordDelivery {};
    class logisticsNetworkRecordReplacement {};
    class logisticsNetworkRecordTargetDispatch {};
    class logisticsNetworkRefreshManagedSide {};
    class logisticsNetworkRefreshObjectiveSideIndex {};
    class logisticsNetworkRefreshSupplyChain {};
    class logisticsNetworkSetManagedSide {};
    class logisticsNetworkStartMainLoop {};
};
