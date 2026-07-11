/*
 * Function: FLO_fnc_virtualizationRemoveTransportPassenger
 * Author: Frontline Operations Development Group
 * Description:
 *   Removes one passenger group ID from a transport group's canonical passenger list.
 *
 * Arguments:
 * 0: Transport group data <HASHMAP>
 * 1: Passenger group ID <STRING>
 *
 * Return Value:
 * BOOL - True when the passenger was removed
 */

params ["_groupData", "_passengerGroupId"];

private _attachedGroups = (_groupData get "attachedGroups") - [_passengerGroupId];
[_groupData, _attachedGroups] call FLO_fnc_virtualizationSetTransportPassengers;

true
