/*
 * Function: FLO_fnc_virtualizationSetTransportAttachment
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies canonical transport attachment state to a passenger group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Transport group ID <STRING>
 * 2: Attachment type <STRING>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupData", "_transportGroupId", "_attachedType"];

_groupData set ["attachedTo", _transportGroupId];
_groupData set ["attachedType", _attachedType];

true
