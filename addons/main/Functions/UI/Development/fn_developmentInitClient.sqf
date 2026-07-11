if (!hasInterface || {FLO_DevelopmentKeybindInitialized}) exitWith {};

FLO_DevelopmentKeybindInitialized = true;

[
    { !isNull player },
    {
        [
            "FLO",
            "openDevelopmentPanel",
            ["Open Development Panel", "Open regional development projects and doctrine."],
            { [] call FLO_fnc_developmentOpenDialog; true },
            {},
            [23, [true, true, false]],
            false
        ] call CBA_fnc_addKeybind;

        diag_log "[FLO][Development] Ctrl+Shift+I keybind initialized";
    }
] call CBA_fnc_waitUntilAndExecute;
