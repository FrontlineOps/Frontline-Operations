/*
 * Function: FLO_fnc_virtualizationGetMountedTransport
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the canonical mounted transport group id for an active spawned group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * STRING - Transport group id or empty string
 */

params ["_groupData"];

_groupData get "mountedIn"

