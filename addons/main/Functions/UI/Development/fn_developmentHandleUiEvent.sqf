params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";
private _data = _eventData get "data";

switch (_event) do {
    case "development::ready": {
        uiNamespace setVariable ["FLO_DevelopmentControl", _control];
        FLO_DevelopmentBrowserReady = true;
        if ((keys FLO_DevelopmentLastSnapshot) isNotEqualTo []) then {
            [FLO_DevelopmentLastSnapshot] call FLO_fnc_developmentUpdateDialog;
        };
        [] call FLO_fnc_developmentRequestSnapshot;
    };
    case "development::refresh": {
        [] call FLO_fnc_developmentRequestSnapshot;
    };
    case "development::assignShipment": {
        [player, _data get "objectiveId"] remoteExecCall ["FLO_fnc_objectiveDevelopmentAssignShipment", 2];
    };
    case "development::operationsOpen": {
        closeDialog 0;
        [FLO_fnc_operationsOpenDialog, []] call CBA_fnc_execNextFrame;
    };
    case "development::close": {
        closeDialog 0;
    };
    default {
        ["UI", 4, format ["Unhandled Development browser event: %1", _event]] call FLO_fnc_log;
    };
};

true
