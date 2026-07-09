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
private _source = if ("source" in _handle) then { _handle get "source" } else { "preset" };
private _data = if (_source isEqualTo "auto") then {
    format ["auto|%1", _handle get "factionClass"]
} else {
    format ["preset|%1", _selection]
};

[_sideLabel, _selection, _data] call FLO_fnc_factionGetCompositionDefaults
