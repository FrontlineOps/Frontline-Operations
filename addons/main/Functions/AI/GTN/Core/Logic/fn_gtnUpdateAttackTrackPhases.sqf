/* Reconciles one runtime attack track per ordered campaign operation. */
params ["_cmdr"];

private _metrics = createHashMapFromArray [
    ["trackCount", 0],
    ["createdTrackCount", 0],
    ["removedTrackCount", 0],
    ["quietCount", 0],
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

private _state = _director call ["_getState", []];
private _operations = _state get "operations";
private _sideKey = _cmdr get "_sideKey";
private _operationIds = (_state get "operationOrder") select {
    ((_operations get _x) get "attackerSideKey") == _sideKey
};

private _allTracks = _cmdr get "_tracks";
private _defenseTracks = _allTracks select { (_x get "goal") == "protect_critical_assets" };
if ((count _defenseTracks) != 1) then {
    throw format ["Commander %1 has %2 defense tracks", _sideKey, count _defenseTracks];
};
private _existingAttackTracks = _allTracks select { (_x get "goal") == "capture_priority_objective" };
private _existingByOperation = createHashMap;
{
    private _operationId = _x get "phaseOperationId";
    if (_operationId == "") then { continue };
    if (_operationId in _existingByOperation) then {
        throw format ["Commander %1 has duplicate attack tracks for operation %2", _sideKey, _operationId];
    };
    _existingByOperation set [_operationId, _x];
} forEach _existingAttackTracks;

private _attackTracks = [];
private _reusedCount = 0;
private _createdCount = 0;
{
    private _track = if (_x in _existingByOperation) then {
        _reusedCount = _reusedCount + 1;
        _existingByOperation get _x
    } else {
        _createdCount = _createdCount + 1;
        [_cmdr, _x] call FLO_fnc_gtnCreateAttackTrack
    };
    _attackTracks pushBack _track;
} forEach _operationIds;
private _removedCount = (count _existingAttackTracks) - _reusedCount;

private _defenseShare = 0;
{ _defenseShare = _defenseShare + (_x get "resourceShare"); } forEach _defenseTracks;
private _attackShare = if (_attackTracks isEqualTo []) then { 0 } else {
    ((1 - _defenseShare) max 0) / (count _attackTracks)
};
{ _x set ["resourceShare", _attackShare]; } forEach _attackTracks;

private _tracks = _attackTracks + _defenseTracks;
_cmdr set ["_tracks", _tracks];
private _executionCursor = _cmdr get "_nextTrackExecutionIndex";
_cmdr set ["_nextTrackExecutionIndex", if (_tracks isEqualTo []) then { 0 } else { _executionCursor mod (count _tracks) }];
private _allocationCursor = _cmdr get "_nextAttackAllocationIndex";
_cmdr set ["_nextAttackAllocationIndex", if (_attackTracks isEqualTo []) then { 0 } else { _allocationCursor mod (count _attackTracks) }];

_metrics set ["trackCount", count _attackTracks];
_metrics set ["createdTrackCount", _createdCount];
_metrics set ["removedTrackCount", _removedCount];
if (_createdCount > 0 || {_removedCount > 0}) then {
    ["GTN", 4, format [
        "Reconciled %1 attack tracks: active=%2 created=%3 removed=%4",
        _sideKey,
        count _attackTracks,
        _createdCount,
        _removedCount
    ]] call FLO_fnc_log;
};

{
    private _track = _x;
    private _operationId = _operationIds select _forEachIndex;
    private _operation = _operations get _operationId;
    private _desiredObjectiveId = _operation get "objectiveId";
    private _desiredRole = _operation get "priorityRole";
    private _desiredPhase = switch (_operation get "phase") do {
        case "ASSAULT": { "assault" };
        default { "spent" };
    };

    private _bindingChanged = (_track get "phaseOperationId") != _operationId
        || {(_track get "phaseObjectiveId") != _desiredObjectiveId};
    private _phaseChanged = (_track get "phase") != _desiredPhase;
    private _roleChanged = (_track get "phaseRole") != _desiredRole;
    if (_bindingChanged || {_phaseChanged}) then {
        _track set ["phase", _desiredPhase];
        _track set ["phaseChangedAt", diag_tickTime];
        _track set ["phaseUntil", 0];
        _track set ["phaseOperationId", _operationId];
        _track set ["phaseObjectiveId", _desiredObjectiveId];
        _track set ["phaseRole", _desiredRole];
        _track set ["status", "IDLE"];
        _track set ["groupPool", []];
        _metrics set ["transitionCount", (_metrics get "transitionCount") + 1];
    } else {
        if (_roleChanged) then {
            _track set ["phaseRole", _desiredRole];
            _metrics set ["transitionCount", (_metrics get "transitionCount") + 1];
        };
    };

    private _countKey = format ["%1Count", _desiredPhase];
    _metrics set [_countKey, (_metrics get _countKey) + 1];
    _metrics set ["selectedObjectiveCount", (_metrics get "selectedObjectiveCount") + 1];
    if (_desiredPhase == "assault") then {
        _metrics set [
            "baselineTotalGroups",
            (_metrics get "baselineTotalGroups") + (_operation get "assaultActiveTarget")
        ];
    };
} forEach _attackTracks;

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
private _config = _cmdr get "_config";
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
