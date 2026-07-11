private _tiers = createHashMapFromArray [
    ["0", createHashMapFromArray [
        ["name", "INTEGRATED"],
        ["treasuryCost", 0],
        ["supplyRequired", 0],
        ["playerSupplyCap", 0],
        ["incomeMultiplier", 1.00]
    ]],
    ["1", createHashMapFromArray [
        ["name", "STABILIZED"],
        ["treasuryCost", 400],
        ["supplyRequired", 6000],
        ["playerSupplyCap", 1500],
        ["incomeMultiplier", 2.00]
    ]],
    ["2", createHashMapFromArray [
        ["name", "DEVELOPED"],
        ["treasuryCost", 900],
        ["supplyRequired", 12000],
        ["playerSupplyCap", 3000],
        ["incomeMultiplier", 4.00]
    ]],
    ["3", createHashMapFromArray [
        ["name", "REGIONAL_CENTER"],
        ["treasuryCost", 1800],
        ["supplyRequired", 18000],
        ["playerSupplyCap", 4500],
        ["incomeMultiplier", 8.00]
    ]]
];

FLO_ObjectiveDevelopmentConfig = createHashMapFromArray [
    ["tickInterval", 60],
    ["investmentInterval", 180],
    ["maximumConcurrentProjects", 3],
    ["commanderSupplyPerTick", 300],
    ["playerContributionFraction", 0.25],
    ["assignmentRadius", 25],
    ["tiers", _tiers],
    ["maxLevelBySubtype", createHashMapFromArray [
        ["capital", 3],
        ["city", 3],
        ["local", 2],
        ["marine", 2],
        ["village", 1],
        ["cluster", 0]
    ]],
    ["validProjectStates", ["ACTIVE", "PAUSED_COMBAT", "BLOCKED_LOGISTICS"]]
];

private _maximumConcurrentProjects = FLO_ObjectiveDevelopmentConfig get "maximumConcurrentProjects";
if !(_maximumConcurrentProjects isEqualType 0 && {_maximumConcurrentProjects > 0} && {_maximumConcurrentProjects == floor _maximumConcurrentProjects}) then {
    throw format ["Development maximum concurrent projects must be a positive integer, got %1", _maximumConcurrentProjects];
};

{
    private _tier = _tiers get str _x;
    private _supplyRequired = _tier get "supplyRequired";
    if ((_tier get "playerSupplyCap") != round (_supplyRequired * (FLO_ObjectiveDevelopmentConfig get "playerContributionFraction"))) then {
        throw format ["Development tier %1 player contribution cap is not 25 percent", _x];
    };
    if ((_supplyRequired mod (FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick")) != 0) then {
        throw format ["Development tier %1 supply requirement is not divisible by the commander tick", _x];
    };
} forEach [1, 2, 3];

FLO_ObjectiveDevelopmentRuntime = createHashMapFromArray [
    ["pfhId", -1],
    ["nextInvestmentAt", createHashMapFromArray [["WEST", 0], ["EAST", 0]]],
    ["assignmentRequestAt", createHashMap]
];
