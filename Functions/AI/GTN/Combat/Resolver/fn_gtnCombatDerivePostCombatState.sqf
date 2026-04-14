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

if ((_gData get "groupType") == "static_aa") exitWith { "holding" };
if (_resumeState != "" && {_resumeState != "inCombat"}) exitWith { _resumeState };
if ((_gData get "pathToken") >= 0) exitWith { "planning" };
if (count (_gData get "waypoints") > 0) exitWith { "moving" };
if ((_gData get "replacementState") != "") exitWith { "moving" };

switch (_gData get "commanderOrder") do {
    case "ATTACK": { "holding" };
    case "DEFEND": { "holding" };
    case "MOVE": { "moving" };
    default {
        if (([_gData] call FLO_fnc_virtualizationGetAADeployState) == "DEPLOYED") then {
            "holding"
        } else {
            "idle"
        };
    };
}
