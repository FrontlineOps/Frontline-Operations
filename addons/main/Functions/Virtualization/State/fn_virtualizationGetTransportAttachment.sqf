/*
 * Function: FLO_fnc_virtualizationGetTransportAttachment
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the canonical transport attachment group id for a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * STRING - Transport group id or empty string
 */

params ["_groupData"];

_groupData get "attachedTo"

