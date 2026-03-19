private _metrics = FLO_PF_Scheduler call ["GetMetrics"];
private _pending = count (keys FLO_PF_RequestPending);
private _cache = count (keys FLO_PF_RequestCache);
private _active = if (isNil { FLO_PF_Scheduler get "CurrentItem" }) then { 0 } else { 1 };
private _resolvedCount = _metrics get "resolvedCount";
private _resolvedMsAvg = if (_resolvedCount > 0) then { (_metrics get "resolvedMsTotal") / _resolvedCount } else { 0 };
private _emittedWaypointsAvg = if (_resolvedCount > 0) then { (_metrics get "emittedWaypointsTotal") / _resolvedCount } else { 0 };
private _perf = FLO_PF_Perf;

[
    ["queueDepth", _metrics get "queueDepth"],
    ["queuePeak", _metrics get "queuePeak"],
    ["processedThisFrame", _metrics get "processedThisFrame"],
    ["nodeSteps", _metrics get "nodeSteps"],
    ["submitted", _metrics get "submitted"],
    ["completedSuccess", _metrics get "completedSuccess"],
    ["completedPartial", _metrics get "completedPartial"],
    ["resolvedCount", _resolvedCount],
    ["resolvedMsLast", _metrics get "resolvedMsLast"],
    ["resolvedMsAvg", _resolvedMsAvg],
    ["resolvedMsPeak", _metrics get "resolvedMsPeak"],
    ["emittedWaypointsLast", _metrics get "emittedWaypointsLast"],
    ["emittedWaypointsAvg", _emittedWaypointsAvg],
    ["emittedWaypointsPeak", _metrics get "emittedWaypointsPeak"],
    ["frameCostMs", _metrics get "frameCostMs"],
    ["frameCostPeakMs", _metrics get "frameCostPeakMs"],
    ["requestPending", _pending],
    ["requestCache", _cache],
    ["activeSearch", _active],
    ["graphBuildMs", _perf get "graphBuildMs"],
    ["roadCount", _perf get "roadCount"],
    ["cacheHits", _perf get "cacheHits"]
]
