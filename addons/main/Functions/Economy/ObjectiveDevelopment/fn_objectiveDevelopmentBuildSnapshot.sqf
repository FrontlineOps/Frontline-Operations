params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]],
    ["_viewerSide", sideUnknown, [west]]
];

if !(_viewerSide in [west, east]) then { throw format ["Invalid development snapshot side %1", _viewerSide]; };
private _friendly = (_objective get "owner") isEqualTo _viewerSide;
if (!_friendly) exitWith { createHashMapFromArray [["visible", false]] };

private _sideKey = [_viewerSide] call FLO_fnc_sideKey;
private _level = _objective get "developmentLevel";
private _tier = [_level] call FLO_fnc_objectiveDevelopmentGetTier;
private _maxLevel = (FLO_ObjectiveDevelopmentConfig get "maxLevelBySubtype") get (_objective get "subtype");
private _treasury = FLO_SideResources get _sideKey;
private _network = FLO_Logistics_Networks get _sideKey;
private _incomePerCycle = 0;
if (
    (_objective get "campaignIntegrationState") == "INTEGRATED"
    && {_objectiveId in (_network get "_supplyRouteInfo")}
) then {
    _incomePerCycle = round (([_treasury, _objective] call FLO_fnc_sideResourcesCalculateObjectiveIncome) select 0);
};
private _project = _objective get "developmentProject";
private _projectSnapshot = createHashMapFromArray [["active", false]];

if ((keys _project) isNotEqualTo []) then {
    [_objectiveId, _objective] call FLO_fnc_objectiveDevelopmentValidateProject;
    private _supplyRequired = _project get "supplyRequired";
    private _supplyDelivered = _project get "supplyDelivered";
    private _playerSupply = _project get "playerSupply";
    private _playerSupplyCap = _project get "playerSupplyCap";
    private _remaining = (_supplyRequired - _supplyDelivered) max 0;
    private _supplyPerTick = FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick";
    private _tickInterval = FLO_ObjectiveDevelopmentConfig get "tickInterval";
    private _sourceObjectiveId = _project get "sourceObjectiveId";
    private _sourceName = "--";
    if (_sourceObjectiveId != "") then { _sourceName = [_sourceObjectiveId] call FLO_fnc_campaignObjectiveName; };
    private _shipmentAmount = _network get "SHIPMENT_THROUGHPUT";
    private _playerCapacityRemaining = (_playerSupplyCap - _playerSupply) max 0;
    private _targetTier = [_project get "targetLevel"] call FLO_fnc_objectiveDevelopmentGetTier;
    _projectSnapshot = createHashMapFromArray [
        ["active", true],
        ["state", _project get "state"],
        ["targetLevel", _project get "targetLevel"],
        ["targetName", _targetTier get "name"],
        ["supplyRequired", _supplyRequired],
        ["supplyDelivered", _supplyDelivered],
        ["commanderSupply", _project get "commanderSupply"],
        ["playerSupply", _playerSupply],
        ["playerSupplyCap", _playerSupplyCap],
        ["playerCapacityRemaining", _playerCapacityRemaining],
        ["progressPercent", round ((_supplyDelivered / _supplyRequired) * 100)],
        ["estimatedRemainingSeconds", ceil (_remaining / _supplyPerTick) * _tickInterval],
        ["playerTimeSavedSeconds", round ((_playerSupply / _supplyPerTick) * _tickInterval)],
        ["sourceObjectiveId", _sourceObjectiveId],
        ["sourceName", _sourceName],
        ["lastContributorName", _project get "lastContributorName"],
        ["canContribute", _playerCapacityRemaining >= _shipmentAmount && {_remaining >= _shipmentAmount}],
        ["shipmentAmount", _shipmentAmount]
    ];
};

private _nextTierName = "MAXIMUM";
if (_level < _maxLevel) then { _nextTierName = ([_level + 1] call FLO_fnc_objectiveDevelopmentGetTier) get "name"; };
createHashMapFromArray [
    ["visible", _friendly],
    ["level", _level],
    ["maxLevel", _maxLevel],
    ["name", _tier get "name"],
    ["nextName", _nextTierName],
    ["incomeMultiplier", _tier get "incomeMultiplier"],
    ["incomePerCycle", _incomePerCycle],
    ["project", _projectSnapshot]
]
