if (!hasInterface) exitWith {};

[
    { !isNull player },
    {
        [
            "FLO",
            "openDeploymentPanel",
            ["Open Deployment Panel", "Open the FLO FOB/COP deployment panel."],
            { [] call FLO_fnc_baseDeployOpenDialog; true },
            {},
            [32, [true, true, false]],
            false
        ] call CBA_fnc_addKeybind;

        diag_log "[FLO][Base] Deployment keybind initialized";
    }
] call CBA_fnc_waitUntilAndExecute;
