/*
 * Function: FLO_fnc_virtualizationClearExecutionState
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears canonical non-commander execution state from a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when the state was cleared
 */

params ["_groupData"];

_groupData set ["executionState", ""];

true
