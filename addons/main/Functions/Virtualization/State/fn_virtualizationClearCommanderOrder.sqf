/*
 * Function: FLO_fnc_virtualizationClearCommanderOrder
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears commander-owned order state from a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when the state was cleared
 */

params ["_groupData"];

_groupData set ["orderTargetPos", []];
_groupData set ["orderMode", ""];
_groupData set ["attackObjective", ""];
_groupData set ["campaignOperationId", ""];
_groupData set ["defendObjective", ""];
_groupData set ["defendLeaseIssuedAt", -1];
_groupData set ["defendLeaseUntil", -1];
_groupData set ["garrisonObjective", ""];
_groupData set ["garrisonPosition", []];
_groupData set ["commanderOrder", ""];

true
