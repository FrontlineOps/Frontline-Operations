class UtilitiesDebug {
    file = "\z\flo\addons\main\Functions\Utilities\Debug";

    class log {};
    class netDebugDump {};
    class netDebugRecord {};
    class netDebugSnapshot {};
};

class UtilitiesSystem {
    file = "\z\flo\addons\main\Functions\Utilities\System";

    class createUUID {};
    class heartbeat {};
    class heartbeatNotifyRestart {};
    class padHex {};
    class performanceMonitorPreInit { preInit = 1; };
    class performanceMonitorStart { postInit = 1; };
    class toHex {};
};

class UtilitiesTime {
    file = "\z\flo\addons\main\Functions\Utilities\Time";

    class dateNumberAddSeconds {};
    class dateNumberDeltaSeconds {};
    class dateNumberSecondsPerYear {};
};

class UtilitiesUI {
    file = "\z\flo\addons\main\Functions\Utilities\UI";

    class showDynamicText {};
    class sendRewardNotification {};
    class sendNotification {};
    class displayNotification {};
};

class UtilitiesGame {
    file = "\z\flo\addons\main\Functions\Utilities\Game";

    class sideKey {};
    class opposingSide {};
    class addReward {};
    class getRandomMagazine {};
    class addIntelServer {};
    class militaryIntel {};
    class adjustAggression {};
    class adjustReputation {};
    class configureObjectActionsLocal {};
    class randomizeWeather {};
};

class UtilitiesVehicle {
    file = "\z\flo\addons\main\Functions\Utilities\Vehicle";

    class placeVehicleWithCrew {};
    class vehicleConfigureRequestedVehicle {};
};

class UtilitiesAftermath {
    file = "\z\flo\addons\main\Functions\Utilities\Aftermath";

    class aftermathCleanupManager {};
    class aftermathCleanupRun {};
    class aftermathGetPlayerPositions {};
    class aftermathIsWreckSettled {};
    class aftermathIsPositionInHotObjective {};
    class aftermathRegisterEntity {};
    class aftermathShouldCleanupEntity {};
    class vehicleCleanupBuildContext {};
    class vehicleCleanupDiscoverCandidates {};
    class vehicleCleanupManager {};
    class vehicleCleanupProcessCandidates {};
    class vehicleCleanupRun {};
    class vehicleShouldCleanup {};
};
