if (!hasInterface) exitWith { false };
if (FLO_DevelopmentKeybindInitialized) exitWith { true };

[
    "FLO",
    "openDevelopmentPanel",
    ["Open Development Panel", "Open regional development projects and doctrine."],
    { [] call FLO_fnc_developmentOpenDialog; true },
    {},
    [23, [true, true, false]],
    false
] call CBA_fnc_addKeybind;

FLO_DevelopmentKeybindInitialized = true;
["UI", 4, "Development keybind initialized"] call FLO_fnc_log;
true
