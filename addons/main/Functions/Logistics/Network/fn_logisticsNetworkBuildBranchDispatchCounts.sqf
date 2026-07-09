/*
 * Function: FLO_fnc_logisticsNetworkBuildBranchDispatchCounts
 * Author: Frontline Operations Development Group
 * Description:
 *   Aggregates objective-scoped dispatch counts onto first-hop supply branches
 *   so target selection can bias away from recently serviced sectors.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Objective count map <HASHMAP>
 *
 * Return Value:
 *   HASHMAP - Branch objective ID -> aggregated count
 */

params ["_net", "_objectiveCounts"];

private _branchCounts = createHashMap;

{
    private _objectiveId = _x;
    private _count = _objectiveCounts get _objectiveId;
    if (_count <= 0) then { continue };

    private _branchObjectiveId = [_net, _objectiveId] call FLO_fnc_logisticsNetworkGetObjectiveSupplyBranch;
    if (_branchObjectiveId == "") then { continue };

    _branchCounts set [_branchObjectiveId, (_branchCounts getOrDefault [_branchObjectiveId, 0]) + _count];
} forEach (keys _objectiveCounts);

_branchCounts
