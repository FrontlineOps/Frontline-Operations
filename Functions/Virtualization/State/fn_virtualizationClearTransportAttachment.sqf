/*
 * Function: FLO_fnc_virtualizationClearTransportAttachment
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears canonical transport attachment state from a passenger group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when the state was cleared
 */

params ["_groupData"];

_groupData set ["attachedTo", ""];
_groupData set ["attachedType", ""];
_groupData set ["mountedIn", ""];

true
