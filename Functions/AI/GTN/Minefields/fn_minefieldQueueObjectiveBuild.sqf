/*
 * Function: FLO_fnc_minefieldQueueObjectiveBuild
 * Author: Frontline Operations Development Group
 * Description:
 *   Queues one ranked objective seed for staged minefield construction.
 *
 * Arguments:
 * 0: Candidate seed <HASHMAP>
 *
 * Return Value:
 * HASHMAP
 */

params [["_seed", createHashMap]];

private _result = createHashMapFromArray [
    ["queued", false],
    ["jobId", ""],
    ["objectiveId", ""],
    ["reason", ""]
];

if (!isServer) exitWith { _result };
if !(_seed isEqualType createHashMap) exitWith { _result };
if ((count (keys _seed)) == 0) exitWith { _result };

private _objectiveId = _seed get "objectiveId";
_result set ["objectiveId", _objectiveId];

if (_objectiveId in FLO_MinefieldObjectiveIndex) exitWith {
    _result set ["reason", "ALREADY_EXISTS"];
    _result
};

private _state = FLO_MinefieldBuild;
private _objectiveIndex = _state get "objectiveIndex";
if (_objectiveId in _objectiveIndex) exitWith {
    _result set ["reason", "ALREADY_QUEUED"];
    _result
};

private _job = [_seed] call FLO_fnc_minefieldBuildJobCreate;
if ((count (keys _job)) == 0) exitWith {
    _result set ["reason", "NO_JOB"];
    _result
};

private _jobId = _job get "id";
private _jobs = _state get "jobs";
private _queue = _state get "queue";

_jobs set [_jobId, _job];
_objectiveIndex set [_objectiveId, _jobId];
_queue pushBack _jobId;
_state set ["jobs", _jobs];
_state set ["objectiveIndex", _objectiveIndex];
_state set ["queue", _queue];

_result set ["queued", true];
_result set ["jobId", _jobId];
_result
