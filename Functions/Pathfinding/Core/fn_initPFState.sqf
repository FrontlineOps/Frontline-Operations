FLO_PF_RequestCache = createHashMap;
FLO_PF_RequestPending = createHashMap;
FLO_PF_RequestTTL = 300;
FLO_PF_RequestCellSize = 90;
FLO_PF_RequestCacheMax = 3000;
FLO_PF_RequestPruneInterval = 15;
FLO_PF_RequestNextPruneAt = 0;

FLO_PF_SourceStats = createHashMapFromArray [
    ["attempts", createHashMap],
    ["newSearch", createHashMap],
    ["cacheHit", createHashMap],
    ["pendingJoin", createHashMap],
    ["inFlight", createHashMap],
    ["inFlightPeak", createHashMap],
    ["completedSuccess", createHashMap],
    ["completedPartial", createHashMap],
    ["resolvedCount", createHashMap],
    ["resolvedNodeStepsLast", createHashMap],
    ["resolvedNodeStepsTotal", createHashMap],
    ["resolvedNodeStepsPeak", createHashMap],
    ["resolvedMsLast", createHashMap],
    ["resolvedMsTotal", createHashMap],
    ["resolvedMsPeak", createHashMap],
    ["emittedWaypointsLast", createHashMap],
    ["emittedWaypointsTotal", createHashMap],
    ["emittedWaypointsPeak", createHashMap]
];

FLO_PF_Perf = createHashMapFromArray [
    ["graphBuildMs", -1],
    ["roadCount", 0],
    ["cacheHits", 0],
    ["slowFrameThresholdMs", 2],
    ["slowSearchThresholdMs", 35],
    ["runawayNodeStepsThreshold", 5000],
    ["runawayNodeStepsLogInterval", 25000],
    ["logiReinfMaxNodeSteps", 384],
    ["logCooldownSec", 5],
    ["nextSlowFrameLogAt", 0],
    ["nextSlowSearchLogAt", 0]
];
