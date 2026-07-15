params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]],
    ["_validateEconomics", false, [false]]
];

private _project = _objective get "developmentProject";
if ((keys _project) isEqualTo []) exitWith { true };

private _requiredKeys = [
    "sideKey",
    "branch",
    "state",
    "targetLevel",
    "createdAtDateNum",
    "startedAtDateNum",
    "rawTreasuryCost",
    "discountApplied",
    "treasuryCost",
    "supplyRequired",
    "supplyDelivered",
    "commanderSupply",
    "playerSupply",
    "playerSupplyCap",
    "sourceObjectiveId",
    "lastContributorName",
    "reservationId"
];
private _missing = _requiredKeys select { !(_x in _project) };
if (_missing isNotEqualTo []) then {
    throw format ["Development project %1 is missing fields %2", _objectiveId, _missing];
};
private _unexpected = (keys _project) select { !(_x in _requiredKeys) };
if (_unexpected isNotEqualTo []) then {
    throw format ["Development project %1 has unsupported fields %2", _objectiveId, _unexpected];
};

private _owner = _objective get "owner";
if !(_owner in [west, east]) then {
    throw format ["Development project %1 has unsupported owner %2", _objectiveId, _owner];
};
private _sideKey = [_owner] call FLO_fnc_sideKey;
if ((_project get "sideKey") != _sideKey) then {
    throw format ["Development project %1 side %2 does not match owner %3", _objectiveId, _project get "sideKey", _sideKey];
};

private _branch = _project get "branch";
if !(_branch in (FLO_ObjectiveDevelopmentConfig get "validBranches")) then {
    throw format ["Development project %1 has invalid branch %2", _objectiveId, _branch];
};

private _state = _project get "state";
if !(_state in (FLO_ObjectiveDevelopmentConfig get "validProjectStates")) then {
    throw format ["Development project %1 has invalid state %2", _objectiveId, _state];
};

private _level = [_objective, _branch] call FLO_fnc_objectiveDevelopmentGetBranchLevel;
private _targetLevel = _project get "targetLevel";
if !(_targetLevel isEqualType 0 && {_targetLevel == (_level + 1)}) then {
    throw format ["Development project %1 target level %2 does not follow %3 level %4", _objectiveId, _targetLevel, _branch, _level];
};

{
    private _value = _project get _x;
    if !(_value isEqualType 0 && {_value >= 0}) then {
        throw format ["Development project %1 has invalid %2 value %3", _objectiveId, _x, _value];
    };
} forEach [
    "createdAtDateNum",
    "startedAtDateNum",
    "rawTreasuryCost",
    "discountApplied",
    "treasuryCost",
    "supplyRequired",
    "supplyDelivered",
    "commanderSupply",
    "playerSupply",
    "playerSupplyCap"
];
if ((_project get "rawTreasuryCost") <= 0 || {(_project get "treasuryCost") <= 0} || {(_project get "supplyRequired") <= 0}) then {
    throw format ["Development project %1 has non-positive project economics", _objectiveId];
};
if ((_project get "discountApplied") >= 0.5) then {
    throw format ["Development project %1 has invalid discount %2", _objectiveId, _project get "discountApplied"];
};
if (((_project get "supplyRequired") mod (FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick")) != 0) then {
    throw format ["Development project %1 supply requirement is not divisible by commander delivery", _objectiveId];
};
if (((_project get "playerSupplyCap") mod (FLO_ObjectiveDevelopmentConfig get "shipmentAmount")) != 0) then {
    throw format ["Development project %1 player cap is not divisible by shipment amount", _objectiveId];
};

private _supplyRequired = _project get "supplyRequired";
private _supplyDelivered = _project get "supplyDelivered";
private _commanderSupply = _project get "commanderSupply";
private _playerSupply = _project get "playerSupply";
if (_supplyDelivered > _supplyRequired) then {
    throw format ["Development project %1 delivered supply exceeds its requirement", _objectiveId];
};
if (abs (_supplyDelivered - (_commanderSupply + _playerSupply)) > 0.001) then {
    throw format ["Development project %1 supply ledger does not balance", _objectiveId];
};
if (_playerSupply > (_project get "playerSupplyCap")) then {
    throw format ["Development project %1 exceeds its player contribution cap", _objectiveId];
};
if !(
    (_project get "sourceObjectiveId") isEqualType ""
    && {(_project get "lastContributorName") isEqualType ""}
    && {(_project get "reservationId") isEqualType ""}
) then {
    throw format ["Development project %1 has invalid text fields", _objectiveId];
};

if (_state == "FUNDING") then {
    if ((_project get "reservationId") == "") then {
        throw format ["Funding project %1 has no treasury reservation ID", _objectiveId];
    };
    if ((_project get "startedAtDateNum") != 0 || {_supplyDelivered != 0} || {(_project get "sourceObjectiveId") != ""}) then {
        throw format ["Funding project %1 contains active-project state", _objectiveId];
    };
} else {
    if ((_project get "reservationId") != "") then {
        throw format ["Funded project %1 still owns treasury reservation %2", _objectiveId, _project get "reservationId"];
    };
};

if (_validateEconomics) then {
    private _quote = [_owner, _objectiveId, _objective, _branch] call FLO_fnc_objectiveDevelopmentBuildProjectQuote;
    {
        private _field = _x;
        if ((_project get _field) != (_quote get _field)) then {
            throw format ["Development project %1 %2 does not match the current quote", _objectiveId, _field];
        };
    } forEach ["targetLevel", "rawTreasuryCost", "treasuryCost", "supplyRequired", "playerSupplyCap"];
    if (abs ((_project get "discountApplied") - (_quote get "discountApplied")) > 0.000001) then {
        throw format ["Development project %1 discount does not match the current quote", _objectiveId];
    };
};

true
