/*
 * Function: FLO_fnc_gtnCombatEnterState
 * Author: Frontline Operations Development Group
 * Description:
 *   Marks a virtual group as in combat and stores its previous state for later
 *   restoration.
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

if !(_gData get "inCombat") then {
    _resumeStates set [_groupId, _gData get "state"];
};

_gData set ["inCombat", true];
