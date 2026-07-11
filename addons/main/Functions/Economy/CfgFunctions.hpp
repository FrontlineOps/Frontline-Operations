class Economy {
    file = "\z\flo\addons\main\Functions\Economy";

    class addMoney {};
    class sideResources {};
};

class EconomySideResources {
    file = "\z\flo\addons\main\Functions\Economy\SideResources";

    class sideResourcesAddResources {};
    class sideResourcesCalculateObjectiveIncome {};
    class sideResourcesCalculateStartingResources {};
    class sideResourcesCanAfford {};
    class sideResourcesCommitReservation {};
    class sideResourcesCreate {};
    class sideResourcesGetAvailable {};
    class sideResourcesGetCommitted {};
    class sideResourcesGetReservationRemaining {};
    class sideResourcesGetSnapshot {};
    class sideResourcesGetUiSnapshot {};
    class sideResourcesPublishState {};
    class sideResourcesRecordTransaction {};
    class sideResourcesReleaseReservation {};
    class sideResourcesReserve {};
    class sideResourcesSerialize {};
    class sideResourcesSpendResources {};
    class sideResourcesStartMainLoop {};
    class sideResourcesTick {};
};

class EconomyCommanderSpending {
    file = "\z\flo\addons\main\Functions\Economy\CommanderSpending";

    class commanderSpendingEvaluate {};
    class commanderSpendingGetState {};
};

class EconomyObjectiveDevelopment {
    file = "\z\flo\addons\main\Functions\Economy\ObjectiveDevelopment";

    class objectiveDevelopmentAssignShipment {};
    class objectiveDevelopmentBuildSnapshot {};
    class objectiveDevelopmentBuildUiSnapshot {};
    class objectiveDevelopmentCompleteProject {};
    class objectiveDevelopmentGetActiveObjectiveIds {};
    class objectiveDevelopmentGetTier {};
    class objectiveDevelopmentHandleCapture {};
    class objectiveDevelopmentIncomeMultiplier {};
    class objectiveDevelopmentInitializeObjective {};
    class objectiveDevelopmentNotifySide {};
    class objectiveDevelopmentPreInit { preInit = 1; };
    class objectiveDevelopmentProcessDeliveries {};
    class objectiveDevelopmentProcessObjectiveDeliveries {};
    class objectiveDevelopmentProcessProject {};
    class objectiveDevelopmentSelectInvestment {};
    class objectiveDevelopmentShipmentTargetsActiveProject {};
    class objectiveDevelopmentStart {};
    class objectiveDevelopmentStartProject {};
    class objectiveDevelopmentTick {};
    class objectiveDevelopmentValidateProject {};
};
