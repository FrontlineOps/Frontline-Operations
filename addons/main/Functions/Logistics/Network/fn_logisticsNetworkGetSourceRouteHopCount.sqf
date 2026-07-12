/* Counts maintained objective-route links to the nearest active source. */
params [
    "_network",
    ["_targetObjectiveId", "", [""]]
];

private _sourceObjectiveId = [_network, _targetObjectiveId] call FLO_fnc_logisticsNetworkFindSupplySourceObjective;
if (_sourceObjectiveId == "") exitWith { -1 };

private _routeInfo = _network get "_supplyRouteInfo";
private _cursor = _targetObjectiveId;
private _hopCount = 0;

while {_cursor != _sourceObjectiveId} do {
    _cursor = (_routeInfo get _cursor) get "parentObjective";
    _hopCount = _hopCount + 1;
};

_hopCount
