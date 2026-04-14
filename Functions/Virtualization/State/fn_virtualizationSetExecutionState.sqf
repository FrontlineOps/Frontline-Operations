/*
 * Function: FLO_fnc_virtualizationSetExecutionState
 * Author: Frontline Operations Development Group
 * Description:
 *   Sets canonical non-commander execution state on a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Execution state <STRING>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupData", "_state"];

_groupData set ["executionState", _state];

true
