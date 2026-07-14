if (!hasInterface) exitWith { false };
if (FLO_SupportKeybindInitialized) exitWith { true };

[
    "FLO",
    "openSupportPanel",
    ["Open Tactical Support Net", "Open artillery, CAS, and CAP requests."],
    { [] call FLO_fnc_supportOpenDialog; true },
    {},
    [31, [true, true, false]],
    false
] call CBA_fnc_addKeybind;

FLO_SupportKeybindInitialized = true;
["UI", 4, "Tactical Support keybind initialized"] call FLO_fnc_log;
true
