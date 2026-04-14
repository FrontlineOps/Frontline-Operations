private _metrics = FLO_PF_Scheduler call ["GetMetrics"];
private _cache = count (keys FLO_PF_RequestCache);
private _resolvedCount = _metrics get "resolvedCount";
private _resolvedMsAvg = if (_resolvedCount > 0) then { (_metrics get "resolvedMsTotal") / _resolvedCount } else { 0 };
private _resolvedNodeStepsAvg = if (_resolvedCount > 0) then { (_metrics get "resolvedNodeStepsTotal") / _resolvedCount } else { 0 };
private _emittedWaypointsAvg = if (_resolvedCount > 0) then { (_metrics get "emittedWaypointsTotal") / _resolvedCount } else { 0 };
private _perf = FLO_PF_Perf;

[
    ["routingMode", _perf get "routingMode"],
    ["nodeSteps", _metrics get "nodeSteps"],
    ["submitted", _metrics get "submitted"],
    ["completedSuccess", _metrics get "completedSuccess"],
    ["completedPartial", _metrics get "completedPartial"],
    ["resolvedCount", _resolvedCount],
    ["resolvedNodeStepsLast", _metrics get "resolvedNodeStepsLast"],
    ["resolvedNodeStepsAvg", _resolvedNodeStepsAvg],
    ["resolvedNodeStepsPeak", _metrics get "resolvedNodeStepsPeak"],
    ["resolvedMsLast", _metrics get "resolvedMsLast"],
    ["resolvedMsAvg", _resolvedMsAvg],
    ["resolvedMsPeak", _metrics get "resolvedMsPeak"],
    ["emittedWaypointsLast", _metrics get "emittedWaypointsLast"],
    ["emittedWaypointsAvg", _emittedWaypointsAvg],
    ["emittedWaypointsPeak", _metrics get "emittedWaypointsPeak"],
    ["requestCache", _cache],
    ["cacheHits", _perf get "cacheHits"]
]
