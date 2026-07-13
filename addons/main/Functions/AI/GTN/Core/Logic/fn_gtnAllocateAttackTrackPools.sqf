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
private _director = _cmdr get "_campaignDirector";
private _assignmentCache = _cmdr get "_objectiveAssignmentCache";
private _attackGroupsByOperation = _assignmentCache get "attackGroupsByOperation";
private _trackExistingCounts = createHashMap;
private _trackGoals = createHashMap;

{
    private _track = _x;
    private _trackId = _track get "id";
    private _objectiveId = _track get "phaseObjectiveId";
    private _operationId = _track get "phaseOperationId";
    private _activeGroupIds = if (_operationId in _attackGroupsByOperation) then {
        +(_attackGroupsByOperation get _operationId)
    } else {
        []
    };
    private _decision = [_director, _cmdr, _operationId, _activeGroupIds] call FLO_fnc_campaignEvaluateAssaultWave;
    _track set ["groupPool", []];
    _track set ["assaultWaveDecision", _decision];
    private _existingCount = _decision get "activeCount";
    private _goal = _decision get "activeTarget";
    _trackExistingCounts set [_trackId, _existingCount];
    _trackGoals set [_trackId, _goal];
    if (_decision get "culminated") then { continue };

    _metrics set ["attackGoal", (_metrics get "attackGoal") max _goal];

    private _needed = _decision get "quota";
    _metrics set ["deficitCount", (_metrics get "deficitCount") + ((_goal - _existingCount) max 0)];
    if (_needed <= 0) then { continue };

    private _targetPosition = (FLO_Objectives get _objectiveId) get "position";
    private _approachSourcePos = _track get "frontSectorAnchorPos";
    if (count _approachSourcePos < 2) then {
        throw format ["Operation track %1 has no assault approach source anchor", _trackId];
    };
    private _formationIndex = FLO_FormationState get "groupToFormation";
    private _formations = FLO_FormationState get "formations";
    private _rankedCandidates = _remaining apply {
        private _groupPosition = (_groups get _x) get "position";
        private _formationId = format ["ZZZ_%1", _x];
        private _formationPosition = _groupPosition;
        if (_x in _formationIndex) then {
            _formationId = _formationIndex get _x;
            private _leadId = (_formations get _formationId) get "leadGroupId";
            if (_leadId in _groups) then { _formationPosition = (_groups get _leadId) get "position"; };
        };
        [
            _formationPosition distance2D _approachSourcePos,
            _formationId,
            _groupPosition distance2D _targetPosition,
            _x
        ]
    };
    _rankedCandidates sort true;

    if ((count _rankedCandidates) >= _needed) then {
        private _selectedIds = createHashMap;
        private _pool = [];
        for "_slot" from 0 to (_needed - 1) do {
            private _groupId = (_rankedCandidates select _slot) select 3;
            _pool pushBack _groupId;
            _selectedIds set [_groupId, true];
        };
        _track set ["groupPool", _pool];
        _remaining = _remaining select { !(_x in _selectedIds) };
    } else {
        _decision set ["status", "AWAITING_WAVE_MASS"];
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
