params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]]
];

[_objectiveId, _objective, true] call FLO_fnc_objectiveDevelopmentValidateProject;
private _project = _objective get "developmentProject";
if ((keys _project) isEqualTo []) then { throw format ["Objective %1 has no Development project to complete", _objectiveId]; };
if ((_project get "state") == "FUNDING") then { throw format ["Objective %1 cannot complete an unfunded project", _objectiveId]; };
if ((_project get "supplyDelivered") < (_project get "supplyRequired")) then {
    throw format ["Objective %1 Development completed before its supply requirement", _objectiveId];
};

private _targetLevel = _project get "targetLevel";
private _branch = _project get "branch";
if (_branch == "REVENUE") then {
    _objective set ["revenueLevel", _targetLevel];
} else {
    _objective set ["developmentLevel", _targetLevel];
};
_objective set ["developmentProject", createHashMap];
FLO_Objectives set [_objectiveId, _objective];

private _side = _objective get "owner";
private _objectiveName = [_objectiveId] call FLO_fnc_campaignObjectiveName;
private _effect = if (_branch == "REVENUE") then {
    format ["income multiplier is now %1x", [_targetLevel] call FLO_fnc_objectiveDevelopmentRevenueMultiplier]
} else {
    format [
        "local project discount is now %1 percent and side capacity is %2",
        round (([_targetLevel] call FLO_fnc_objectiveDevelopmentDiscount) * 100),
        [_side] call FLO_fnc_objectiveDevelopmentGetProjectCapacity
    ]
};
[_side, format [
    "%1 level %2 completed at %3: %4.",
    _branch,
    _targetLevel,
    _objectiveName,
    _effect
], "success"] call FLO_fnc_objectiveDevelopmentNotifySide;
["ECONOMY", 2, format ["%1 completed %2 level %3", _objectiveId, _branch, _targetLevel]] call FLO_fnc_log;
true
