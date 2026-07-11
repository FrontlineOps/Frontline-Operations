params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]]
];

private _project = _objective get "developmentProject";
if ((keys _project) isEqualTo []) exitWith { true };

private _requiredKeys = [
    "sideKey",
    "state",
    "targetLevel",
    "startedAtDateNum",
    "treasuryCost",
    "supplyRequired",
    "supplyDelivered",
    "commanderSupply",
    "playerSupply",
    "playerSupplyCap",
    "sourceObjectiveId",
    "lastContributorName"
];
private _missing = _requiredKeys select { !(_x in _project) };
if (_missing isNotEqualTo []) then {
    throw format ["Development project %1 is missing fields %2", _objectiveId, _missing];
};

private _owner = _objective get "owner";
if !(_owner in [west, east]) then {
    throw format ["Development project %1 has unsupported owner %2", _objectiveId, _owner];
};
private _sideKey = [_owner] call FLO_fnc_sideKey;
if ((_project get "sideKey") != _sideKey) then {
    throw format ["Development project %1 side %2 does not match owner %3", _objectiveId, _project get "sideKey", _sideKey];
};

private _state = _project get "state";
if !(_state in (FLO_ObjectiveDevelopmentConfig get "validProjectStates")) then {
    throw format ["Development project %1 has invalid state %2", _objectiveId, _state];
};

private _level = _objective get "developmentLevel";
private _targetLevel = _project get "targetLevel";
if (_targetLevel != (_level + 1)) then {
    throw format ["Development project %1 target level %2 does not follow level %3", _objectiveId, _targetLevel, _level];
};
private _tier = [_targetLevel] call FLO_fnc_objectiveDevelopmentGetTier;
if ((_project get "treasuryCost") != (_tier get "treasuryCost")) then {
    throw format ["Development project %1 treasury cost does not match tier %2", _objectiveId, _targetLevel];
};
if ((_project get "supplyRequired") != (_tier get "supplyRequired")) then {
    throw format ["Development project %1 supply requirement does not match tier %2", _objectiveId, _targetLevel];
};
if ((_project get "playerSupplyCap") != (_tier get "playerSupplyCap")) then {
    throw format ["Development project %1 player cap does not match tier %2", _objectiveId, _targetLevel];
};

private _supplyRequired = _project get "supplyRequired";
private _supplyDelivered = _project get "supplyDelivered";
private _commanderSupply = _project get "commanderSupply";
private _playerSupply = _project get "playerSupply";
if (
    _supplyRequired <= 0
    || {_supplyDelivered < 0}
    || {_commanderSupply < 0}
    || {_playerSupply < 0}
    || {_supplyDelivered > _supplyRequired}
) then {
    throw format ["Development project %1 has invalid supply totals", _objectiveId];
};
if (abs (_supplyDelivered - (_commanderSupply + _playerSupply)) > 0.001) then {
    throw format ["Development project %1 supply ledger does not balance", _objectiveId];
};
if (_playerSupply > (_project get "playerSupplyCap")) then {
    throw format ["Development project %1 exceeds its player contribution cap", _objectiveId];
};
if !((_project get "startedAtDateNum") isEqualType 0) then {
    throw format ["Development project %1 has invalid start time", _objectiveId];
};
if !((_project get "sourceObjectiveId") isEqualType "" && {(_project get "lastContributorName") isEqualType ""}) then {
    throw format ["Development project %1 has invalid text fields", _objectiveId];
};

true
