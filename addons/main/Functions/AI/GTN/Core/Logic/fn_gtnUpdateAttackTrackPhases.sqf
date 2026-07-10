/* Projects ordered campaign operations onto the commander's attack tracks. */
params ["_cmdr"];

private _metrics = createHashMapFromArray [
    ["trackCount", 0],
    ["quietCount", 0],
    ["stagingCount", 0],
    ["assaultCount", 0],
    ["spentCount", 0],
    ["transitionCount", 0],
    ["selectedObjectiveCount", 0],
    ["currentTotalGroups", 0],
    ["baselineTotalGroups", 0],
    ["theaterStrengthRatio", 1],
    ["posture", "normal"]
];

private _director = _cmdr get "_campaignDirector";
if (isNil "_director") then {
    throw "FLO_fnc_gtnUpdateAttackTrackPhases: commander has no campaign director";
};

private _tracks = (_cmdr get "_tracks") select { (_x get "goal") == "capture_priority_objective" };
_metrics set ["trackCount", count _tracks];
if (_tracks isEqualTo []) exitWith { _metrics };

private _state = _director call ["_getState", []];
private _operations = _state get "operations";
private _sideKey = _cmdr get "_sideKey";
private _operationIds = (_state get "operationOrder") select {
    ((_operations get _x) get "attackerSideKey") == _sideKey
};

{
    private _track = _x;
    private _desiredOperationId = "";
    private _desiredObjectiveId = "";
    private _desiredRole = "";
    private _desiredPhase = "quiet";

    if (_forEachIndex < count _operationIds) then {
        _desiredOperationId = _operationIds select _forEachIndex;
        private _operation = _operations get _desiredOperationId;
        _desiredObjectiveId = _operation get "objectiveId";
        _desiredRole = _operation get "priorityRole";
        _desiredPhase = switch (_operation get "phase") do {
            case "PREPARE": { "staging" };
            case "ASSAULT": { "assault" };
            default { "spent" };
        };
    };

    private _bindingChanged = (_track get "phaseOperationId") != _desiredOperationId
        || {(_track get "phaseObjectiveId") != _desiredObjectiveId};
    private _phaseChanged = (_track get "phase") != _desiredPhase;
    if (_bindingChanged || {_phaseChanged}) then {
        _track set ["phase", _desiredPhase];
        _track set ["phaseChangedAt", diag_tickTime];
        _track set ["phaseUntil", 0];
        _track set ["phaseOperationId", _desiredOperationId];
        _track set ["phaseObjectiveId", _desiredObjectiveId];
        _track set ["phaseRole", _desiredRole];
        _track set ["phaseStagingGoal", 0];
        _track set ["status", "IDLE"];
        _metrics set ["transitionCount", (_metrics get "transitionCount") + 1];
    };

    private _countKey = format ["%1Count", _desiredPhase];
    _metrics set [_countKey, (_metrics get _countKey) + 1];
    if (_desiredObjectiveId != "") then {
        _metrics set ["selectedObjectiveCount", (_metrics get "selectedObjectiveCount") + 1];
    };
} forEach _tracks;

_metrics
