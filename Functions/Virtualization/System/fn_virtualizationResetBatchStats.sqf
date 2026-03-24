/*
 * Function: FLO_fnc_virtualizationResetBatchStats
 */

params ["_stats"];

{
    _stats set [_x, _y];
} forEach (createHashMapFromArray [
    ["groupsProcessedThisBatch", 0],
    ["activationsThisBatch", 0],
    ["deactivationsThisBatch", 0],
    ["virtualMovesThisBatch", 0],
    ["activePositionSyncsThisBatch", 0],
    ["waypointAdvancesThisBatch", 0],
    ["patrolAssignmentsThisBatch", 0],
    ["attachedSyncsThisBatch", 0],
    ["tierSkipsThisBatch", 0],
    ["missionHoldSkipsThisBatch", 0],
    ["eliminatedGroupsThisBatch", 0],
    ["lastPlayerCacheMs", 0],
    ["lastGroupCacheMs", 0]
]);

true
