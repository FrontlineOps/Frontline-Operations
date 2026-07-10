if (!hasInterface || {FLO_OperationsKeybindInitialized}) exitWith {};

FLO_OperationsKeybindInitialized = true;

[
    { !isNull player },
    {
        [
            "FLO",
            "openOperationsPanel",
            ["Open Operations Panel", "Open the FLO theater operations panel."],
            { [] call FLO_fnc_operationsOpenDialog; true },
            {},
            [24, [true, true, false]],
            false
        ] call CBA_fnc_addKeybind;

        diag_log "[FLO][Operations] Ctrl+Shift+O keybind initialized";
    }
] call CBA_fnc_waitUntilAndExecute;
