/*
 * Function: FLO_fnc_virtualizationResetBatchStats
 */

params ["_stats"];

_stats set ["groupsProcessedThisBatch", 0];
_stats set ["dueGroupsThisBatch", 0];
_stats set ["scheduledSkipsThisBatch", 0];
_stats set ["activationsThisBatch", 0];
_stats set ["activationBlocksThisBatch", 0];
_stats set ["deactivationsThisBatch", 0];
_stats set ["virtualMovesThisBatch", 0];
_stats set ["activePositionSyncsThisBatch", 0];
_stats set ["waypointAdvancesThisBatch", 0];
_stats set ["patrolAssignmentsThisBatch", 0];
_stats set ["attachedSyncsThisBatch", 0];
_stats set ["movementPauseSkipsThisBatch", 0];
_stats set ["movementDeadbandSkipsThisBatch", 0];
_stats set ["missionHoldSkipsThisBatch", 0];
_stats set ["eliminatedGroupsThisBatch", 0];
_stats set ["lastPlayerCacheMs", 0];
_stats set ["lastGroupCacheMs", 0];

true
