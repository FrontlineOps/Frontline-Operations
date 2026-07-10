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
    ["stagedTrackCount", 0],
    ["stagingFloor", 0],
    ["remainingCount", count _candidateGroupIds]
];
if (isNil "_cmdr" || {_attackTracks isEqualTo []} || {_candidateGroupIds isEqualTo []}) exitWith { _metrics };

private _activeTracks = _attackTracks select {
    (_x get "phase") in ["staging", "assault"]
    && {(_x get "phaseOperationId") != ""}
    && {(_x get "phaseObjectiveId") != ""}
};
if (_activeTracks isEqualTo []) exitWith { _metrics };

private _config = _cmdr get "_config";
private _mainFloor = (_config get "attackLaneStagingMinGroups") max 1;
private _supportFloor = (_config get "attackLaneSupportStagingMinGroups") max 1;
_metrics set ["stagingFloor", _mainFloor];
_metrics set ["viableTrackCount", count _activeTracks];
_metrics set ["meaningfulTrackCount", count _activeTracks];

private _groups = FLO_virtualGroups get "_groups";
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
    private _goal = [_supportFloor, _mainFloor] select ((_track get "phaseRole") == "MAIN_EFFORT");
    _track set ["groupPool", []];
    _track set ["phaseStagingGoal", _goal];
    _trackExistingCounts set [_trackId, _existingCount];
    _trackGoals set [_trackId, _goal];

    private _needed = (_goal - _existingCount) max 0;
    private _targetPosition = (FLO_Objectives get _objectiveId) get "position";
    for "_slot" from 1 to _needed do {
        if (_remaining isEqualTo []) exitWith {};
        private _nearestIndex = -1;
        private _nearestDistance = 1e12;
        {
            private _distance = ((_groups get _x) get "position") distance2D _targetPosition;
            if (_distance < _nearestDistance) then {
                _nearestIndex = _forEachIndex;
                _nearestDistance = _distance;
            };
        } forEach _remaining;
        if (_nearestIndex < 0) exitWith {};
        private _pool = _track get "groupPool";
        _pool pushBack (_remaining deleteAt _nearestIndex);
        _track set ["groupPool", _pool];
    };
} forEach _activeTracks;

while {_remaining isNotEqualTo []} do {
    private _groupId = _remaining deleteAt 0;
    private _groupPosition = (_groups get _groupId) get "position";
    private _bestTrack = _activeTracks select 0;
    private _bestLoad = 1e12;
    private _bestDistance = 1e12;
    {
        private _track = _x;
        private _trackId = _track get "id";
        private _assignedTotal = (_trackExistingCounts get _trackId) + count (_track get "groupPool");
        private _relativeLoad = _assignedTotal / (_trackGoals get _trackId);
        private _targetPosition = (FLO_Objectives get (_track get "phaseObjectiveId")) get "position";
        private _distance = _groupPosition distance2D _targetPosition;
        if (_relativeLoad < _bestLoad || {_relativeLoad == _bestLoad && {_distance < _bestDistance}}) then {
            _bestTrack = _track;
            _bestLoad = _relativeLoad;
            _bestDistance = _distance;
        };
    } forEach _activeTracks;
    private _pool = _bestTrack get "groupPool";
    _pool pushBack _groupId;
    _bestTrack set ["groupPool", _pool];
};

{
    private _track = _x;
    private _trackId = _track get "id";
    private _poolCount = count (_track get "groupPool");
    private _totalCount = (_trackExistingCounts get _trackId) + _poolCount;
    _metrics set ["assignedCount", (_metrics get "assignedCount") + _poolCount];
    if (_poolCount > 0) then {
        _metrics set ["seededTrackCount", (_metrics get "seededTrackCount") + 1];
    };
    if (_totalCount >= (_trackGoals get _trackId)) then {
        _metrics set ["stagedTrackCount", (_metrics get "stagedTrackCount") + 1];
    };
} forEach _activeTracks;
_metrics set ["remainingCount", 0];

["GTN", 3, format [
    "Attack pool allocation: candidates=%1 tracks=%2 assigned=%3 staged=%4",
    _metrics get "candidateCount",
    count _activeTracks,
    _metrics get "assignedCount",
    _metrics get "stagedTrackCount"
]] call FLO_fnc_log;
_metrics
