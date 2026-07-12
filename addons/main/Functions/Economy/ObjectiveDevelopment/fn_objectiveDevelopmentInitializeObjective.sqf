params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]]
];

if (_objectiveId == "") then { throw "Objective Development initialization requires an objective ID"; };
private _subtype = _objective get "subtype";
if !(_subtype in (FLO_ObjectiveDevelopmentConfig get "supportedObjectiveSubtypes")) then {
    throw format ["Objective %1 has unsupported Development subtype %2", _objectiveId, _subtype];
};

if (isNil {_objective get "objectiveDevelopmentSchemaVersion"}) then {
    private _legacyLevel = 0;
    if !(isNil {_objective get "developmentLevel"}) then {
        _legacyLevel = _objective get "developmentLevel";
    };
    if !(_legacyLevel isEqualType 0 && {_legacyLevel >= 0} && {_legacyLevel == floor _legacyLevel}) then {
        throw format ["Objective %1 has invalid legacy Development level %2", _objectiveId, _legacyLevel];
    };

    private _legacyProject = createHashMap;
    if !(isNil {_objective get "developmentProject"}) then {
        _legacyProject = _objective get "developmentProject";
    };
    if !(_legacyProject isEqualType createHashMap) then {
        throw format ["Objective %1 has invalid legacy Development project type %2", _objectiveId, typeName _legacyProject];
    };
    if ((keys _legacyProject) isNotEqualTo []) then {
        _legacyProject set ["branch", "REVENUE"];
        _legacyProject set ["pricingVersion", 1];
        _legacyProject set ["createdAtDateNum", _legacyProject get "startedAtDateNum"];
        _legacyProject set ["rawTreasuryCost", _legacyProject get "treasuryCost"];
        _legacyProject set ["discountApplied", 0];
        _legacyProject set ["reservationId", ""];
    };

    _objective set ["objectiveDevelopmentSchemaVersion", FLO_ObjectiveDevelopmentConfig get "schemaVersion"];
    _objective set ["revenueLevel", _legacyLevel];
    _objective set ["developmentLevel", 0];
    _objective set ["developmentProject", _legacyProject];
};

private _schemaVersion = _objective get "objectiveDevelopmentSchemaVersion";
if (_schemaVersion != (FLO_ObjectiveDevelopmentConfig get "schemaVersion")) then {
    throw format ["Objective %1 has unsupported Objective Development schema %2", _objectiveId, _schemaVersion];
};
{
    private _level = _objective get _x;
    if !(_level isEqualType 0 && {_level >= 0} && {_level == floor _level}) then {
        throw format ["Objective %1 has invalid %2 value %3", _objectiveId, _x, _level];
    };
} forEach ["revenueLevel", "developmentLevel"];
private _project = _objective get "developmentProject";
if !(_project isEqualType createHashMap) then {
    throw format ["Objective %1 has invalid Development project type %2", _objectiveId, typeName _project];
};
[_objectiveId, _objective, false] call FLO_fnc_objectiveDevelopmentValidateProject;

_objective
