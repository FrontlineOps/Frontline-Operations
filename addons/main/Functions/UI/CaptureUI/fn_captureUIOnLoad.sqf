/* Owns Capture UI browser setup when the resource display is created. */
params ["_display"];

private _control = _display displayCtrl 1101;
if (isNull _control) then {
    private _message = "Capture UI browser control 1101 is unavailable during onLoad";
    ["UI", 1, _message] call FLO_fnc_log;
    throw _message;
};

uiNamespace setVariable ["FLO_CaptureUI_Display", _display];
FLO_CaptureUI_DisplayOpen = true;
FLO_CaptureUI_HTMLReady = false;

private _event = "JSDialog";
_control ctrlAddEventHandler [_event, {
    params ["_control", "_isConfirmDialog", "_message"];
    [_control, _isConfirmDialog, _message] call FLO_fnc_captureUIHandleUiEvent;
}];

true
