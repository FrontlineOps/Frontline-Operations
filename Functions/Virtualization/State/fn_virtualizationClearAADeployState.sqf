/*
 * Function: FLO_fnc_virtualizationClearAADeployState
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears canonical AA deployment state from a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when the state was cleared
 */

params ["_groupData"];

_groupData set ["aaDeployState", ""];
_groupData set ["aaDeployTargetPos", []];
_groupData set ["aaDeployTargetObjective", ""];
_groupData set ["isStrategicAA", false];

true
