if (!hasInterface) exitWith { false };
if (!FLO_ClientUiReady) exitWith {
    ["Development is unavailable while FLO initializes.", "warning"] call FLO_fnc_displayNotification;
    false
};

private _display = findDisplay FLO_DevelopmentDialogIdd;
if (!isNull _display) exitWith {
    [] call FLO_fnc_developmentRequestSnapshot;
    true
};

createDialog "FLO_DevelopmentDialog";
_display = findDisplay FLO_DevelopmentDialogIdd;
if (isNull _display) exitWith {
    ["The Development panel could not be opened.", "error"] call FLO_fnc_displayNotification;
    false
};

private _control = _display displayCtrl FLO_DevelopmentBrowserIdc;
if (isNull _control) exitWith {
    closeDialog 0;
    ["The Development browser control is unavailable.", "error"] call FLO_fnc_displayNotification;
    false
};

uiNamespace setVariable ["FLO_DevelopmentControl", _control];
FLO_DevelopmentBrowserReady = false;
FLO_DevelopmentLastSnapshot = createHashMap;

[_control] call FLO_fnc_developmentAddWebEventHandler;
_control ctrlWebBrowserAction ["LoadFile", "\z\flo\addons\main\UI\Development\index.html"];
true
