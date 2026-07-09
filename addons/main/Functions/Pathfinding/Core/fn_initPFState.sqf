FLO_PF_RequestCache = createHashMap;
FLO_PF_RequestTTL = 300;
FLO_PF_RequestCellSize = 90;
FLO_PF_RequestCacheMax = 3000;
FLO_PF_RequestPruneInterval = 15;
FLO_PF_RequestNextPruneAt = 0;
FLO_PF_Mode = "WATER_ONLY";
FLO_PF_WaterSampleStep = 180;
FLO_PF_WaterSampleStepTrails = 120;
FLO_PF_WaterSampleStepLogi = 260;
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
    ["routingMode", FLO_PF_Mode],
    ["cacheHits", 0],
    ["slowSearchThresholdMs", 35],
    ["logCooldownSec", 5],
    ["nextSlowSearchLogAt", 0]
];
