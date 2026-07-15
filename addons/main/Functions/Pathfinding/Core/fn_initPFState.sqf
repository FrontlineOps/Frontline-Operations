FLO_PF_RequestCache = createHashMap;
FLO_PF_RequestTTL = 300;
FLO_PF_RequestCacheMax = 3000;
FLO_PF_RequestPruneInterval = 15;
FLO_PF_RequestNextPruneAt = 0;
FLO_PF_WaterSampleStep = 180;
FLO_PF_WaterSampleStepTrails = 120;
FLO_PF_WaterSampleStepLogi = 260;
FLO_PF_WaterValidationStep = 40;
FLO_PF_WaterDetourBaseOffset = 220;
FLO_PF_WaterDetourStep = 180;
FLO_PF_WaterDetourMax = 2800;
FLO_PF_WaterRouteMaxDepth = 4;

FLO_PF_SourceStats = createHashMapFromArray [
    ["attempts", createHashMap],
    ["newSearch", createHashMap],
    ["cacheHit", createHashMap],
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
    ["routingMode", "WATER_ONLY"],
    ["cacheHits", 0],
    ["slowSearchThresholdMs", 35],
    ["logCooldownSec", 5],
    ["nextSlowSearchLogAt", 0]
];

FLO_PF_Metrics = createHashMapFromArray [
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
    ["emittedWaypointsTotal", 0]
];
