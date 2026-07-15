params ["_className"];

private _cfg = configFile >> "CfgWeapons" >> _className;

if !(isClass _cfg) exitWith {
    createHashMapFromArray [
        ["hasNvg", false],
        ["hasThermal", false],
        ["hasThermalResolution", false],
        ["thermalModeCount", 0]
    ]
};

private _traits = createHashMapFromArray [
    ["hasNvg", false],
    ["hasThermal", false],
    ["hasThermalResolution", false],
    ["thermalModeCount", 0]
];

{
    if (isClass _x) then {
        [_x, _traits] call FLO_fnc_storeReadVisionTraits;

        private _opticsModes = _x >> "OpticsModes";

        if (isClass _opticsModes) then {
            {
                [_x, _traits] call FLO_fnc_storeReadVisionTraits;
            } forEach ("true" configClasses _opticsModes);
        };
    };
} forEach [
    _cfg,
    _cfg >> "ItemInfo"
];

_traits

