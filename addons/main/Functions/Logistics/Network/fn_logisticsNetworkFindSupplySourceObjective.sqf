/* Finds the nearest unblocked explicit source on the target's route to HQ. */
params [
    "_network",
    ["_targetObjectiveId", "", [""]],
    ["_blockedObjectives", [], [[]]],
    ["_requiredThroughput", 0, [0]]
];

if (_targetObjectiveId == "") exitWith { "" };
if !(_targetObjectiveId in FLO_Objectives) exitWith { "" };

[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _routeInfo = _network get "_supplyRouteInfo";
private _activeSources = _network get "_activeSupplyNodes";
if !(_targetObjectiveId in _routeInfo) exitWith { "" };

private _cursor = _targetObjectiveId;
private _sourceObjectiveId = "";
while {_cursor != "" && {_sourceObjectiveId == ""}} do {
    if (_cursor in _activeSources && {!(_cursor in _blockedObjectives)}) then {
        private _source = _activeSources get _cursor;
        if ((_source get "throughput") >= _requiredThroughput) then {
            _sourceObjectiveId = _cursor;
        };
    };

    if (_sourceObjectiveId == "") then {
        _cursor = if (_cursor in _routeInfo) then {
            (_routeInfo get _cursor) get "parentObjective"
        } else {
            ""
        };
    };
};

_sourceObjectiveId
