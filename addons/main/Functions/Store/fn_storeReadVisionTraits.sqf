params ["_cfg", "_traits"];

if !(isClass _cfg) exitWith {};

{
    private _mode = toLower _x;

    if (_mode isEqualTo "nvg") then {
        _traits set ["hasNvg", true];
    };

    if (_mode in ["ti", "thermal"]) then {
        _traits set ["hasThermal", true];
    };
} forEach getArray (_cfg >> "visionMode");

private _thermalModes = getArray (_cfg >> "thermalMode");

if (_thermalModes isNotEqualTo []) then {
    _traits set ["hasThermal", true];
    _traits set ["thermalModeCount", ((_traits get "thermalModeCount") max count _thermalModes)];
};

if (getArray (_cfg >> "thermalResolution") isNotEqualTo []) then {
    _traits set ["hasThermal", true];
    _traits set ["hasThermalResolution", true];
};

