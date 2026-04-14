/*
 * Function: FLO_fnc_gtnCombatExitState
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears the combat overlay from a group and restores its next appropriate
 *   operational state.
 *
 * Arguments:
 *   0: Group ID <STRING>
 *   1: Group data <HASHMAP>
 *   2: Resume states map <HASHMAP>
 *
 * Return Value:
 *   None
 */

params ["_groupId", "_gData", "_resumeStates"];

private _resumeState = _resumeStates getOrDefault [_groupId, ""];
_gData set ["inCombat", false];
[_gData, [_gData, _resumeState] call FLO_fnc_gtnCombatDerivePostCombatState] call FLO_fnc_virtualizationSetRuntimeState;
_resumeStates deleteAt _groupId;
