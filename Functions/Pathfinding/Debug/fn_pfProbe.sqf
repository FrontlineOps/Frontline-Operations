private _metrics = FLO_PF_Scheduler call ["GetMetrics"];
private _pending = count (keys FLO_PF_RequestPending);
private _cache = count (keys FLO_PF_RequestCache);
private _active = if (isNil { FLO_PF_Scheduler get "CurrentItem" }) then { 0 } else { 1 };
private _resolvedCount = _metrics get "resolvedCount";
private _resolvedMsAvg = if (_resolvedCount > 0) then { (_metrics get "resolvedMsTotal") / _resolvedCount } else { 0 };
private _resolvedNodeStepsAvg = if (_resolvedCount > 0) then { (_metrics get "resolvedNodeStepsTotal") / _resolvedCount } else { 0 };
private _emittedWaypointsAvg = if (_resolvedCount > 0) then { (_metrics get "emittedWaypointsTotal") / _resolvedCount } else { 0 };
private _perf = FLO_PF_Perf;
private _frameAgeMs = (diag_tickTime - (_metrics get "lastFrameAt")) * 1000;
private _lastWorkAgeMs = if ((_metrics get "lastWorkFrameAt") > 0) then {
    (diag_tickTime - (_metrics get "lastWorkFrameAt")) * 1000
} else {
    -1
};
private _currentItem = FLO_PF_Scheduler get "CurrentItem";
private _activeNodeSteps = if (isNil "_currentItem") then { 0 } else { _currentItem get "NodeSteps" };
private _activeSource = if (isNil "_currentItem") then { "" } else { _currentItem get "SourceTag" };
private _activeRequestDistance = if (isNil "_currentItem") then { 0 } else { _currentItem get "RequestDistance" };
private _activeDoctrine = if (isNil "_currentItem") then { "" } else { _currentItem get "DoctrineName" };
private _activeStartSnapDistance = if (isNil "_currentItem") then { 0 } else { _currentItem get "StartSnapDistance" };
private _activeEndSnapDistance = if (isNil "_currentItem") then { 0 } else { _currentItem get "EndSnapDistance" };
private _activeStartNodeIndex = if (isNil "_currentItem") then { "" } else { _currentItem get "StartNodeIndex" };
private _activeEndNodeIndex = if (isNil "_currentItem") then { "" } else { _currentItem get "EndNodeIndex" };
private _activeStartNodeType = if (isNil "_currentItem") then { "" } else { _currentItem get "StartNodeType" };
private _activeEndNodeType = if (isNil "_currentItem") then { "" } else { _currentItem get "EndNodeType" };
private _activeStartComponentId = if (isNil "_currentItem") then { -1 } else { _currentItem getOrDefault ["StartComponentId", -1] };
private _activeEndComponentId = if (isNil "_currentItem") then { -1 } else { _currentItem getOrDefault ["EndComponentId", -1] };
private _activeRequestAgeMs = if (isNil "_currentItem") then { 0 } else { (diag_tickTime - (_currentItem get "SubmittedAt")) * 1000 };

[
    ["maxNodesPerFrame", FLO_PF_Scheduler get "MaxNodesPerFrame"],
    ["queueDepth", _metrics get "queueDepth"],
    ["queuePeak", _metrics get "queuePeak"],
    ["processedThisFrame", _metrics get "processedThisFrame"],
    ["hadWorkLastFrame", _metrics get "hadWorkLastFrame"],
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
    ["frameCostMs", _metrics get "frameCostMs"],
    ["lastNonZeroFrameCostMs", _metrics get "lastNonZeroFrameCostMs"],
    ["frameCostPeakMs", _metrics get "frameCostPeakMs"],
    ["frameAgeMs", _frameAgeMs],
    ["lastWorkAgeMs", _lastWorkAgeMs],
    ["requestPending", _pending],
    ["requestCache", _cache],
    ["activeSearch", _active],
    ["activeSource", _activeSource],
    ["activeNodeSteps", _activeNodeSteps],
    ["activeRequestDistance", _activeRequestDistance],
    ["activeDoctrine", _activeDoctrine],
    ["activeRequestAgeMs", _activeRequestAgeMs],
    ["activeStartSnapDistance", _activeStartSnapDistance],
    ["activeEndSnapDistance", _activeEndSnapDistance],
    ["activeStartNodeIndex", _activeStartNodeIndex],
    ["activeEndNodeIndex", _activeEndNodeIndex],
    ["activeStartNodeType", _activeStartNodeType],
    ["activeEndNodeType", _activeEndNodeType],
    ["activeStartComponentId", _activeStartComponentId],
    ["activeEndComponentId", _activeEndComponentId],
    ["graphBuildMs", _perf get "graphBuildMs"],
    ["roadCount", _perf get "roadCount"],
    ["cacheHits", _perf get "cacheHits"]
]
