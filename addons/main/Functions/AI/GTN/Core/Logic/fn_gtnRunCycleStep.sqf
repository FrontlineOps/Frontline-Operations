/* Yield only between owned transactions, never during selection or order commit. */
params ["_commander", "_code", ["_arguments", []]];
private _perf = _commander get "_perf";
private _result = nil;
private _failure = [];
isNil {
    private _frame = diag_frameNo;
    if ((_perf get "cycleSliceFrame") != _frame) then {
        _perf set ["cycleSliceFrame", _frame];
        _perf set ["cycleSliceMs", 0];
    };
    private _started = diag_tickTime;
    try { _result = _arguments call _code } catch { _failure = [_exception] };
    private _workMs = (diag_tickTime - _started) * 1000;
    private _sliceMs = (_perf get "cycleSliceMs") + _workMs;
    _perf set ["cycleSliceMs", _sliceMs];
    _perf set ["cycleWorkMs", (_perf get "cycleWorkMs") + _workMs];
    _perf set ["cyclePeakFrameMs", (_perf get "cyclePeakFrameMs") max _sliceMs];
};
if (_failure isNotEqualTo []) then { throw (_failure select 0) };
// The budget is soft: an individual atomic transaction may exceed it.
if (canSuspend && {(_perf get "cycleSliceMs") >= ((_commander get "_config") get "cycleFrameBudgetMs")}) then {
    private _frame = diag_frameNo;
    waitUntil { uiSleep 0.001; diag_frameNo != _frame };
};
if (isNil "_result") exitWith { nil };
_result
