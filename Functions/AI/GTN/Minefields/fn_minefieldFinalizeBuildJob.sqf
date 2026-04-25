/*
 * Function: FLO_fnc_minefieldFinalizeBuildJob
 * Author: Frontline Operations Development Group
 * Description:
 *   Finalizes one queued minefield build job, removes it from the queue, and
 *   cleans up any partially-created mine objects on failure.
 *
 * Arguments:
 * 0: Job ID <STRING>
 * 1: Reason <STRING>
 *
 * Return Value:
 * BOOL
 */

params [
    ["_jobId", ""],
    ["_reason", ""]
];

if (_jobId == "") exitWith { false };

private _state = FLO_MinefieldBuild;
private _jobs = _state get "jobs";
if !(_jobId in _jobs) exitWith { false };

private _job = _jobs get _jobId;
private _objectiveId = _job get "objectiveId";
private _queue = _state get "queue";
private _queueIndex = _queue find _jobId;
if (_queueIndex >= 0) then {
    _queue deleteAt _queueIndex;
};

private _objectiveIndex = _state get "objectiveIndex";
if (_objectiveId in _objectiveIndex) then {
    _objectiveIndex deleteAt _objectiveId;
};

private _metrics = _job get "metrics";
if (_reason == "") then {
    _reason = _metrics get "reason";
};
if (_reason == "") then {
    _reason = "CANCELED";
};

if !(_reason isEqualTo "PLACED") then {
    {
        if (isNull _x) then { continue };
        deleteVehicle _x;
    } forEach (_job get "mineObjects");
};

_metrics set ["reason", _reason];
_metrics set ["totalMs", (diag_tickTime - (_job get "startedAt")) * 1000];

if ((_metrics get "totalMs") > 25 || {_reason != "PLACED"}) then {
    diag_log format [
        "[FLO][PERF] GTN minefield job %1 objective=%2 reason=%3 slices=%4 packets=%5 planned=%6 affordable=%7 placed=%8 spent=%9 total=%10 | resolve=%11 packetBuild=%12 layout=%13 budget=%14 spawn=%15 commit=%16 roles[f=%17 r=%18 c=%19 b=%20] slots[direct=%21 fallback=%22] rejects[nosafe=%23 water=%24 defended=%25 foreign=%26 spacing=%27]",
        _job get "sideKey",
        _objectiveId,
        _reason,
        _job get "slices",
        _metrics get "packetCount",
        _metrics get "plannedMineCount",
        _metrics get "affordableMineCount",
        _metrics get "placedMineCount",
        _metrics get "spentResources",
        _metrics get "totalMs",
        _metrics get "resolveMs",
        _metrics get "packetBuildMs",
        _metrics get "layoutMs",
        _metrics get "budgetMs",
        _metrics get "spawnMs",
        _metrics get "commitMs",
        _metrics get "frontageBuildMs",
        _metrics get "roadBuildMs",
        _metrics get "coverBuildMs",
        _metrics get "bypassBuildMs",
        _metrics get "acceptedDirectSlots",
        _metrics get "acceptedFallbackSlots",
        _metrics get "rejectedNoSafePos",
        _metrics get "rejectedWater",
        _metrics get "rejectedDefendedObjective",
        _metrics get "rejectedForeignObjective",
        _metrics get "rejectedSpacing"
    ];
};

_jobs deleteAt _jobId;
_state set ["queue", _queue];
_state set ["objectiveIndex", _objectiveIndex];
_state set ["jobs", _jobs];

true
