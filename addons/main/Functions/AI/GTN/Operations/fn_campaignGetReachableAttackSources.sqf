/* Returns commander-valid attack sources that are connected to a live node. */
params [
    "_commander",
    "_network",
    ["_objectiveId", "", [""]]
];

private _sources = _commander call ["_getFriendlyAttackSourceObjectives", [_objectiveId]];
_sources select {
    ([_network, _x, [], 0] call FLO_fnc_logisticsNetworkFindSupplySourceObjective) != ""
}
