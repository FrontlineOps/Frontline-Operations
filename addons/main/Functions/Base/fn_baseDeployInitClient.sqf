if (!hasInterface) exitWith { false };
if (FLO_BaseDeployClientInitialized) exitWith { true };

["FLO_Base_FirstFOBClaimed", {
    params ["_claims"];
    [_claims] call FLO_fnc_baseDeployValidateState;
    FLO_BaseFirstFOBClaimedBySide = _claims;
    FLO_BaseDeployRenderKey = "";
    [] call FLO_fnc_baseDeployUpdateDialog;
}] call CBA_fnc_addEventHandler;

[
    "FLO",
    "openDeploymentPanel",
    ["Open Deployment Panel", "Open the FLO FOB/COP deployment panel."],
    { [] call FLO_fnc_baseDeployOpenDialog; true },
    {},
    [32, [true, true, false]],
    false
] call CBA_fnc_addKeybind;

FLO_BaseDeployClientInitialized = true;
["UI", 4, "Deployment event and keybind initialized"] call FLO_fnc_log;
true
