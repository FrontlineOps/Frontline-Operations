/*
 * Function: FLO_fnc_virtualizationSetRuntimeState
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the canonical low-level runtime state for a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Runtime state <STRING>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupData", "_state"];

_groupData set ["state", _state];

true

