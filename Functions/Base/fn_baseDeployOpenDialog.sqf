if (!hasInterface) exitWith { false };

if !(missionNamespace getVariable ["FLO_MissionReady", false]) exitWith {
    hint "Deployment is available after mission setup completes.";
    false
};

private _side = side group player;
if !(_side in [west, east]) exitWith {
    hint "Deployment is only available to BLUFOR and OPFOR.";
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

if (isNull _display) exitWith { false };

FLO_BaseDeployBrowserReady = false;
FLO_BaseDeployRenderKey = "";

private _control = _display displayCtrl FLO_BaseDeployBrowserIdc;
uiNamespace setVariable ["FLO_DeployControl", _control];

[_control] call FLO_fnc_baseDeployAddWebEventHandler;
[_control, ["LoadFile", "UI\Deploy\index.html"]] call FLO_fnc_baseDeployWebAction;

true
