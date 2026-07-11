/*
 * Function: FLO_fnc_virtualizationGetAATargetPos
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the canonical AA deployment target position for a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * ARRAY - Target position
 */

params ["_groupData"];

_groupData get "aaDeployTargetPos"

