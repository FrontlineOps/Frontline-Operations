/*
 * Function: FLO_fnc_gtnGetCachedReserveBands
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Cache reserve-band graph walks for the current GTN cycle so attack, defense,
 * and garrison allocation can reuse the same graph-local BFS results.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 * 1: Seed Objective IDs <ARRAY>
 * 2: Max Depth <NUMBER>
 *
 * Return Value:
 * Objective ID -> Band <HASHMAP>
 */

params [
    ["_cmdr", nil],
    ["_seedObjectiveIds", [], [[]]],
    ["_maxDepth", 0, [0]]
];

if (isNil "_cmdr") exitWith { createHashMap };

private _sortedSeeds = +_seedObjectiveIds;
_sortedSeeds sort true;

private _cache = _cmdr get "_reserveBandsCache";
private _cacheKey = format ["%1|%2", _maxDepth, _sortedSeeds joinString ","];
if (_cacheKey in _cache) exitWith {
    _cache get _cacheKey
};

private _bands = [_cmdr, _sortedSeeds, _maxDepth] call FLO_fnc_gtnBuildObjectiveReserveBands;
_cache set [_cacheKey, _bands];

_bands
