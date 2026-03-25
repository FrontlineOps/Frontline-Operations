/*
 * Function: FLO_fnc_logisticsNetworkBuildInboundObjectiveCounts
 * Author: Frontline Operations Development Group
 * Description:
 *   Counts currently reinforcing virtual groups by their requested objective
 *   so saturation gates operate on the actual pressured sector rather than the
 *   staging objective where the group is currently headed.
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
    if ((_groupData get "replacementState") != "REINFORCE") then { continue };

    private _objectiveId = _groupData get "reinforcementRequestedObjective";
    if (_objectiveId == "") then { continue };

    _counts set [_objectiveId, (_counts getOrDefault [_objectiveId, 0]) + 1];
} forEach _groups;

_counts
