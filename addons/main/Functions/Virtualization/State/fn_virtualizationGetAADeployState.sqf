/*
 * Function: FLO_fnc_virtualizationGetAADeployState
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the canonical AA deployment runtime state for a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * STRING - AA deployment state
 */

params ["_groupData"];

_groupData get "aaDeployState"

