/*
 * Function: FLO_fnc_factionBuildCompositionDefaultsHandle
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves the default objective composition tuning handle for a selected
 *   faction handle.
 *
 * Arguments:
 * 0: Faction handle <HASHMAP>
 * 1: Side label <STRING>
 *
 * Returns:
 * Composition defaults handle <HASHMAP>
 */
params ["_handle", "_sideLabel"];

private _selection = _handle get "name";
[_sideLabel, _selection] call FLO_fnc_factionGetCompositionDefaults
