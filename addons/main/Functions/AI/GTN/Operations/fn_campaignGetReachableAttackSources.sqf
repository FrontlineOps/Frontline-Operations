/* Returns commander-valid attack sources connected through maintained route topology. */
params [
    "_commander",
    "_network",
    ["_objectiveId", "", [""]]
];

private _sources = _commander call ["_getFriendlyAttackSourceObjectives", [_objectiveId]];
[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _routeInfo = _network get "_supplyRouteInfo";
_sources select { _x in _routeInfo }
