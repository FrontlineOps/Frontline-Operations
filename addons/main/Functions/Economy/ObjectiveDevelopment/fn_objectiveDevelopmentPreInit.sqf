FLO_ObjectiveDevelopmentConfig = createHashMapFromArray [
    ["schemaVersion", 2],
    ["pricingVersion", 2],
    ["tickInterval", 60],
    ["investmentInterval", 180],
    ["baseProjectSlots", 3],
    ["projectSlotDivisor", 4],
    ["maximumFundingProjects", 1],
    ["revenuePaybackCycles", 8],
    ["developmentBaseCost", 300],
    ["developmentCapacityValueFraction", 0.25],
    ["supplyPerTreasury", 15],
    ["minimumSupplyRequired", 6000],
    ["commanderSupplyPerTick", 300],
    ["playerContributionFraction", 0.25],
    ["shipmentAmount", 1500],
    ["assignmentRadius", 25],
    ["captureRetention", 0.75],
    ["supportedObjectiveSubtypes", ["capital", "city", "marine", "local", "village", "cluster"]],
    ["validBranches", ["REVENUE", "DEVELOPMENT"]],
    ["validProjectStates", ["FUNDING", "ACTIVE", "PAUSED_COMBAT", "BLOCKED_LOGISTICS"]],
    ["fundedProjectStates", ["ACTIVE", "PAUSED_COMBAT", "BLOCKED_LOGISTICS"]]
];

{
    private _value = FLO_ObjectiveDevelopmentConfig get _x;
    if !(_value isEqualType 0 && {_value > 0} && {_value == floor _value}) then {
        throw format ["Objective Development config %1 must be a positive integer, got %2", _x, _value];
    };
} forEach [
    "schemaVersion",
    "pricingVersion",
    "tickInterval",
    "investmentInterval",
    "baseProjectSlots",
    "projectSlotDivisor",
    "maximumFundingProjects",
    "revenuePaybackCycles",
    "developmentBaseCost",
    "supplyPerTreasury",
    "minimumSupplyRequired",
    "commanderSupplyPerTick",
    "shipmentAmount"
];

private _supplyPerTick = FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick";
private _minimumSupply = FLO_ObjectiveDevelopmentConfig get "minimumSupplyRequired";
private _shipmentAmount = FLO_ObjectiveDevelopmentConfig get "shipmentAmount";
if ((_minimumSupply mod _supplyPerTick) != 0) then {
    throw "Objective Development minimum supply must be divisible by commander supply per tick";
};
if ((_minimumSupply mod _shipmentAmount) != 0) then {
    throw "Objective Development minimum supply must be divisible by shipment amount";
};
private _playerFraction = FLO_ObjectiveDevelopmentConfig get "playerContributionFraction";
if !(_playerFraction isEqualType 0 && {_playerFraction > 0} && {_playerFraction <= 0.25}) then {
    throw format ["Objective Development player contribution fraction is invalid: %1", _playerFraction];
};
private _capacityValueFraction = FLO_ObjectiveDevelopmentConfig get "developmentCapacityValueFraction";
if !(_capacityValueFraction isEqualType 0 && {_capacityValueFraction > 0} && {_capacityValueFraction <= 1}) then {
    throw format ["Objective Development capacity value fraction is invalid: %1", _capacityValueFraction];
};

FLO_ObjectiveDevelopmentRuntime = createHashMapFromArray [
    ["pfhId", -1],
    ["nextInvestmentAt", createHashMapFromArray [["WEST", 0], ["EAST", 0]]],
    ["assignmentRequestAt", createHashMap]
];
