/*
 * Function: FLO_fnc_virtualizationValidateUpdateState
 */

private _requiredKeys = [
    "pfhId",
    "running",
    "lastUpdateTime",
    "lastPlayerCacheTime",
    "lastGroupCacheTime",
    "cachedPlayerPositions",
    "cachedGroupIds",
    "currentBatchIndex",
    "batchSize",
    "playerCacheInterval",
    "groupUpdateTimes",
    "stats",
    "perf"
];

{
    private _value = FLO_VirtUpdate get _x;
    if (isNil "_value") then {
        throw format ["[VIRTUALIZATION] FLO_VirtUpdate missing key %1", _x];
    };
} forEach _requiredKeys;

private _stats = FLO_VirtUpdate get "stats";
private _perf = FLO_VirtUpdate get "perf";
private _statsDefaults = call FLO_fnc_virtualizationGetUpdateStatsDefaults;
private _perfDefaults = call FLO_fnc_virtualizationGetUpdatePerfDefaults;

{
    private _value = _stats get _x;
    if (isNil "_value") then {
        throw format ["[VIRTUALIZATION] FLO_VirtUpdate stats missing key %1", _x];
    };
} forEach keys _statsDefaults;

{
    private _value = _perf get _x;
    if (isNil "_value") then {
        throw format ["[VIRTUALIZATION] FLO_VirtUpdate perf missing key %1", _x];
    };
} forEach keys _perfDefaults;

true
