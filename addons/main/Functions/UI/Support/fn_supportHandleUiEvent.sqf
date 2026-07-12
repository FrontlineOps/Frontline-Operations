params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";
private _data = _eventData get "data";

switch (_event) do {
    case "support::ready": {
        uiNamespace setVariable ["FLO_SupportControl", _control];
        FLO_SupportBrowserReady = true;
        [] call FLO_fnc_supportUpdateDialog;
    };
    case "support::select": {
        private _type = toUpper (_data get "type");
        if !(_type in ["ARTY", "CAS", "CAP"]) then {
            throw format ["FLO_fnc_supportHandleUiEvent: unsupported support type %1", _type];
        };
        FLO_SupportSelectedType = _type;
        [] call FLO_fnc_supportUpdateDialog;
    };
    case "support::mapPlayer": {
        ["PLAYER"] call FLO_fnc_supportFocusMap;
    };
    case "support::mapTarget": {
        ["TARGET"] call FLO_fnc_supportFocusMap;
    };
    case "support::submit": {
        if (FLO_SupportTargetPosition isEqualTo []) then {
            ["Designate a target on the Tactical Support map.", "warning"] call FLO_fnc_displayNotification;
        } else {
            private _type = FLO_SupportSelectedType;
            private _target = +FLO_SupportTargetPosition;
            closeDialog 0;
            [FLO_fnc_gtnSubmitPlayerSupportRequest, [_type, _target]] call CBA_fnc_execNextFrame;
        };
    };
    case "support::close": {
        closeDialog 0;
    };
    default {
        diag_log format ["[FLO][Support] Unhandled browser event: %1", _event];
    };
};

true
