/*
 * Function: FLO_fnc_virtualizationProcessGroupBatch
 */

params [
    "_groupIds",
    "_groups",
    "_activationDist",
    "_now",
    "_stats",
    "_perf"
];

private _totalGroups = count _groupIds;
private _batchSize = FLO_VirtUpdate get "batchSize";
private _batchStart = FLO_VirtUpdate get "currentBatchIndex";

if (_batchStart >= _totalGroups) then {
    _batchStart = 0;
    FLO_VirtUpdate set ["currentBatchIndex", 0];
};

private _batchEnd = (_batchStart + _batchSize - 1) min (_totalGroups - 1);
private _processed = 0;
private _due = 0;
private _tracePhaseSampling = FLO_Debug_Level >= 5;
_stats set ["lastBatchStart", _batchStart];
_stats set ["lastBatchEnd", _batchEnd];

for "_i" from _batchStart to _batchEnd do {
    private _groupId = _groupIds select _i;
    private _groupData = _groups get _groupId;
    _processed = _processed + 1;

    if (_now < (_groupData get "nextProcessAt")) then {
        _stats set ["scheduledSkipsTotal", (_stats get "scheduledSkipsTotal") + 1];
        _stats set ["scheduledSkipsThisBatch", (_stats get "scheduledSkipsThisBatch") + 1];
        continue;
    };

    _due = _due + 1;
    private _samplePhases = false;
    if (_tracePhaseSampling) then {
        private _sampleSequence = (_stats get "phaseSampleSequence") + 1;
        _stats set ["phaseSampleSequence", _sampleSequence];
        _samplePhases = (_sampleSequence mod 16) == 0;
    };

    private _groupStart = diag_tickTime;
    [_groupId, _groupData, _activationDist, _now, _samplePhases] call FLO_fnc_virtualizationProcessGroup;
    private _groupMs = (diag_tickTime - _groupStart) * 1000;

    if (_samplePhases) then {
        _stats set ["phaseSamplesTotal", (_stats get "phaseSamplesTotal") + 1];
        _stats set ["phaseSampleMsTotal", (_stats get "phaseSampleMsTotal") + _groupMs];
    };

    _stats set ["lastGroupProcessMs", _groupMs];
    if (_groupMs > (_stats get "peakGroupProcessMs")) then {
        _stats set ["peakGroupProcessMs", _groupMs];
    };

    if (_groupMs >= (_perf get "slowGroupThresholdMs") && {_now >= (_perf get "nextSlowGroupLogAt")}) then {
        _stats set ["slowGroupCount", (_stats get "slowGroupCount") + 1];
        _stats set ["lastSlowGroupId", _groupId];
        _stats set ["lastSlowGroupType", _groupData get "groupType"];
        _stats set ["lastSlowGroupMs", _groupMs];
        _perf set ["nextSlowGroupLogAt", _now + (_perf get "logCooldownSec")];
        diag_log format [
            "[FLO][PERF] Virtualization group %1 type=%2 active=%3 missionLock=%4 in %5 ms",
            _groupId,
            _groupData get "groupType",
            _groupData get "isActive",
            _groupData get "missionLock",
            _groupMs
        ];
    };

};

_stats set ["groupsProcessedThisBatch", _processed];
_stats set ["groupsProcessedTotal", (_stats get "groupsProcessedTotal") + _processed];
_stats set ["dueGroupsThisBatch", _due];
_stats set ["dueGroupsTotal", (_stats get "dueGroupsTotal") + _due];

private _nextBatch = _batchEnd + 1;
if (_nextBatch >= _totalGroups) then {
    FLO_VirtUpdate set ["currentBatchIndex", 0];
    _stats set ["cyclesRun", (_stats get "cyclesRun") + 1];
} else {
    FLO_VirtUpdate set ["currentBatchIndex", _nextBatch];
};

[_processed, _batchStart, _batchEnd, _totalGroups]
