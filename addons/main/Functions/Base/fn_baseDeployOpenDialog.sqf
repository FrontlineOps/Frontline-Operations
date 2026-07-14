if (!hasInterface) exitWith { false };

if (!FLO_ClientUiReady) exitWith {
    ["Deployment is available after mission setup completes.", "warning"] call FLO_fnc_displayNotification;
    false
};

private _side = side group player;
if !(_side in [west, east]) exitWith {
    ["Deployment is only available to BLUFOR and OPFOR.", "warning"] call FLO_fnc_displayNotification;
    false
};

private _display = findDisplay FLO_BaseDeployDialogIdd;

if (!isNull _display) exitWith {
    FLO_BaseDeployRenderKey = "";
    [] call FLO_fnc_baseDeployUpdateDialog;
    true
};

createDialog "FLO_DeployDialog";
_display = findDisplay FLO_BaseDeployDialogIdd;

if (isNull _display) exitWith {
    ["The Deployment panel could not be opened.", "error"] call FLO_fnc_displayNotification;
    false
};

FLO_BaseDeployBrowserReady = false;
FLO_BaseDeployRenderKey = "";

private _control = _display displayCtrl FLO_BaseDeployBrowserIdc;
if (isNull _control) exitWith {
    closeDialog 0;
    ["The Deployment browser control is unavailable.", "error"] call FLO_fnc_displayNotification;
    false
};
uiNamespace setVariable ["FLO_DeployControl", _control];

[_control] call FLO_fnc_baseDeployAddWebEventHandler;
[_control, ["LoadFile", "\z\flo\addons\main\UI\Deploy\index.html"]] call FLO_fnc_baseDeployWebAction;

true
