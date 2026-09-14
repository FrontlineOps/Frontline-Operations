params [["_base", objNull, [objNull]]];

if (!hasInterface) exitWith { false };
if (isNull _base) exitWith {
    ["Store is unavailable.", "warning"] call FLO_fnc_displayNotification;
    false
};

FLO_StoreActiveBaseNetId = netId _base;

private _display = findDisplay FLO_StoreDialogIdd;

if (!isNull _display) exitWith {
    [player, FLO_StoreActiveBaseNetId] remoteExecCall ["FLO_fnc_storeRequestHydrate", 2];
    true
};

createDialog "FLO_StoreDialog";
_display = findDisplay FLO_StoreDialogIdd;

if (isNull _display) exitWith {
    ["The Store could not be opened.", "error"] call FLO_fnc_displayNotification;
    false
};

private _control = _display displayCtrl FLO_StoreBrowserIdc;
if (isNull _control) exitWith {
    closeDialog 0;
    ["The Store browser control is unavailable.", "error"] call FLO_fnc_displayNotification;
    false
};
// Create local scene objects after native display construction has returned.
[_display] call FLO_fnc_storePreviewOpen;
uiNamespace setVariable ["FLO_StoreControl", _control];

// Arma browser control event (not yet listed in HEMTT event metadata).
private _webDialogEvent = "JSDialog";
_control ctrlAddEventHandler [_webDialogEvent, FLO_fnc_storeHandleUiEvent];
[_control, ["LoadFile", "\z\flo\addons\main\UI\Store\index.html"]] call FLO_fnc_uiWebAction;

true
