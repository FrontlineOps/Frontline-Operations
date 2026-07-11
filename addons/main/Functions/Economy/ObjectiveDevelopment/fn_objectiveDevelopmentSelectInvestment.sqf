params [["_side", sideUnknown, [west]]];

if !(_side in [west, east]) then { throw format ["Invalid development investment side %1", _side]; };
private _sideKey = [_side] call FLO_fnc_sideKey;
private _activeObjectiveIds = [_sideKey] call FLO_fnc_objectiveDevelopmentGetActiveObjectiveIds;
if ((count _activeObjectiveIds) >= (FLO_ObjectiveDevelopmentConfig get "maximumConcurrentProjects")) exitWith { "" };

private _treasury = FLO_SideResources get _sideKey;
private _spendingState = [_treasury] call FLO_fnc_commanderSpendingGetState;
if ((_spendingState get "posture") != "SURPLUS") exitWith { "" };

private _network = FLO_Logistics_Networks get _sideKey;
[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _routeInfo = _network get "_supplyRouteInfo";
private _maxLevels = FLO_ObjectiveDevelopmentConfig get "maxLevelBySubtype";
private _resourceValues = _treasury get "RESOURCE_VALUES";
private _supplyPerTick = FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick";
private _enemyCountKey = ["opforCount", "bluforCount"] select (_side isEqualTo east);
private _ranked = [];

{
    private _objectiveId = _x;
    private _objective = _y;
    if (_objectiveId in _activeObjectiveIds) then { continue };
    if ((_objective get "owner") isNotEqualTo _side) then { continue };
    if ((_objective get "campaignIntegrationState") != "INTEGRATED") then { continue };
    if !(_objectiveId in _routeInfo) then { continue };
    if ((keys (_objective get "developmentProject")) isNotEqualTo []) then { continue };
    if ((_objective get "contested") || {_objective get "underAttack"} || {(_objective get _enemyCountKey) > 0}) then { continue };

    private _subtype = _objective get "subtype";
    private _level = _objective get "developmentLevel";
    private _maxLevel = _maxLevels get _subtype;
    if (_level >= _maxLevel) then { continue };

    private _sourceObjectiveId = [_network, _objectiveId, [], _supplyPerTick] call FLO_fnc_logisticsNetworkFindSupplySourceObjective;
    if (_sourceObjectiveId == "") then { continue };

    private _currentTier = [_level] call FLO_fnc_objectiveDevelopmentGetTier;
    private _nextTier = [_level + 1] call FLO_fnc_objectiveDevelopmentGetTier;
    private _cost = _nextTier get "treasuryCost";
    private _addedIncome = (_resourceValues get _subtype)
        * ((_nextTier get "incomeMultiplier") - (_currentTier get "incomeMultiplier"));
    private _score = ((_addedIncome / _cost) * 100000) + (_objective get "priority");
    _ranked pushBack [_score, _objectiveId];
} forEach FLO_Objectives;

_ranked sort false;
if (_ranked isEqualTo []) exitWith { "" };
(_ranked select 0) select 1
