/* Distributes the offensive reserve across bound operation tracks. */
params [
    ["_cmdr", nil],
    ["_attackTracks", [], [[]]],
    ["_candidateGroupIds", [], [[]]]
];

private _metrics = createHashMapFromArray [
    ["candidateCount", count _candidateGroupIds],
    ["assignedCount", 0],
    ["viableTrackCount", 0],
    ["meaningfulTrackCount", 0],
    ["seededTrackCount", 0],
    ["readyTrackCount", 0],
    ["attackGoal", 0],
    ["deficitCount", 0],
    ["remainingCount", count _candidateGroupIds]
];
if (isNil "_cmdr" || {_attackTracks isEqualTo []}) exitWith { _metrics };

private _activeTracks = _attackTracks select {
    (_x get "phase") == "assault"
    && {(_x get "phaseOperationId") != ""}
    && {(_x get "phaseObjectiveId") != ""}
};
if (_activeTracks isEqualTo []) exitWith { _metrics };

_metrics set ["viableTrackCount", count _activeTracks];
_metrics set ["meaningfulTrackCount", count _activeTracks];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _remaining = _candidateGroupIds select { _x in _groups };
private _activeAttackCounts = (_cmdr get "_objectiveAssignmentCache") get "attackCounts";
private _trackExistingCounts = createHashMap;
private _trackGoals = createHashMap;

{
    private _track = _x;
    private _trackId = _track get "id";
    private _objectiveId = _track get "phaseObjectiveId";
    private _existingCount = if (_objectiveId in _activeAttackCounts) then {
        _activeAttackCounts get _objectiveId
    } else {
        0
    };
    private _goal = _cmdr call ["_getAttackCapForObjective", [_objectiveId]];
    _track set ["groupPool", []];
    _trackExistingCounts set [_trackId, _existingCount];
    _trackGoals set [_trackId, _goal];
    _metrics set ["attackGoal", (_metrics get "attackGoal") max _goal];

    private _needed = (_goal - _existingCount) max 0;
    _metrics set ["deficitCount", (_metrics get "deficitCount") + _needed];
    private _targetPosition = (FLO_Objectives get _objectiveId) get "position";
    private _rankedCandidates = _remaining apply {
        [((_groups get _x) get "position") distance2D _targetPosition, _x]
    };
    _rankedCandidates sort true;

    private _takeCount = _needed min (count _rankedCandidates);
    if (_takeCount > 0) then {
        private _selectedIds = createHashMap;
        private _pool = [];
        for "_slot" from 0 to (_takeCount - 1) do {
            private _groupId = (_rankedCandidates select _slot) select 1;
            _pool pushBack _groupId;
            _selectedIds set [_groupId, true];
        };
        _track set ["groupPool", _pool];
        _remaining = _remaining select { !(_x in _selectedIds) };
    };
} forEach _activeTracks;

{
    private _track = _x;
    private _trackId = _track get "id";
    private _poolCount = count (_track get "groupPool");
    private _totalCount = (_trackExistingCounts get _trackId) + _poolCount;
    _metrics set ["assignedCount", (_metrics get "assignedCount") + _poolCount];
    if (_poolCount > 0) then {
        _metrics set ["seededTrackCount", (_metrics get "seededTrackCount") + 1];
    };
    if ((_trackGoals get _trackId) > 0 && {_totalCount >= (_trackGoals get _trackId)}) then {
        _metrics set ["readyTrackCount", (_metrics get "readyTrackCount") + 1];
    };
} forEach _activeTracks;
_metrics set ["remainingCount", count _remaining];

["GTN", 3, format [
    "Assault pool allocation: candidates=%1 tracks=%2 deficit=%3 pooled=%4 ready=%5",
    _metrics get "candidateCount",
    count _activeTracks,
    _metrics get "deficitCount",
    _metrics get "assignedCount",
    _metrics get "readyTrackCount"
]] call FLO_fnc_log;
_metrics
