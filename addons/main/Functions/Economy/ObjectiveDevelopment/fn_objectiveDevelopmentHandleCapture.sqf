params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]],
    ["_previousOwner", sideUnknown, [west]],
    ["_newOwner", sideUnknown, [west]]
];

private _project = _objective get "developmentProject";
private _projectCancelled = (keys _project) isNotEqualTo [];
private _previousLevel = _objective get "developmentLevel";
private _nextLevel = ((_objective get "developmentLevel") - 1) max 0;
_objective set ["developmentLevel", _nextLevel];
_objective set ["developmentProject", createHashMap];

if (_projectCancelled && {_previousOwner in [west, east]}) then {
    [_previousOwner, format ["Development at %1 was lost during the capture.", [_objectiveId] call FLO_fnc_campaignObjectiveName], "warning"] call FLO_fnc_objectiveDevelopmentNotifySide;
};
if (_previousLevel != _nextLevel || {_projectCancelled}) then {
    ["ECONOMY", 2, format [
        "Objective %1 capture %2->%3 cancelledProject=%4 development=%5->%6",
        _objectiveId,
        _previousOwner,
        _newOwner,
        _projectCancelled,
        _previousLevel,
        _nextLevel
    ]] call FLO_fnc_log;
};

_objective
