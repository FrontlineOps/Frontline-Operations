params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]],
    ["_viewerSide", sideUnknown, [west]]
];

if !(_viewerSide in [west, east]) then { throw format ["Invalid Development snapshot side %1", _viewerSide]; };
private _friendly = (_objective get "owner") isEqualTo _viewerSide;
if (!_friendly) exitWith { createHashMapFromArray [["visible", false]] };

private _sideKey = [_viewerSide] call FLO_fnc_sideKey;
private _revenueLevel = _objective get "revenueLevel";
private _developmentLevel = _objective get "developmentLevel";
private _treasury = FLO_SideResources get _sideKey;
private _network = FLO_Logistics_Networks get _sideKey;
private _incomePerCycle = 0;
if (
    (_objective get "campaignIntegrationState") == "INTEGRATED"
    && {_objectiveId in (_network get "_supplyRouteInfo")}
) then {
    _incomePerCycle = round (([_treasury, _objective] call FLO_fnc_sideResourcesCalculateObjectiveIncome) select 0);
};

private _revenueQuote = [_viewerSide, _objectiveId, _objective, "REVENUE"] call FLO_fnc_objectiveDevelopmentBuildProjectQuote;
private _developmentQuote = [_viewerSide, _objectiveId, _objective, "DEVELOPMENT"] call FLO_fnc_objectiveDevelopmentBuildProjectQuote;
private _project = _objective get "developmentProject";
private _projectSnapshot = createHashMapFromArray [["active", false]];

if ((keys _project) isNotEqualTo []) then {
    [_objectiveId, _objective, true] call FLO_fnc_objectiveDevelopmentValidateProject;
    private _state = _project get "state";
    private _fundingRequired = _project get "treasuryCost";
    private _fundingReserved = _fundingRequired;
    if (_state == "FUNDING") then {
        private _reservationId = _project get "reservationId";
        private _reservations = _treasury get "_reservations";
        if !(_reservationId in _reservations) then {
            throw format ["Development snapshot %1 is missing reservation %2", _objectiveId, _reservationId];
        };
        _fundingReserved = (_reservations get _reservationId) get "remaining";
    };

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
    private _fundingPercent = round ((_fundingReserved / _fundingRequired) * 100);
    private _supplyPercent = round ((_supplyDelivered / _supplyRequired) * 100);
    private _funding = _state == "FUNDING";
    _projectSnapshot = createHashMapFromArray [
        ["active", true],
        ["branch", _project get "branch"],
        ["state", _state],
        ["targetLevel", _project get "targetLevel"],
        ["targetName", format ["%1 LEVEL %2", _project get "branch", _project get "targetLevel"]],
        ["rawTreasuryCost", _project get "rawTreasuryCost"],
        ["discountApplied", _project get "discountApplied"],
        ["treasuryCost", _project get "treasuryCost"],
        ["fundingReserved", _fundingReserved],
        ["fundingRequired", _fundingRequired],
        ["fundingRemaining", (_fundingRequired - _fundingReserved) max 0],
        ["fundingPercent", _fundingPercent],
        ["supplyRequired", _supplyRequired],
        ["supplyDelivered", _supplyDelivered],
        ["supplyPercent", _supplyPercent],
        ["commanderSupply", _project get "commanderSupply"],
        ["playerSupply", _playerSupply],
        ["playerSupplyCap", _playerSupplyCap],
        ["playerCapacityRemaining", _playerCapacityRemaining],
        ["progressKind", ["SUPPLY", "TREASURY"] select _funding],
        ["progressCurrent", [_supplyDelivered, _fundingReserved] select _funding],
        ["progressRequired", [_supplyRequired, _fundingRequired] select _funding],
        ["progressPercent", [_supplyPercent, _fundingPercent] select _funding],
        ["estimatedRemainingSeconds", ceil (_remaining / _supplyPerTick) * _tickInterval],
        ["estimatedConstructionSeconds", ceil (_supplyRequired / _supplyPerTick) * _tickInterval],
        ["playerTimeSavedSeconds", round ((_playerSupply / _supplyPerTick) * _tickInterval)],
        ["sourceObjectiveId", _sourceObjectiveId],
        ["sourceName", _sourceName],
        ["lastContributorName", _project get "lastContributorName"],
        ["canContribute", !_funding && {_playerCapacityRemaining >= _shipmentAmount} && {_remaining >= _shipmentAmount}],
        ["shipmentAmount", _shipmentAmount]
    ];
};

createHashMapFromArray [
    ["visible", _friendly],
    ["revenueLevel", _revenueLevel],
    ["revenueMultiplier", [_revenueLevel] call FLO_fnc_objectiveDevelopmentRevenueMultiplier],
    ["developmentLevel", _developmentLevel],
    ["developmentDiscount", [_developmentLevel] call FLO_fnc_objectiveDevelopmentDiscount],
    ["incomePerCycle", _incomePerCycle],
    ["nextRevenueQuote", _revenueQuote],
    ["nextDevelopmentQuote", _developmentQuote],
    ["project", _projectSnapshot]
]
