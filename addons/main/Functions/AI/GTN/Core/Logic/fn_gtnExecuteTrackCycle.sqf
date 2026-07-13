/*
 * Function: FLO_fnc_gtnExecuteTrackCycle
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Executes one GTN track for a single commander update slice.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 * 1: Track <HASHMAP>
 *
 * Return Value:
 * Metrics <HASHMAP>
 */

params [
    ["_cmdr", nil],
    ["_track", nil]
];

private _metrics = createHashMapFromArray [
    ["emptyPoolSkips", 0],
    ["phaseSkips", 0],
    ["planCalls", 0],
    ["plansCreated", 0],
    ["planTaskTotal", 0],
    ["planMs", 0],
    ["primitiveExecCalls", 0],
    ["primitiveExecMs", 0],
    ["primitiveFailures", 0],
    ["checkCalls", 0],
    ["checkMs", 0],
    ["syncSuccesses", 0],
    ["tasksExecuted", 0],
    ["plansCompleted", 0],
    ["plansFailed", 0],
    ["processedTrackId", ""]
];

if (isNil "_cmdr" || {isNil "_track"}) exitWith { _metrics };

private _executor = _cmdr get "_executor";
private _trackId = _track get "id";
private _planner = _track get "planner";
private _status = _track get "status";
private _goal = _track get "goal";
_metrics set ["processedTrackId", _trackId];

if (_status == "IDLE") then {
    if (_goal == "capture_priority_objective" && {(_track get "phase") != "assault"}) exitWith {
        _metrics set ["phaseSkips", 1];
        ["GTN", 4, format[
            "Track %1 phase=%2 objective=%3 - holding attack execution",
            _trackId,
            _track get "phase",
            _track get "phaseObjectiveId"
        ]] call FLO_fnc_log;
        _metrics
    };

    private _pool = _track get "groupPool";
    if (_pool isEqualTo []) exitWith {
        _metrics set ["emptyPoolSkips", 1];
        ["GTN", 4, format["Track %1 has no groups, skipping this cycle", _trackId]] call FLO_fnc_log;
        _metrics
    };

    _metrics set ["planCalls", 1];
    private _tPlan = diag_tickTime;
    private _planResult = _planner call ["_plan", [_goal, []]];
    _metrics set ["planMs", (diag_tickTime - _tPlan) * 1000];
    private _plan = if (isNil "_planResult") then { [] } else { _planResult };
    if (_plan isEqualTo []) exitWith {
        ["GTN", 4, format["Track %1: No plan for %2 (preconditions not met)", _trackId, _goal]] call FLO_fnc_log;
        _metrics
    };

    _metrics set ["plansCreated", 1];
    _metrics set ["planTaskTotal", count _plan];
    _track set ["status", "RUNNING"];
    _status = "RUNNING";
    ["GTN", 4, format["Track %1: Started plan for %2 (%3 tasks)", _trackId, _goal, count _plan]] call FLO_fnc_log;
};

if (_status != "RUNNING") exitWith { _metrics };

private _planStatus = _planner call ["_getPlanStatus", []];
switch (_planStatus) do {
    case "PENDING";
    case "RUNNING": {
        private _maxTasksPerCycle = (_cmdr get "_config") get "maxTrackTasksPerCycle";
        private _tasksThisCycle = 0;
        private _continueLoop = true;

        while {_continueLoop && {_tasksThisCycle < _maxTasksPerCycle}} do {
            private _currentStatus = _planner call ["_getPlanStatus", []];

            if (_currentStatus in ["PENDING", "RUNNING"]) then {
                private _currentTask = _planner call ["_getCurrentTask", []];

                if (!isNil "_currentTask") then {
                    _currentTask set ["_trackRef", _track];

                    if (_currentStatus == "PENDING") then {
                        private _taskId = _currentTask get "taskId";
                        _executor call ["_setActiveTrack", [_currentTask]];
                        ["GTN", 5, format["Track %1: Executing %2", _trackId, _taskId]] call FLO_fnc_log;

                        _metrics set ["primitiveExecCalls", (_metrics get "primitiveExecCalls") + 1];
                        private _tExec = diag_tickTime;
                        private _result = _executor call ["_executePrimitive", [_currentTask]];
                        _metrics set ["primitiveExecMs", (_metrics get "primitiveExecMs") + ((diag_tickTime - _tExec) * 1000)];
                        if (_result) then {
                            _planner call ["_executeNext", []];
                            private _stats = _cmdr get "_stats";
                            _stats set ["tasksExecuted", (_stats get "tasksExecuted") + 1];
                            _metrics set ["tasksExecuted", (_metrics get "tasksExecuted") + 1];
                            _tasksThisCycle = _tasksThisCycle + 1;

                            _metrics set ["checkCalls", (_metrics get "checkCalls") + 1];
                            private _tCheck = diag_tickTime;
                            if (_planner call ["_checkCurrentTask", [_executor]]) then {
                                _metrics set ["checkMs", (_metrics get "checkMs") + ((diag_tickTime - _tCheck) * 1000)];
                                private _taskStatus = _currentTask get "status";
                                if (_taskStatus == "SUCCESS") then {
                                    _metrics set ["syncSuccesses", (_metrics get "syncSuccesses") + 1];
                                    ["GTN", 4, format["Track %1: Task %2 completed synchronously", _trackId, _taskId]] call FLO_fnc_log;
                                    private _nextTask = _planner call ["_getCurrentTask", []];
                                    _planner set ["_planStatus", if (isNil "_nextTask") then { "SUCCESS" } else { "PENDING" }];
                                } else {
                                    ["GTN", 2, format["Track %1: Task %2 failed during sync check", _trackId, _taskId]] call FLO_fnc_log;
                                    _planner set ["_planStatus", "FAILED"];
                                    _continueLoop = false;
                                };
                            } else {
                                _metrics set ["checkMs", (_metrics get "checkMs") + ((diag_tickTime - _tCheck) * 1000)];
                                _continueLoop = false;
                            };
                        } else {
                            _metrics set ["primitiveFailures", (_metrics get "primitiveFailures") + 1];
                            ["GTN", 2, format["Track %1: Primitive %2 failed", _trackId, _taskId]] call FLO_fnc_log;
                            _planner set ["_planStatus", "FAILED"];
                            _continueLoop = false;
                        };
                    } else {
                        _executor call ["_setActiveTrack", [_currentTask]];
                        _metrics set ["checkCalls", (_metrics get "checkCalls") + 1];
                        private _tCheck = diag_tickTime;
                        if (_planner call ["_checkCurrentTask", [_executor]]) then {
                            _metrics set ["checkMs", (_metrics get "checkMs") + ((diag_tickTime - _tCheck) * 1000)];
                            private _taskStatus = _currentTask get "status";
                            if (_taskStatus == "SUCCESS") then {
                                private _nextTask = _planner call ["_getCurrentTask", []];
                                _planner set ["_planStatus", if (isNil "_nextTask") then { "SUCCESS" } else { "PENDING" }];
                            } else {
                                _planner set ["_planStatus", "FAILED"];
                                _continueLoop = false;
                            };
                        } else {
                            _metrics set ["checkMs", (_metrics get "checkMs") + ((diag_tickTime - _tCheck) * 1000)];
                            _continueLoop = false;
                        };
                    };
                } else {
                    _continueLoop = false;
                };
            } else {
                _continueLoop = false;
            };
        };
    };

    case "SUCCESS": {
        _metrics set ["plansCompleted", 1];
        ["GTN", 4, format["Track %1: Plan completed successfully", _trackId]] call FLO_fnc_log;
        _track set ["status", "IDLE"];
    };

    case "FAILED": {
        _metrics set ["plansFailed", 1];
        ["GTN", 2, format["Track %1: Plan failed, will retry next cycle", _trackId]] call FLO_fnc_log;
        _track set ["status", "IDLE"];
    };
};

_metrics
