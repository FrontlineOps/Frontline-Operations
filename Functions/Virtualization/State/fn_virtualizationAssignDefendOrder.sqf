/*
 * Function: FLO_fnc_virtualizationAssignDefendOrder
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies canonical commander defend-order state to a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Target position <ARRAY>
 * 2: Objective ID <STRING>
 * 3: Lease issued at <NUMBER>
 * 4: Lease until <NUMBER>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupData", "_targetPos", "_objectiveId", "_leaseIssuedAt", "_leaseUntil"];

[_groupData] call FLO_fnc_virtualizationClearCommanderOrder;
[_groupData, "DEFEND"] call FLO_fnc_virtualizationSetCommanderOrder;
_groupData set ["defendObjective", _objectiveId];
_groupData set ["orderTargetPos", _targetPos];
_groupData set ["orderMode", "DEFEND"];
_groupData set ["defendLeaseIssuedAt", _leaseIssuedAt];
_groupData set ["defendLeaseUntil", _leaseUntil];

true
