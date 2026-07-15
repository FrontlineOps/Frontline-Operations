if (!hasInterface) exitWith { false };
if (!FLO_ClientUiReady) exitWith {
    ["Tactical support is unavailable while FLO initializes.", "warning"] call FLO_fnc_displayNotification;
    false
};
if !((side group player) in [west, east]) exitWith {
    ["Tactical support is unavailable for this side.", "warning"] call FLO_fnc_displayNotification;
    false
};
if (!alive player) exitWith {
    ["Tactical support requires an active player unit.", "warning"] call FLO_fnc_displayNotification;
    false
};

private _display = findDisplay FLO_SupportDialogIdd;
if (!isNull _display) exitWith { true };

createDialog "FLO_SupportDialog";
_display = findDisplay FLO_SupportDialogIdd;
if (isNull _display) exitWith {
    ["The Tactical Support Net could not be opened.", "error"] call FLO_fnc_displayNotification;
    false
};

private _browser = _display displayCtrl FLO_SupportBrowserIdc;
private _map = _display displayCtrl FLO_SupportMapIdc;
if (isNull _browser || {isNull _map}) exitWith {
    closeDialog 0;
    ["The Tactical Support Net controls are unavailable.", "error"] call FLO_fnc_displayNotification;
    false
};

uiNamespace setVariable ["FLO_SupportControl", _browser];
uiNamespace setVariable ["FLO_SupportMapControl", _map];
FLO_SupportBrowserReady = false;
FLO_SupportSelectedType = "ARTY";
FLO_SupportTargetPosition = [];
FLO_SupportLastServerSnapshot = createHashMap;

_map ctrlAddEventHandler ["Draw", {
    [_this select 0] call FLO_fnc_supportDrawMap;
}];
_map ctrlAddEventHandler ["MouseButtonClick", {
    _this call FLO_fnc_supportHandleMapClick;
}];

[_browser] call FLO_fnc_supportAddWebEventHandler;
[_browser, ["LoadFile", "\z\flo\addons\main\UI\Support\index.html"]] call FLO_fnc_supportWebAction;
[] call FLO_fnc_supportRequestSnapshot;

[{
    if (isNull (findDisplay FLO_SupportDialogIdd)) exitWith {};
    [] call FLO_fnc_supportUpdateDialog;
}, [], 1] call CBA_fnc_waitAndExecute;

["UI", 4, "Tactical Support dialog opened and snapshot requested"] call FLO_fnc_log;
["PLAYER"] call FLO_fnc_supportFocusMap;

true
