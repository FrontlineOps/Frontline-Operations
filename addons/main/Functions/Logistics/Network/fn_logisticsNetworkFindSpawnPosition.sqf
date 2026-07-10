/* Resolves [spawn position, source objective ID, explicit source node ID]. */
params [
    "_network",
    ["_targetObjectiveId", "", [""]],
    ["_blockedObjectives", [], [[]]],
    ["_requiredThroughput", 0, [0]]
];

if (_targetObjectiveId == "") exitWith { [[0, 0, 0], "", ""] };

private _sourceObjectiveId = [
    _network,
    _targetObjectiveId,
    _blockedObjectives,
    _requiredThroughput
] call FLO_fnc_logisticsNetworkPickSpawnSourceObjective;
if (_sourceObjectiveId == "") exitWith { [[0, 0, 0], "", ""] };

private _activeSources = _network get "_activeSupplyNodes";
private _sourceNodeId = (_activeSources get _sourceObjectiveId) get "nodeId";
private _spawnPosition = [_network, _sourceObjectiveId] call FLO_fnc_logisticsNetworkGetCachedSpawnPosition;
if (_spawnPosition isEqualTo [0, 0, 0]) then {
    _spawnPosition = (FLO_Objectives get _sourceObjectiveId) get "position";
};

[_spawnPosition, _sourceObjectiveId, _sourceNodeId]
