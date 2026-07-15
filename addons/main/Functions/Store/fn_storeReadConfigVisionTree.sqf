params ["_cfg", "_traits", ["_depth", 0]];

if !(isClass _cfg) exitWith {};
if (_depth > 4) exitWith {};

[_cfg, _traits] call FLO_fnc_storeReadVisionTraits;

{
    [_x, _traits, _depth + 1] call FLO_fnc_storeReadConfigVisionTree;
} forEach ("true" configClasses _cfg);

