params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]]
];

[_objectiveId, _objective] call FLO_fnc_objectiveDevelopmentValidateProject;
private _project = _objective get "developmentProject";
if ((keys _project) isEqualTo []) then { throw format ["Objective %1 has no development project to complete", _objectiveId]; };
if ((_project get "supplyDelivered") < (_project get "supplyRequired")) then {
    throw format ["Objective %1 development completed before its supply requirement", _objectiveId];
};

private _targetLevel = _project get "targetLevel";
private _tier = [_targetLevel] call FLO_fnc_objectiveDevelopmentGetTier;
private _side = _objective get "owner";
_objective set ["developmentLevel", _targetLevel];
_objective set ["developmentProject", createHashMap];
FLO_Objectives set [_objectiveId, _objective];

private _objectiveName = [_objectiveId] call FLO_fnc_campaignObjectiveName;
[_side, format ["Regional development completed at %1: %2 income is now active.", _objectiveName, _tier get "name"], "success"] call FLO_fnc_objectiveDevelopmentNotifySide;
["ECONOMY", 2, format ["%1 completed development level %2", _objectiveId, _targetLevel]] call FLO_fnc_log;
true
