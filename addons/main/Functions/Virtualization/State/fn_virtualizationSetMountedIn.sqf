/*
 * Function: FLO_fnc_virtualizationSetMountedIn
 * Author: Frontline Operations Development Group
 * Description:
 *   Marks an attached group as currently spawned mounted inside a transport.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Transport group ID <STRING>
 *
 * Return Value:
 * BOOL - True when the mounted state was applied
 */

params ["_groupData", "_transportGroupId"];

_groupData set ["mountedIn", _transportGroupId];

true
