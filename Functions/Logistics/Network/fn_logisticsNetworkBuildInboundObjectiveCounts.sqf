/*
 * Function: FLO_fnc_logisticsNetworkBuildInboundObjectiveCounts
 * Author: Frontline Operations Development Group
 * Description:
 *   Counts currently reinforcing virtual groups by their destination objective
 *   so target selection can avoid repeatedly overfilling the same sector.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   HASHMAP - objectiveId -> inbound reinforcing group count
 */

params ["_net"];

private _managedSide = _net get "_managedSide";
private _groups = FLO_virtualGroups get "_groups";
private _counts = createHashMap;

{
    private _groupData = _y;
    if ((_groupData get "side") != _managedSide) then { continue };
    if !(_groupData get "isReinforcing") then { continue };

    private _objectiveId = _groupData get "reinforcementTargetObjective";
    if (_objectiveId == "") then {
        _objectiveId = _groupData get "homeObjective";
    };
    if (_objectiveId == "") then { continue };

    _counts set [_objectiveId, (_counts getOrDefault [_objectiveId, 0]) + 1];
} forEach _groups;

_counts
