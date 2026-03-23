/*
 * Function: FLO_fnc_virtualizationAssignMoveOrder
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies canonical commander move-order state to a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Target position <ARRAY>
 * 2: Order mode <STRING>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupData", "_targetPos", "_mode"];

[_groupData] call FLO_fnc_virtualizationClearCommanderOrder;
[_groupData, "MOVE"] call FLO_fnc_virtualizationSetCommanderOrder;
_groupData set ["orderTargetPos", _targetPos];
_groupData set ["orderMode", _mode];

true
