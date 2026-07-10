/*
 * Function: FLO_fnc_virtualizationRebuildDerivedState
 */

call FLO_fnc_virtualizationSpatialRebuild;
[] call FLO_fnc_virtualizationReconcileTransportState;

FLO_VirtUpdate set ["cachedGroupIds", []];
FLO_VirtUpdate set ["lastGroupCacheTime", 0];
FLO_VirtUpdate set ["currentBatchIndex", 0];

private _stats = FLO_VirtUpdate get "stats";
[diag_tickTime, _stats, call FLO_fnc_virtualizationGetGroupMap] call FLO_fnc_virtualizationRefreshCachedGroups;

true
