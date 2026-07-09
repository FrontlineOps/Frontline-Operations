/*
 * Function: FLO_fnc_virtualizationClearMountedIn
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears the spawned-mounted transport marker from a group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when the mounted state was cleared
 */

params ["_groupData"];

_groupData set ["mountedIn", ""];

true
