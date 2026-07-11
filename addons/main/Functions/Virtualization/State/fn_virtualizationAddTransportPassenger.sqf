/*
 * Function: FLO_fnc_virtualizationAddTransportPassenger
 * Author: Frontline Operations Development Group
 * Description:
 *   Adds one passenger group ID to a transport group's canonical passenger list.
 *
 * Arguments:
 * 0: Transport group data <HASHMAP>
 * 1: Passenger group ID <STRING>
 *
 * Return Value:
 * BOOL - True when the passenger was registered
 */

params ["_groupData", "_passengerGroupId"];

private _attachedGroups = +(_groupData get "attachedGroups");
if !(_passengerGroupId in _attachedGroups) then {
    _attachedGroups pushBack _passengerGroupId;
};

[_groupData, _attachedGroups] call FLO_fnc_virtualizationSetTransportPassengers;

true
