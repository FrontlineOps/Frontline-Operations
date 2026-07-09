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
_state set ["primaryRef", ""];
_state set ["primaryKind", ""];
_state set ["primaryObjId", ""];
_state set ["primaryScore", 0];
_state set ["primaryAssignedAt", -1];
_state set ["primaryCalmStartedAt", -1];
