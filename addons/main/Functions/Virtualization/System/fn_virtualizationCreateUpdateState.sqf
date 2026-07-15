/*
 * Function: FLO_fnc_virtualizationCreateUpdateState
 */

params [
    ["_batchSize", 25, [0]],
    ["_playerCacheInterval", 1, [0]]
];

createHashMapFromArray [
    ["pfhId", -1],
    ["disconnectEhId", -1],
    ["running", false],
    ["lastUpdateTime", 0],
    ["lastPlayerCacheTime", 0],
    ["lastGroupCacheTime", 0],
    ["cachedPlayerPositions", []],
    ["cachedGroupIds", []],
    ["activeUnitCount", 0],
    ["currentBatchIndex", 0],
    ["batchSize", _batchSize],
    ["playerCacheInterval", _playerCacheInterval],
    ["stats", call FLO_fnc_virtualizationGetUpdateStatsDefaults],
    ["perf", call FLO_fnc_virtualizationGetUpdatePerfDefaults]
]
