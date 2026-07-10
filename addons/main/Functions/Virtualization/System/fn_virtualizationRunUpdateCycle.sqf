/*
 * Function: FLO_fnc_virtualizationRunUpdateCycle
 */

private _now = diag_tickTime;
private _stats = FLO_VirtUpdate get "stats";
private _perf = FLO_VirtUpdate get "perf";
private _batchStartTime = diag_tickTime;

FLO_VirtUpdate set ["lastUpdateTime", _now];

[_stats] call FLO_fnc_virtualizationResetBatchStats;
[ _now, _stats ] call FLO_fnc_virtualizationRefreshPlayerCache;

private _groups = call FLO_fnc_virtualizationGetGroupMap;
if ((keys _groups) isEqualTo []) exitWith {
    FLO_VirtUpdate set ["cachedGroupIds", []];
    FLO_VirtUpdate set ["activeUnitCount", 0];
    FLO_VirtUpdate set ["currentBatchIndex", 0];
    _stats set ["totalGroupsLast", 0];
    _stats set ["activeGroupsLast", 0];
    _stats set ["inactiveGroupsLast", 0];
    _stats set ["activeUnitsLast", 0];
    _stats set ["deferredGroupsLast", 0];
    _stats set ["activationCapLast", ["activationUnitCap"] call FLO_fnc_virtualizationGetConfigValue];
    _stats set ["lastBatchStart", 0];
    _stats set ["lastBatchEnd", -1];
    _stats set ["lastBatchMs", (diag_tickTime - _batchStartTime) * 1000];
};

private _groupIds = [_now, _stats, _groups] call FLO_fnc_virtualizationRefreshCachedGroups;

private _activationDist = ["activationDistance"] call FLO_fnc_virtualizationGetConfigValue;
private _batchResult = [_groupIds, _groups, _activationDist, _now, _stats, _perf] call FLO_fnc_virtualizationProcessGroupBatch;
_batchResult params ["_processed", "_batchStart", "_batchEnd", "_totalGroups"];

private _batchMs = (diag_tickTime - _batchStartTime) * 1000;
_stats set ["lastBatchMs", _batchMs];
if (_batchMs > (_stats get "peakBatchMs")) then {
    _stats set ["peakBatchMs", _batchMs];
};

[ _now, _processed, _batchStart, _batchEnd, _totalGroups, _batchMs, _stats, _perf ] call FLO_fnc_virtualizationLogSlowBatch;

true
