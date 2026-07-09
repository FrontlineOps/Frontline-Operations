/*
 * Function: FLO_fnc_virtualizationGetTransportPassengers
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the canonical passenger manifest for a transport group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * ARRAY - Attached passenger group ids
 */

params ["_groupData"];

_groupData get "attachedGroups"

