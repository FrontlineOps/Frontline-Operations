/*
 * Function: FLO_fnc_minefieldBuildQueueRun
 * Author: Frontline Operations Development Group
 * Description:
 *   Budgeted PFH worker for staged minefield build jobs.
 *
 * Arguments: None
 *
 * Return Value:
 * BOOL
 */

if (!isServer) exitWith { false };
if (isNil "FLO_MinefieldBuild") exitWith { false };

private _state = FLO_MinefieldBuild;
private _sliceBudgetMs = (_state get "sliceBudgetMs") max 1;
private _sliceStart = diag_tickTime;

while {count (_state get "queue") > 0 && {((diag_tickTime - _sliceStart) * 1000) < _sliceBudgetMs}} do {
    private _queue = _state get "queue";
    private _jobId = _queue deleteAt 0;
    private _status = [_jobId] call FLO_fnc_minefieldBuildJobStep;

    if (_status == "requeue" && {_jobId in (_state get "jobs")}) then {
        _queue pushBack _jobId;
    };

    _state set ["queue", _queue];
};

true
