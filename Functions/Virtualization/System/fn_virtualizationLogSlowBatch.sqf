/*
 * Function: FLO_fnc_virtualizationLogSlowBatch
 */

params [
    "_now",
    "_processed",
    "_batchStart",
    "_batchEnd",
    "_totalGroups",
    "_batchMs",
    "_stats",
    "_perf"
];

if (_batchMs < (_perf get "slowBatchThresholdMs") || {_now < (_perf get "nextSlowBatchLogAt")}) exitWith { false };

_stats set ["slowBatchCount", (_stats get "slowBatchCount") + 1];
_perf set ["nextSlowBatchLogAt", _now + (_perf get "logCooldownSec")];

diag_log format [
    "[FLO][PERF] Virtualization PFH processed %1 groups (batch %2-%3 of %4) in %5 ms | playerCache=%6 groupCache=%7 activations=%8 blocked=%9 deactivations=%10 activeUnits=%11/%12 deferred=%13 virtualMoves=%14 moveOnly=%15 activeSyncs=%16 waypointAdv=%17 patrols=%18 attached=%19 tierSkips=%20 missionSkips=%21 eliminated=%22",
    _processed,
    _batchStart,
    _batchEnd,
    _totalGroups,
    _batchMs,
    _stats get "lastPlayerCacheMs",
    _stats get "lastGroupCacheMs",
    _stats get "activationsThisBatch",
    _stats get "activationBlocksThisBatch",
    _stats get "deactivationsThisBatch",
    _stats get "activeUnitsLast",
    _stats get "activationCapLast",
    _stats get "deferredGroupsLast",
    _stats get "virtualMovesThisBatch",
    _stats get "movementOnlyUpdatesThisBatch",
    _stats get "activePositionSyncsThisBatch",
    _stats get "waypointAdvancesThisBatch",
    _stats get "patrolAssignmentsThisBatch",
    _stats get "attachedSyncsThisBatch",
    _stats get "tierSkipsThisBatch",
    _stats get "missionHoldSkipsThisBatch",
    _stats get "eliminatedGroupsThisBatch"
];

true
