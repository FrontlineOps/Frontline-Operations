/* Builds territory-scaled depot coverage from maintained objective-route state. */
params ["_network"];

private _nowTick = diag_tickTime;
if (_nowTick < (_network get "_nextDepotPlanningAtTick")) exitWith { "" };

private _planningInterval = _network get "DEPOT_PLANNING_INTERVAL";
private _objectivesPerDepot = _network get "DEPOT_TERRITORY_OBJECTIVES_PER_NODE";
private _minimumSourceHops = _network get "DEPOT_MIN_SOURCE_HOPS";
if (_planningInterval <= 0) then {
    private _message = format ["Invalid depot planning interval %1", _planningInterval];
    ["LOGISTICS", 1, _message] call FLO_fnc_log;
    throw _message;
};
if (_objectivesPerDepot <= 0) then {
    private _message = format ["Invalid territory objectives-per-depot value %1", _objectivesPerDepot];
    ["LOGISTICS", 1, _message] call FLO_fnc_log;
    throw _message;
};
if (_minimumSourceHops < 1) then {
    private _message = format ["Invalid depot route-hop minimum %1", _minimumSourceHops];
    ["LOGISTICS", 1, _message] call FLO_fnc_log;
    throw _message;
};
_network set ["_nextDepotPlanningAtTick", _nowTick + _planningInterval];

[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _routeInfo = _network get "_supplyRouteInfo";
private _securedObjectiveCount = count (keys _routeInfo);
if (_securedObjectiveCount == 0) exitWith { "" };

private _infrastructureObjectives = createHashMap;
private _depotCount = 0;
{
    private _node = _y;
    private _objectiveId = _node get "objectiveId";
    private _nodeType = _node get "type";
    private _nodeState = _node get "state";
    if (
        _objectiveId in _routeInfo
        && {_nodeType in ["HQ", "DEPOT", "FOB"]}
        && {_nodeState in ["CONNECTED", "STRAINED", "ESTABLISHING"]}
    ) then {
        _infrastructureObjectives set [_objectiveId, true];
        if (_nodeType == "DEPOT") then {
            _depotCount = _depotCount + 1;
        };
    };
} forEach (_network get "_nodes");

private _desiredDepotCount = ceil (_securedObjectiveCount / _objectivesPerDepot);
if (_depotCount >= _desiredDepotCount) exitWith { "" };

private _candidateRows = [];
{
    private _objectiveId = _x;
    if (_objectiveId in _infrastructureObjectives) then { continue };

    private _objective = FLO_Objectives get _objectiveId;
    if ((_objective get "contested") || {_objective get "underAttack"}) then { continue };

    private _cursor = _objectiveId;
    private _sourceHops = -1;
    private _hopCount = 0;
    while {_cursor != "" && {_sourceHops < 0}} do {
        if (_cursor in _infrastructureObjectives) then {
            _sourceHops = _hopCount;
        } else {
            _cursor = (_routeInfo get _cursor) get "parentObjective";
            _hopCount = _hopCount + 1;
        };
    };
    if (_sourceHops < _minimumSourceHops) then { continue };

    private _route = _routeInfo get _objectiveId;
    _candidateRows pushBack [
        _sourceHops,
        _objective get "priority",
        _route get "routeMeters",
        _objectiveId
    ];
} forEach (keys _routeInfo);

if (_candidateRows isEqualTo []) exitWith { "" };
_candidateRows sort false;
private _selection = _candidateRows select 0;
private _objectiveId = _selection select 3;
private _sourceHops = _selection select 0;
private _referenceId = format [
    "TERRITORY_COVERAGE secured=%1 depots=%2/%3 hops=%4",
    _securedObjectiveCount,
    _depotCount + 1,
    _desiredDepotCount,
    _sourceHops
];

[_network, _objectiveId, _referenceId] call FLO_fnc_logisticsNetworkEstablishForwardDepot
