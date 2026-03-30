private _metrics = createHashMapFromArray [
    ["submitted", 0],
    ["completedSuccess", 0],
    ["completedPartial", 0],
    ["nodeSteps", 0],
    ["resolvedCount", 0],
    ["resolvedNodeStepsLast", 0],
    ["resolvedNodeStepsPeak", 0],
    ["resolvedNodeStepsTotal", 0],
    ["resolvedMsLast", 0],
    ["resolvedMsPeak", 0],
    ["resolvedMsTotal", 0],
    ["emittedWaypointsLast", 0],
    ["emittedWaypointsPeak", 0],
    ["emittedWaypointsTotal", 0],
    ["processedThisFrame", 0],
    ["queueDepth", 0],
    ["queuePeak", 0],
    ["frameCostMs", 0],
    ["lastNonZeroFrameCostMs", 0],
    ["frameCostPeakMs", 0],
    ["hadWorkLastFrame", false],
    ["lastFrameAt", diag_tickTime],
    ["lastWorkFrameAt", 0]
];

if (isNil "FLO_PF_Scheduler") then {
    FLO_PF_Scheduler = createHashMapObject [[
        ["#type", "FLO_typ_WaterRoutingMetrics"],
        ["_metrics", _metrics],
        ["CurrentItem", nil],
        ["MaxNodesPerFrame", 0],
        ["GetMetrics", compileFinal {
            _self get "_metrics"
        }]
    ]];
};
