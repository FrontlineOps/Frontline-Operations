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
    case "deploy::buyTickets": {
        hint "Reinforcement tickets are not used by FLO deployment.";
    };
    case "deploy::close": {
        closeDialog 0;
    };
    default {
        diag_log format ["[FLO][Base] Unhandled deployment UI event: %1", _event];
    };
};

true
