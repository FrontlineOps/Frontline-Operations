params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";

switch (_event) do {
    case "captureUI::ready": {
        FLO_CaptureUI_HTMLReady = true;
        [] call FLO_fnc_captureUIRender;
        ["UI", 4, "Capture UI browser ready"] call FLO_fnc_log;
    };
    default {
        ["UI", 4, format ["Unhandled Capture UI browser event: %1", _event]] call FLO_fnc_log;
    };
};

true
