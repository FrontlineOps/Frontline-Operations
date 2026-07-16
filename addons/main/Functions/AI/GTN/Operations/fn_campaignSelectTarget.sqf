/* Ranks untargeted enemy objectives directly connected to the friendly frontline. */
params [
    "_director",
    ["_side", sideUnknown, [east]],
    ["_excludedObjectiveIds", [], [[]]]
];

private _manager = _director get "_resourceManager";
private _commander = _manager call ["_getCommanderBySide", [_side]];
if (isNil "_commander") then {
    throw format ["FLO_fnc_campaignSelectTarget: no commander for %1", _side];
};

private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
private _network = FLO_Logistics_Networks get _sideKey;
private _activeSupplyNodes = [_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _frontline = _commander call ["_getAttackFrontlineEnemyObjectives", []];
private _config = _director get "_config";
private _minimumSamples = _config get "opportunityMinimumSamples";
private _minimumSourceSupply = _config get "operationLogisticsMinimumSupply";
private _opportunities = (_director get "_state") get "opportunities";
private _sideOpportunities = createHashMap;
private _terrainRejected = 0;
private _excludedRejected = 0;
private _noIntegratedSourceRejected = 0;
private _noSupplySourceRejected = 0;

{
    if ((_y get "sideKey") == _sideKey && {(_y get "sampleCount") >= _minimumSamples}) then {
        _sideOpportunities set [_y get "objectiveId", _y];
    };
} forEach _opportunities;

private _ranked = [];
{
    private _objectiveId = _x;
    private _objective = _y;
    if (_objectiveId in _excludedObjectiveIds) then {
        _excludedRejected = _excludedRejected + 1;
        continue;
    };

    private _objectivePosition = [_objectiveId, _objective] call FLO_fnc_campaignResolveAssaultLandAnchor;
    if (_objectivePosition isEqualTo []) then {
        _terrainRejected = _terrainRejected + 1;
        continue;
    };

    private _attackSourceObjectiveIds = _commander call ["_getFriendlyAttackSourceObjectives", [_objectiveId]];
    if (_attackSourceObjectiveIds isEqualTo []) then {
        _noIntegratedSourceRejected = _noIntegratedSourceRejected + 1;
        continue;
    };

    private _sourcePairs = [];
    {
        private _attackSourceObjectiveId = _x;
        private _supplySourceObjectiveId = [
            _network,
            _attackSourceObjectiveId,
            [],
            _minimumSourceSupply
        ] call FLO_fnc_logisticsNetworkFindSupplySourceObjective;
        if (_supplySourceObjectiveId == "") then { continue };
        if !(_supplySourceObjectiveId in _activeSupplyNodes) then {
            throw format ["Reachable supply source %1 is absent from active logistics state", _supplySourceObjectiveId];
        };
        _sourcePairs pushBack [_attackSourceObjectiveId, _supplySourceObjectiveId];
    } forEach _attackSourceObjectiveIds;
    if (_sourcePairs isEqualTo []) then {
        _noSupplySourceRejected = _noSupplySourceRejected + 1;
        continue;
    };

    private _nearestSourceDistance = 1e12;
    private _bestSupplyRatio = 0;
    {
        private _attackSourcePosition = (FLO_Objectives get (_x select 0)) get "position";
        _nearestSourceDistance = _nearestSourceDistance min (_objectivePosition distance2D _attackSourcePosition);
        private _source = _activeSupplyNodes get (_x select 1);
        private _node = (_network get "_nodes") get (_source get "nodeId");
        _bestSupplyRatio = _bestSupplyRatio max ((_source get "throughput") / (_node get "throughputMax"));
    } forEach _sourcePairs;

    private _score = ((_objective get "priority") * 10)
        + (_bestSupplyRatio * 50)
        - (_nearestSourceDistance / 250);
    private _fromOpportunity = _objectiveId in _sideOpportunities;
    if (_fromOpportunity) then {
        private _opportunity = _sideOpportunities get _objectiveId;
        _score = _score + (switch (_opportunity get "status") do {
            case "ASSAULT": { 300 };
            case "CONTACT": { 120 };
            default { 0 };
        });
        _score = _score + ((_opportunity get "sampleCount") min 20);
    };
    if (_objective get "contested") then { _score = _score + 40; };
    if (_objective get "underAttack") then { _score = _score + 20; };

    _ranked pushBack [
        _score,
        _objectiveId,
        _sourcePairs,
        _fromOpportunity,
        _objectivePosition
    ];
} forEach _frontline;

_ranked sort false;
if (_ranked isEqualTo []) exitWith {
    ["CAMPAIGN", 4, format [
        "No direct frontline assault target for %1: frontline=%2 excluded=%3 terrain=%4 noIntegratedSource=%5 noSupply=%6",
        _sideKey,
        count _frontline,
        _excludedRejected,
        _terrainRejected,
        _noIntegratedSourceRejected,
        _noSupplySourceRejected
    ]] call FLO_fnc_log;
    []
};

private _selections = [];
{
    private _selected = _x;
    private _objectiveId = _selected select 1;
    private _sourcePairs = _selected select 2;
    private _supplyRanking = [];
    private _rankedSupplyIds = [];
    {
        private _supplySourceObjectiveId = _x select 1;
        if (_supplySourceObjectiveId in _rankedSupplyIds) then { continue };
        _rankedSupplyIds pushBack _supplySourceObjectiveId;
        _supplyRanking pushBack [
            (_activeSupplyNodes get _supplySourceObjectiveId) get "throughput",
            _supplySourceObjectiveId
        ];
    } forEach _sourcePairs;
    _supplyRanking sort false;

    private _selectedSupplySourceObjectiveId = (_supplyRanking select 0) select 1;
    private _sourceObjectiveIds = (_sourcePairs select {
        (_x select 1) == _selectedSupplySourceObjectiveId
    }) apply { _x select 0 };
    private _supportObjectiveIds = +_sourceObjectiveIds;
    private _objective = FLO_Objectives get _objectiveId;
    {
        private _linked = FLO_Objectives get _x;
        if ((_linked get "owner") isEqualTo _side && {[_x] call FLO_fnc_campaignIsObjectiveIntegrated}) then {
            _supportObjectiveIds pushBackUnique _x;
        };
    } forEach (_objective get "linkedObjectives");

    _selections pushBack createHashMapFromArray [
        ["objectiveId", _objectiveId],
        ["sourceObjectiveIds", _sourceObjectiveIds],
        ["supportObjectiveIds", _supportObjectiveIds],
        ["supplySourceObjectiveId", _selectedSupplySourceObjectiveId],
        ["fromOpportunity", _selected select 3],
        ["assaultLandAnchor", _selected select 4]
    ];
} forEach _ranked;

_selections
