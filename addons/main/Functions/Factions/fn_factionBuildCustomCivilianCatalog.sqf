/* Builds the canonical civilian catalog from documented custom arrays. */
private _men = ["CivMenArray"] call FLO_fnc_factionGetVariableArray;
private _vehicles = ["CivVehArray"] call FLO_fnc_factionGetVariableArray;

if (_men isEqualTo []) then {
    throw "Custom civilian definition has no spawnable men";
};

createHashMapFromArray [
    ["men", _men],
    ["vehicles", _vehicles]
]
