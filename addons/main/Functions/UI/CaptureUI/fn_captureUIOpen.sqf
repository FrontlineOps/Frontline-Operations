/* Opens the named Capture UI resource layer for the current objective. */
if (!hasInterface) exitWith { false };
if (FLO_CaptureUI_CurrentObj == "") exitWith { false };
if (FLO_CaptureUI_DisplayOpen) exitWith {
    if (FLO_CaptureUI_HTMLReady) then {
        [] call FLO_fnc_captureUIRender;
    };
    true
};

if (FLO_CaptureUI_Layer < 0) then {
    private _message = "Capture UI named resource layer is not initialized";
    ["UI", 1, _message] call FLO_fnc_log;
    throw _message;
};

FLO_CaptureUI_HTMLReady = false;
FLO_CaptureUI_Layer cutRsc ["FLO_CaptureUI", "PLAIN", 0, false];

[{
    if (FLO_CaptureUI_CurrentObj != "" && {!FLO_CaptureUI_DisplayOpen}) then {
        private _message = "Capture UI resource display did not load";
        ["UI", 1, _message] call FLO_fnc_log;
        throw _message;
    };
}, []] call CBA_fnc_execNextFrame;

true
