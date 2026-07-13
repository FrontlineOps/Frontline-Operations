if (!hasInterface || {FLO_SupportKeybindInitialized}) exitWith {};

FLO_SupportKeybindInitialized = true;

[
    { !isNull player },
    {
        [
            "FLO",
            "openSupportPanel",
            ["Open Tactical Support Net", "Open artillery, CAS, and CAP requests."],
            { [] call FLO_fnc_supportOpenDialog; true },
            {},
            [31, [true, true, false]],
            false
        ] call CBA_fnc_addKeybind;

        diag_log "[FLO][Support] Ctrl+Shift+S keybind initialized";
    }
] call CBA_fnc_waitUntilAndExecute;
