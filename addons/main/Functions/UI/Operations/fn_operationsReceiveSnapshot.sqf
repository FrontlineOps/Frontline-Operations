params ["_snapshot"];

if (!hasInterface) exitWith {};

FLO_OperationsLastSnapshot = _snapshot;
[_snapshot] call FLO_fnc_operationsBuildMapDrawData;

private _objectiveIds = (_snapshot get "objectives") apply { _x get "id" };
if !(FLO_OperationsSelectedObjectiveId in _objectiveIds) then {
    private _operationTargetId = (_snapshot get "operation") get "targetId";
    private _playerObjectiveId = (_snapshot get "player") get "objectiveId";
    FLO_OperationsSelectedObjectiveId = if (_operationTargetId in _objectiveIds) then {
        _operationTargetId
    } else {
        ["", _playerObjectiveId] select (_playerObjectiveId in _objectiveIds)
    };
};

[_snapshot] call FLO_fnc_operationsUpdateDialog;

if (FLO_OperationsSelectedObjectiveId != "") then {
    [FLO_OperationsSelectedObjectiveId, false] call FLO_fnc_operationsSelectObjective;
};

if (!FLO_OperationsMapInitialized) then {
    FLO_OperationsMapInitialized = ["FIT"] call FLO_fnc_operationsFocusMap;
};
