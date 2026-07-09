/*
 * Function: FLO_fnc_virtualizationGetEffectiveState
 * Author: Frontline Operations Development Group
 * Description:
 *   Derives a high-level semantic state from the normalized virtualization
 *   fields while the stored "state" field remains a low-level runtime state.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * STRING - Effective state
 */

params ["_groupData"];

if (_groupData get "inCombat") exitWith { "inCombat" };

private _replacementState = _groupData get "replacementState";
switch (_replacementState) do {
    case "REINFORCE": { "reinforcing" };
    case "AA_DEPLOY": { "aaDeploy" };
    default {
        private _executionState = _groupData get "executionState";
        if (_executionState != "") exitWith { toLower _executionState };

        private _runtimeState = _groupData get "state";
        if (_runtimeState in ["reserved", "planning", "moving", "idle"]) exitWith { _runtimeState };

        if (_runtimeState == "holding") then {
            switch (_groupData get "commanderOrder") do {
                case "ATTACK": { "attacking" };
                case "DEFEND": { "defending" };
                default {
                    ["holding", "defending"] select (((_groupData get "groupType") == "static_aa") || {([_groupData] call FLO_fnc_virtualizationGetAADeployState) == "DEPLOYED"});
                };
            };
        } else {
            _runtimeState
        };
    };
}
