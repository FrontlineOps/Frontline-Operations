/*
 * Function: FLO_fnc_gtnClearSecondaryTaskState
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears the secondary GTN player task slot state.
 *
 * Arguments:
 *   0: Player task state <HASHMAP>
 *
 * Return Value:
 *   Nothing
 */

params ["_state"];

_state set ["secondaryTaskId", ""];
_state set ["secondaryRef", ""];
_state set ["secondaryKind", ""];
_state set ["secondaryObjId", ""];
_state set ["secondaryTargets", []];
_state set ["secondaryScore", 0];
_state set ["secondaryAssignedAt", -1];
