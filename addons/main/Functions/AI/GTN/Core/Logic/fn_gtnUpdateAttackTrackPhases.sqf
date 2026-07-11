/* Projects ordered campaign operations onto the commander's attack tracks. */
params ["_cmdr"];

private _metrics = createHashMapFromArray [
    ["trackCount", 0],
    ["quietCount", 0],
    ["prepareCount", 0],
    ["assaultCount", 0],
    ["spentCount", 0],
    ["transitionCount", 0],
    ["selectedObjectiveCount", 0],
    ["currentTotalGroups", 0],
    ["baselineTotalGroups", 0],
    ["theaterStrengthRatio", 1],
    ["posture", "normal"],
    ["attackGroupCount", 0],
    ["arrivedGroupCount", 0],
    ["activeAttackGroupCount", 0],
    ["deferredAttackGroupCount", 0],
    ["nearestAttackMeters", -1],
    ["farthestAttackMeters", -1]
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
private _config = _cmdr get "_config";

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
            case "PREPARE": { "prepare" };
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
        _track set ["status", "IDLE"];
        _metrics set ["transitionCount", (_metrics get "transitionCount") + 1];
    };

    private _countKey = format ["%1Count", _desiredPhase];
    _metrics set [_countKey, (_metrics get _countKey) + 1];
    if (_desiredObjectiveId != "") then {
        _metrics set ["selectedObjectiveCount", (_metrics get "selectedObjectiveCount") + 1];
        if (_desiredPhase == "assault") then {
            private _goal = (_operations get _desiredOperationId) get "assaultActiveTarget";
            _metrics set ["baselineTotalGroups", (_metrics get "baselineTotalGroups") + _goal];
        };
    };
} forEach _tracks;

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _ownSide = _cmdr get "_ownSide";
private _assignmentCache = _cmdr get "_objectiveAssignmentCache";
private _operationGroupIds = +(_assignmentCache get "attackGroupIds");
private _attackCount = 0;
private _arrivedCount = 0;
private _activeCount = 0;
private _deferredCount = 0;
private _nearestDistance = 1e12;
private _farthestDistance = -1;
{
    private _groupData = _groups get _x;
    if (isNil "_groupData") then { continue };
    if ((_groupData get "side") isNotEqualTo _ownSide) then { continue };
    private _operationId = _groupData get "campaignOperationId";
    if !(_operationId in _operationIds) then { continue };

    if ((_groupData get "commanderOrder") != "ATTACK") then { continue };

    _attackCount = _attackCount + 1;
    if (_groupData get "isActive") then { _activeCount = _activeCount + 1; };
    if (_groupData get "activationDeferred") then { _deferredCount = _deferredCount + 1; };

    private _objectiveId = _groupData get "attackObjective";
    if !(_objectiveId in FLO_Objectives) then { continue };
    private _objective = FLO_Objectives get _objectiveId;
    private _distance = (_groupData get "position") distance2D (_objective get "position");
    _nearestDistance = _nearestDistance min _distance;
    _farthestDistance = _farthestDistance max _distance;
    if (_distance <= (_objective get "radius")) then {
        _arrivedCount = _arrivedCount + 1;
    };
} forEach _operationGroupIds;

private _desiredTotal = _metrics get "baselineTotalGroups";
private _strengthRatio = if (_desiredTotal > 0) then { _attackCount / _desiredTotal } else { 1 };
private _posture = "normal";
if (_strengthRatio < (_config get "attackLaneExhaustedStrengthRatio")) then {
    _posture = "exhausted";
} else {
    if (_strengthRatio < (_config get "attackLaneCautiousStrengthRatio")) then {
        _posture = "cautious";
    };
};

_metrics set ["currentTotalGroups", _attackCount];
_metrics set ["theaterStrengthRatio", _strengthRatio];
_metrics set ["posture", _posture];
_metrics set ["attackGroupCount", _attackCount];
_metrics set ["arrivedGroupCount", _arrivedCount];
_metrics set ["activeAttackGroupCount", _activeCount];
_metrics set ["deferredAttackGroupCount", _deferredCount];
if (_attackCount > 0) then {
    _metrics set ["nearestAttackMeters", round _nearestDistance];
    _metrics set ["farthestAttackMeters", round _farthestDistance];
};

_metrics
