/*
 * Function: FLO_fnc_virtualizationAssignAttackOrder
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies canonical commander attack-order state to a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Target position <ARRAY>
 * 2: Objective ID <STRING>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupData", "_targetPos", "_objectiveId"];

[_groupData] call FLO_fnc_virtualizationClearCommanderOrder;
[_groupData, "ATTACK"] call FLO_fnc_virtualizationSetCommanderOrder;
_groupData set ["attackObjective", _objectiveId];
_groupData set ["orderTargetPos", _targetPos];
_groupData set ["orderMode", "COMBAT"];

true
