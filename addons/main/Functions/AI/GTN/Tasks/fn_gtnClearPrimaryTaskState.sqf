/*
 * Function: FLO_fnc_gtnClearPrimaryTaskState
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears the primary GTN player task slot state.
 *
 * Arguments:
 *   0: Player task state <HASHMAP>
 *
 * Return Value:
 *   Nothing
 */

params ["_state"];

_state set ["primaryTaskId", ""];
_state set ["assignmentId", ""];
_state set ["objectiveId", ""];
