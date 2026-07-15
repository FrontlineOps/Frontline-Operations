if (!hasInterface) exitWith { false };

private _parent = findDisplay FLO_StoreDialogIdd;
if (isNull _parent) exitWith {
    ["Open the Store before managing kits.", "warning"] call FLO_fnc_displayNotification;
    false
};

private _display = findDisplay FLO_StoreKitsDialogIdd;
if (!isNull _display) exitWith {
    private _payload = [true, ""] call FLO_fnc_storeBuildKitsPayload;
    [_payload] call FLO_fnc_storeUpdateKitsDialog;
    true
};

_display = _parent createDisplay "FLO_StoreKitsDialog";
if (isNull _display) exitWith {
    ["The saved-kits display could not be opened.", "error"] call FLO_fnc_displayNotification;
    false
};

private _control = _display displayCtrl FLO_StoreKitsBrowserIdc;
if (isNull _control) exitWith {
    _display closeDisplay 1;
    ["The saved-kits browser control is unavailable.", "error"] call FLO_fnc_displayNotification;
    false
};

uiNamespace setVariable ["FLO_StoreKitsControl", _control];
[_control] call FLO_fnc_storeAddKitsWebEventHandler;
[_control, ["LoadFile", "\z\flo\addons\main\UI\Store\kits.html"]] call FLO_fnc_storeWebAction;
true
