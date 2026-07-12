params [
    ["_side", sideUnknown, [west]],
    ["_objectiveId", "", [""]]
];

if !(_objectiveId in FLO_Objectives) then { throw format ["Cannot process missing development objective %1", _objectiveId]; };
private _objective = FLO_Objectives get _objectiveId;
[_objectiveId, _objective, true] call FLO_fnc_objectiveDevelopmentValidateProject;
private _project = _objective get "developmentProject";
if ((keys _project) isEqualTo []) exitWith { false };
if ((_objective get "owner") isNotEqualTo _side) then {
    throw format ["Development project %1 owner changed outside the capture handler", _objectiveId];
};
if ((_project get "state") == "FUNDING") exitWith { false };

private _enemyCountKey = ["opforCount", "bluforCount"] select (_side isEqualTo east);
if ((_objective get "contested") || {_objective get "underAttack"} || {(_objective get _enemyCountKey) > 0}) exitWith {
    private _changed = (_project get "state") != "PAUSED_COMBAT";
    _project set ["state", "PAUSED_COMBAT"];
    _objective set ["developmentProject", _project];
    FLO_Objectives set [_objectiveId, _objective];
    _changed
};

private _remaining = (_project get "supplyRequired") - (_project get "supplyDelivered");
if (_remaining <= 0) exitWith {
    [_objectiveId, _objective] call FLO_fnc_objectiveDevelopmentCompleteProject
};

private _sideKey = [_side] call FLO_fnc_sideKey;
private _network = FLO_Logistics_Networks get _sideKey;
private _amount = (FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick") min _remaining;
private _sourceObjectiveId = [_network, _objectiveId, [], _amount] call FLO_fnc_logisticsNetworkFindSupplySourceObjective;
if (_sourceObjectiveId == "") exitWith {
    private _changed = (_project get "state") != "BLOCKED_LOGISTICS";
    _project set ["state", "BLOCKED_LOGISTICS"];
    _project set ["sourceObjectiveId", ""];
    _objective set ["developmentProject", _project];
    FLO_Objectives set [_objectiveId, _objective];
    _changed
};

private _source = (_network get "_activeSupplyNodes") get _sourceObjectiveId;
private _sourceNodeId = _source get "nodeId";
if !([_network, _sourceNodeId, _amount, format ["Development at %1", _objectiveId]] call FLO_fnc_logisticsNetworkConsumeThroughput) exitWith {
    private _changed = (_project get "state") != "BLOCKED_LOGISTICS";
    _project set ["state", "BLOCKED_LOGISTICS"];
    _objective set ["developmentProject", _project];
    FLO_Objectives set [_objectiveId, _objective];
    _changed
};

_project set ["state", "ACTIVE"];
_project set ["sourceObjectiveId", _sourceObjectiveId];
_project set ["commanderSupply", (_project get "commanderSupply") + _amount];
_project set ["supplyDelivered", (_project get "supplyDelivered") + _amount];
_objective set ["developmentProject", _project];
[_objectiveId, _objective, true] call FLO_fnc_objectiveDevelopmentValidateProject;
FLO_Objectives set [_objectiveId, _objective];

if ((_project get "supplyDelivered") >= (_project get "supplyRequired")) then {
    [_objectiveId, _objective] call FLO_fnc_objectiveDevelopmentCompleteProject;
};
true
