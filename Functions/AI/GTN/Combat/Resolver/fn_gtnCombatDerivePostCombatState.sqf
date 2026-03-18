/*
 * Function: FLO_fnc_gtnCombatDerivePostCombatState
 * Author: Frontline Operations Development Group
 * Description:
 *   Derives the appropriate group state after the combat overlay is removed.
 *
 * Arguments:
 *   0: Group data <HASHMAP>
 *   1: Saved resume state <STRING>
 *
 * Return Value:
 *   Post-combat state <STRING>
 */

params ["_gData", "_resumeState"];

if ((_gData get "groupType") == "static_aa") exitWith { "defending" };
if (_resumeState != "" && {_resumeState != "inCombat"}) exitWith { _resumeState };
if ((_gData getOrDefault ["pathRequestToken", -1]) >= 0) exitWith { "planning" };
if (count (_gData get "waypoints") > 0) exitWith { "moving" };
if (_gData getOrDefault ["isReinforcing", false]) exitWith { "reinforcing" };

switch (_gData get "currentOrder") do {
    case "ATTACK": { "attacking" };
    case "DEFEND": { "defending" };
    case "MOVE": { "moving" };
    default { "idle" };
}
