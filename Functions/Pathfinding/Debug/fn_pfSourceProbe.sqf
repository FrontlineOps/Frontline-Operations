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

private _emitCurrentQueueBySource = {
    private _counts = createHashMap;
    private _queueObject = FLO_PF_Scheduler get "_queueObject";
    private _queueArray = _queueObject get "_queueArray";
    private _head = _queueObject get "_head";

    for "_i" from _head to ((count _queueArray) - 1) do {
        private _item = _queueArray select _i;
        private _sourceTag = _item get "SourceTag";
        _counts set [_sourceTag, (_counts getOrDefault [_sourceTag, 0]) + 1];
    };

    private _active = FLO_PF_Scheduler get "CurrentItem";
    if !(isNil "_active") then {
        private _sourceTag = _active get "SourceTag";
        _counts set [_sourceTag, (_counts getOrDefault [_sourceTag, 0]) + 1];
    };

    [_counts] call _emitSorted
};

private _emitActiveSource = {
    private _active = FLO_PF_Scheduler get "CurrentItem";
    if (isNil "_active") exitWith { "" };
    _active get "SourceTag";
};

private _sourceStats = FLO_PF_SourceStats;

[
    ["activeSource", call _emitActiveSource],
    ["queuedPlusActive", call _emitCurrentQueueBySource],
    ["attempts", [(_sourceStats get "attempts")] call _emitSorted],
    ["newSearch", [(_sourceStats get "newSearch")] call _emitSorted],
    ["cacheHit", [(_sourceStats get "cacheHit")] call _emitSorted],
    ["pendingJoin", [(_sourceStats get "pendingJoin")] call _emitSorted],
    ["inFlight", [(_sourceStats get "inFlight")] call _emitSorted],
    ["inFlightPeak", [(_sourceStats get "inFlightPeak")] call _emitSorted],
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
