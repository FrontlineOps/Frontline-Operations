params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";

switch (_event) do {
    case "deploy::ready": {
        uiNamespace setVariable ["FLO_DeployControl", _control];
        FLO_BaseDeployBrowserReady = true;
        FLO_BaseDeployRenderKey = "";
        [] call FLO_fnc_baseDeployUpdateDialog;
    };
    case "deploy::refresh": {
        FLO_BaseDeployRenderKey = "";
        [] call FLO_fnc_baseDeployUpdateDialog;
    };
    case "deploy::requestFOB": {
        [player, "FOB"] remoteExecCall ["FLO_fnc_baseDeployRequest", 2];
    };
    case "deploy::requestCOP": {
        [player, "COP"] remoteExecCall ["FLO_fnc_baseDeployRequest", 2];
    };
    case "deploy::close": {
        closeDialog 0;
    };
    default {
        ["UI", 4, format ["Unhandled Deployment browser event: %1", _event]] call FLO_fnc_log;
    };
};

true
