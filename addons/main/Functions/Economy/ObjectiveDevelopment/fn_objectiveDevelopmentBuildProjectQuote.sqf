params [
    ["_side", sideUnknown, [west]],
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]],
    ["_branch", "", [""]]
];

if !(_side in [west, east]) then { throw format ["Invalid project quote side %1", _side]; };
if (_objectiveId == "") then { throw "Project quote requires an objective ID"; };
if ((_objective get "owner") isNotEqualTo _side) then {
    throw format ["Project quote side does not own objective %1", _objectiveId];
};
_branch = toUpper _branch;
if !(_branch in (FLO_ObjectiveDevelopmentConfig get "validBranches")) then {
    throw format ["Invalid project quote branch %1", _branch];
};

private _sideKey = [_side] call FLO_fnc_sideKey;
private _treasury = FLO_SideResources get _sideKey;
private _currentLevel = [_objective, _branch] call FLO_fnc_objectiveDevelopmentGetBranchLevel;
private _targetLevel = _currentLevel + 1;
private _developmentLevel = _objective get "developmentLevel";
private _discount = [_developmentLevel] call FLO_fnc_objectiveDevelopmentDiscount;
private _rawTreasuryCost = 0;
private _addedIncome = 0;
private _currentRevenueMultiplier = [_objective get "revenueLevel"] call FLO_fnc_objectiveDevelopmentRevenueMultiplier;
private _targetRevenueMultiplier = _currentRevenueMultiplier;

if (_branch == "REVENUE") then {
    _targetRevenueMultiplier = [_targetLevel] call FLO_fnc_objectiveDevelopmentRevenueMultiplier;
    private _baseIncome = (_treasury get "RESOURCE_VALUES") get (_objective get "subtype");
    private _incomeInterval = _treasury get "UPDATE_INTERVAL";
    if !(_incomeInterval isEqualType 0 && {_incomeInterval > 0}) then {
        throw format ["Invalid %1 Development income interval: %2", _sideKey, _incomeInterval];
    };
    _addedIncome = (_baseIncome * (_incomeInterval / 60))
        * (_targetRevenueMultiplier - _currentRevenueMultiplier);
    _rawTreasuryCost = ceil (_addedIncome * (FLO_ObjectiveDevelopmentConfig get "revenuePaybackCycles"));
} else {
    _rawTreasuryCost = (FLO_ObjectiveDevelopmentConfig get "developmentBaseCost") * _targetLevel * _targetLevel;
};

private _discountFactor = 1 - _discount;
private _treasuryCost = 1 max (ceil (_rawTreasuryCost * _discountFactor));
private _supplyPerTick = FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick";
private _supplyRequired = ceil (
    (_rawTreasuryCost * (FLO_ObjectiveDevelopmentConfig get "supplyPerTreasury") * _discountFactor) / _supplyPerTick
) * _supplyPerTick;
_supplyRequired = _supplyRequired max (FLO_ObjectiveDevelopmentConfig get "minimumSupplyRequired");
private _shipmentAmount = FLO_ObjectiveDevelopmentConfig get "shipmentAmount";
private _playerSupplyCap = floor (
    (_supplyRequired * (FLO_ObjectiveDevelopmentConfig get "playerContributionFraction")) / _shipmentAmount
) * _shipmentAmount;
private _targetDevelopmentLevel = [_developmentLevel, _targetLevel] select (_branch == "DEVELOPMENT");

createHashMapFromArray [
    ["branch", _branch],
    ["currentLevel", _currentLevel],
    ["targetLevel", _targetLevel],
    ["rawTreasuryCost", _rawTreasuryCost],
    ["discountApplied", _discount],
    ["treasuryCost", _treasuryCost],
    ["supplyRequired", _supplyRequired],
    ["playerSupplyCap", _playerSupplyCap],
    ["addedIncome", _addedIncome],
    ["currentRevenueMultiplier", _currentRevenueMultiplier],
    ["targetRevenueMultiplier", _targetRevenueMultiplier],
    ["currentDevelopmentDiscount", _discount],
    ["targetDevelopmentDiscount", [_targetDevelopmentLevel] call FLO_fnc_objectiveDevelopmentDiscount],
    ["estimatedDurationSeconds", ceil (_supplyRequired / _supplyPerTick) * (FLO_ObjectiveDevelopmentConfig get "tickInterval")]
]
