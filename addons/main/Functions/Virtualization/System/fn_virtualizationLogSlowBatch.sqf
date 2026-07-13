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
    "[FLO][PERF] Virtualization PFH processed %1 groups (batch %2-%3 of %4) in %5 ms | due=%6 scheduledSkips=%7 playerCache=%8 groupCache=%9 activations=%10 blocked=%11 deactivations=%12 activeUnits=%13/%14 deferred=%15 virtualMoves=%16 activeSyncs=%17 waypointAdv=%18 patrols=%19 attached=%20 movePaused=%21 deadband=%22 missionSkips=%23 eliminated=%24",
    _processed,
    _batchStart,
    _batchEnd,
    _totalGroups,
    _batchMs,
    _stats get "dueGroupsThisBatch",
    _stats get "scheduledSkipsThisBatch",
    _stats get "lastPlayerCacheMs",
    _stats get "lastGroupCacheMs",
    _stats get "activationsThisBatch",
    _stats get "activationBlocksThisBatch",
    _stats get "deactivationsThisBatch",
    _stats get "activeUnitsLast",
    _stats get "activationCapLast",
    _stats get "deferredGroupsLast",
    _stats get "virtualMovesThisBatch",
    _stats get "activePositionSyncsThisBatch",
    _stats get "waypointAdvancesThisBatch",
    _stats get "patrolAssignmentsThisBatch",
    _stats get "attachedSyncsThisBatch",
    _stats get "movementPauseSkipsThisBatch",
    _stats get "movementDeadbandSkipsThisBatch",
    _stats get "missionHoldSkipsThisBatch",
    _stats get "eliminatedGroupsThisBatch"
];

true
