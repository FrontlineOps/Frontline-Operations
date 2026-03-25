/*
 * Function: FLO_fnc_virtualizationSetAssetComposition
 */

params [
    ["_groupData", createHashMap, [createHashMap]],
    ["_composition", [], [[]]]
];

private _groupType = _groupData get "groupType";
private _vehicleType = if ([_groupType] call FLO_fnc_virtualizationUsesAssetStrength) then {
    _composition param [0, ""]
} else {
    ""
};

_groupData set ["comp", _composition];
_groupData set ["vehicleType", _vehicleType];

true
