if (!hasInterface) exitWith { false };
if (FLO_OperationsKeybindInitialized) exitWith { true };

[
    "FLO",
    "openOperationsPanel",
    ["Open Operations Panel", "Open the FLO theater operations panel."],
    { [] call FLO_fnc_operationsOpenDialog; true },
    {},
    [24, [true, true, false]],
    false
] call CBA_fnc_addKeybind;

["FLO_ClientUIReady", {
    private _seenVersion = profileNamespace getVariable ["FLO_GuideSeenVersion", 0];
    if (_seenVersion < FLO_OperationsGuideVersion) then {
        [true] call FLO_fnc_operationsOpenDialog;
    };
}] call CBA_fnc_addEventHandler;

FLO_OperationsKeybindInitialized = true;
["UI", 4, "Operations keybind and onboarding event initialized"] call FLO_fnc_log;
true
