params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]]
];

if (_objectiveId == "") then { throw "Objective development initialization requires an objective ID"; };
private _subtype = _objective get "subtype";
private _maxLevels = FLO_ObjectiveDevelopmentConfig get "maxLevelBySubtype";
if !(_subtype in _maxLevels) then {
    throw format ["Objective %1 has unsupported development subtype %2", _objectiveId, _subtype];
};

if (isNil {_objective get "developmentLevel"}) then {
    _objective set ["developmentLevel", 0];
};
if (isNil {_objective get "developmentProject"}) then {
    _objective set ["developmentProject", createHashMap];
};

private _level = _objective get "developmentLevel";
private _maxLevel = _maxLevels get _subtype;
if !(_level isEqualType 0 && {_level >= 0} && {_level <= _maxLevel} && {floor _level == _level}) then {
    throw format ["Objective %1 has invalid development level %2 for %3", _objectiveId, _level, _subtype];
};
private _project = _objective get "developmentProject";
if !(_project isEqualType createHashMap) then {
    throw format ["Objective %1 has invalid development project type %2", _objectiveId, typeName _project];
};
[_objectiveId, _objective] call FLO_fnc_objectiveDevelopmentValidateProject;

_objective
