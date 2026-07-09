/*
 * Function: FLO_fnc_virtualizationResetUpdateStats
 */

private _stats = FLO_VirtUpdate get "stats";
private _perf = FLO_VirtUpdate get "perf";
private _defaults = call FLO_fnc_virtualizationGetUpdateStatsDefaults;

{
    _stats set [_x, _y];
} forEach _defaults;

_perf set ["nextSlowBatchLogAt", 0];
_perf set ["nextSlowGroupLogAt", 0];

true
