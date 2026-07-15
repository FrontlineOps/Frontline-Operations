/*
 * Function: FLO_fnc_logisticsNetworkBuildRecentDispatchCounts
 * Author: Frontline Operations Development Group
 * Description:
 *   Prunes expired reinforcement dispatch history and returns current recent
 *   dispatch counts per objective for target spread scoring.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   HASHMAP - objectiveId -> recent dispatch count
 */

params ["_net"];

private _history = _net get "_recentReinforcementDispatches";
private _now = diag_tickTime;
private _pruned = [];
private _counts = createHashMap;

{
    _x params ["_objectiveId", "_expiresAt"];
    if (_expiresAt <= _now) then { continue };

    _pruned pushBack _x;
    _counts set [_objectiveId, (_counts getOrDefault [_objectiveId, 0]) + 1];
} forEach _history;

_net set ["_recentReinforcementDispatches", _pruned];

_counts
