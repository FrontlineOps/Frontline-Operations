/*
 * Function: FLO_fnc_virtualizationGetAATargetObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the canonical AA deployment target objective for a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * STRING - Objective id
 */

params ["_groupData"];

_groupData get "aaDeployTargetObjective"

