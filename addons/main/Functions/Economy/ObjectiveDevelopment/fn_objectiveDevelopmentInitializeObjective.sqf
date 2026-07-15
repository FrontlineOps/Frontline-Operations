params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]]
];

if (_objectiveId == "") then { throw "Objective Development initialization requires an objective ID"; };
private _subtype = _objective get "subtype";
if !(_subtype in (FLO_ObjectiveDevelopmentConfig get "supportedObjectiveSubtypes")) then {
    throw format ["Objective %1 has unsupported Development subtype %2", _objectiveId, _subtype];
};

private _restoring = FLO_IsLoadedSave;
private _requiredFields = ["revenueLevel", "developmentLevel", "developmentProject"];
private _validationError = "";

try {
    private _missingFields = _requiredFields select { !(_x in _objective) };
    if (_missingFields isNotEqualTo []) then {
        private _hasDevelopmentState = ({ _x in _objective } count _requiredFields) > 0;
        if (_restoring || {_hasDevelopmentState}) then {
            throw format ["Objective %1 is missing Development fields %2", _objectiveId, _missingFields];
        };
        _objective set ["revenueLevel", 0];
        _objective set ["developmentLevel", 0];
        _objective set ["developmentProject", createHashMap];
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
} catch {
    _validationError = _exception;
};

if (_validationError != "") then {
    private _severity = [1, 2] select _restoring;
    private _context = ["state is invalid", "saved state was refused"] select _restoring;
    ["ECONOMY", _severity, format ["Objective Development %1 at %2: %3", _context, _objectiveId, _validationError]] call FLO_fnc_log;
    throw _validationError;
};

_objective
