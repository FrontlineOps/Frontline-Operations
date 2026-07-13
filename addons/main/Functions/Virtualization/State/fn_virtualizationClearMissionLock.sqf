/*
 * Function: FLO_fnc_virtualizationClearMissionLock
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears the canonical subsystem mission lock from a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when the lock was cleared
 */

params ["_groupData"];

_groupData set ["missionLock", ""];
_groupData set ["missionType", ""];
_groupData set ["nextProcessAt", 0];

true
