params [["_side", sideUnknown, [west]]];

if !(_side in [west, east]) then { throw format ["Invalid Development investment side %1", _side]; };
private _sideKey = [_side] call FLO_fnc_sideKey;
private _activeObjectiveIds = [_sideKey] call FLO_fnc_objectiveDevelopmentGetActiveObjectiveIds;
if ((count _activeObjectiveIds) >= ([_side] call FLO_fnc_objectiveDevelopmentGetProjectCapacity)) exitWith { createHashMap };
if (([_sideKey] call FLO_fnc_objectiveDevelopmentGetFundingObjectiveId) != "") exitWith { createHashMap };

private _treasury = FLO_SideResources get _sideKey;
private _spendingState = [_treasury] call FLO_fnc_commanderSpendingGetState;
private _network = FLO_Logistics_Networks get _sideKey;
[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _routeInfo = _network get "_supplyRouteInfo";
private _supplyPerTick = FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick";
private _enemyCountKey = ["opforCount", "bluforCount"] select (_side isEqualTo east);
private _totalDevelopmentLevels = [_side] call FLO_fnc_objectiveDevelopmentGetTotalDevelopmentLevels;
private _incomeBasis = _spendingState get "developmentIncomeBasis";
private _capacityProgress = sqrt ((_totalDevelopmentLevels + 1) / (FLO_ObjectiveDevelopmentConfig get "projectSlotDivisor"))
    - sqrt (_totalDevelopmentLevels / (FLO_ObjectiveDevelopmentConfig get "projectSlotDivisor"));
private _ranked = [];

{
    private _objectiveId = _x;
    private _objective = _y;
    if ((_objective get "owner") isNotEqualTo _side) then { continue };
    if ((_objective get "campaignIntegrationState") != "INTEGRATED") then { continue };
    if !(_objectiveId in _routeInfo) then { continue };
    if ((keys (_objective get "developmentProject")) isNotEqualTo []) then { continue };
    if ((_objective get "contested") || {_objective get "underAttack"} || {(_objective get _enemyCountKey) > 0}) then { continue };
    if (([_network, _objectiveId, [], _supplyPerTick] call FLO_fnc_logisticsNetworkFindSupplySourceObjective) == "") then { continue };

    private _priority = _objective get "priority";
    private _revenueQuote = [_side, _objectiveId, _objective, "REVENUE"] call FLO_fnc_objectiveDevelopmentBuildProjectQuote;
    private _addedIncome = _revenueQuote get "addedIncome";
    private _revenueScore = ((_addedIncome / (_revenueQuote get "treasuryCost")) * 100000)
        + _priority;
    _ranked pushBack [_revenueScore, _objectiveId, "REVENUE"];

    private _developmentQuote = [_side, _objectiveId, _objective, "DEVELOPMENT"] call FLO_fnc_objectiveDevelopmentBuildProjectQuote;
    private _discountGain = (_developmentQuote get "targetDevelopmentDiscount")
        - (_developmentQuote get "currentDevelopmentDiscount");
    private _capacityValue = _incomeBasis
        * _capacityProgress
        * (FLO_ObjectiveDevelopmentConfig get "developmentCapacityValueFraction");
    private _nextRevenueSavings = (_revenueQuote get "rawTreasuryCost") * _discountGain;
    private _developmentBenefit = _capacityValue + _nextRevenueSavings;
    private _developmentScore = ((_developmentBenefit / (_developmentQuote get "treasuryCost")) * 100000) + _priority;
    _ranked pushBack [_developmentScore, _objectiveId, "DEVELOPMENT"];
} forEach FLO_Objectives;

_ranked sort false;
if (_ranked isEqualTo []) exitWith { createHashMap };
private _selected = _ranked select 0;
createHashMapFromArray [
    ["objectiveId", _selected select 1],
    ["branch", _selected select 2],
    ["score", _selected select 0]
]
