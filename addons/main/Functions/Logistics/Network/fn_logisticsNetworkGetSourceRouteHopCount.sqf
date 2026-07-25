/* Counts maintained parent-route links to existing logistics infrastructure. */
params [
    "_network",
    ["_targetObjectiveId", "", [""]]
];

[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _routeInfo = _network get "_supplyRouteInfo";
if !(_targetObjectiveId in _routeInfo) exitWith { -1 };

private _infrastructureObjectives = createHashMap;
{
    private _node = _y;
    private _objectiveId = _node get "objectiveId";
    if (
        _objectiveId in _routeInfo
        && {(_node get "type") in ["HQ", "DEPOT", "FOB"]}
        && {(_node get "state") in ["CONNECTED", "STRAINED", "ESTABLISHING"]}
    ) then {
        _infrastructureObjectives set [_objectiveId, true];
    };
} forEach (_network get "_nodes");

private _cursor = _targetObjectiveId;
private _hopCount = 0;
private _sourceFound = false;

while {_cursor != "" && {!_sourceFound}} do {
    if (_cursor in _infrastructureObjectives) then {
        _sourceFound = true;
    } else {
        _cursor = (_routeInfo get _cursor) get "parentObjective";
        _hopCount = _hopCount + 1;
    };
};

[_hopCount, -1] select (!_sourceFound)
