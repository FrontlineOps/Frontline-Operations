/*
 * Function: FLO_fnc_transportClearInsertState
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears the carrier-side insert execution state used by ground transport,
 *   helicopter landing inserts, and paradrops.
 *
 * Arguments:
 *   0: Carrier Group Data <HASHMAP>
 *
 * Return Value:
 *   BOOL - True when the state was cleared
 */

params [["_groupData", createHashMap, [createHashMap]]];

_groupData set ["dismountAtWaypoint", -1];
_groupData set ["transportInsertMode", ""];
_groupData set ["transportInsertPos", []];
_groupData set ["transportLandCommandIssued", false];
[_groupData] call FLO_fnc_virtualizationClearExecutionState;
[_groupData] call FLO_fnc_virtualizationClearMissionLock;

true
