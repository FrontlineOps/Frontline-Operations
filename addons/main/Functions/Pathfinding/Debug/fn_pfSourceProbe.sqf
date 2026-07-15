private _emitSorted = {
    params ["_map"];

    private _pairs = [];
    {
        _pairs pushBack [(_map get _x), _x];
    } forEach (keys _map);
    _pairs sort false;
    _pairs apply { [_x select 1, _x select 0] }
};

private _emitAverage = {
    params ["_totalMap", "_countMap"];

    private _pairs = [];
    {
        private _count = _countMap getOrDefault [_x, 0];
        private _avg = if (_count > 0) then { (_totalMap get _x) / _count } else { 0 };
        _pairs pushBack [_avg, _x];
    } forEach (keys _countMap);
    _pairs sort false;
    _pairs apply { [_x select 1, _x select 0] }
};

private _sourceStats = FLO_PF_SourceStats;

[
    ["attempts", [(_sourceStats get "attempts")] call _emitSorted],
    ["newSearch", [(_sourceStats get "newSearch")] call _emitSorted],
    ["cacheHit", [(_sourceStats get "cacheHit")] call _emitSorted],
    ["completedSuccess", [(_sourceStats get "completedSuccess")] call _emitSorted],
    ["completedPartial", [(_sourceStats get "completedPartial")] call _emitSorted],
    ["resolvedCount", [(_sourceStats get "resolvedCount")] call _emitSorted],
    ["resolvedNodeStepsLast", [(_sourceStats get "resolvedNodeStepsLast")] call _emitSorted],
    ["resolvedNodeStepsAvg", [(_sourceStats get "resolvedNodeStepsTotal"), (_sourceStats get "resolvedCount")] call _emitAverage],
    ["resolvedNodeStepsPeak", [(_sourceStats get "resolvedNodeStepsPeak")] call _emitSorted],
    ["resolvedMsLast", [(_sourceStats get "resolvedMsLast")] call _emitSorted],
    ["resolvedMsAvg", [(_sourceStats get "resolvedMsTotal"), (_sourceStats get "resolvedCount")] call _emitAverage],
    ["resolvedMsPeak", [(_sourceStats get "resolvedMsPeak")] call _emitSorted],
    ["emittedWaypointsLast", [(_sourceStats get "emittedWaypointsLast")] call _emitSorted],
    ["emittedWaypointsAvg", [(_sourceStats get "emittedWaypointsTotal"), (_sourceStats get "resolvedCount")] call _emitAverage],
    ["emittedWaypointsPeak", [(_sourceStats get "emittedWaypointsPeak")] call _emitSorted]
]
