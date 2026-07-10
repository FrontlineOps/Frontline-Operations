params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";
private _data = _eventData get "data";

switch (_event) do {
    case "operations::ready": {
        uiNamespace setVariable ["FLO_OperationsControl", _control];
        FLO_OperationsBrowserReady = true;
        [] call FLO_fnc_operationsRequestSnapshot;
    };
    case "operations::refresh": {
        [] call FLO_fnc_operationsRequestSnapshot;
    };
    case "operations::mapFit": {
        ["FIT"] call FLO_fnc_operationsFocusMap;
    };
    case "operations::mapPlayer": {
        ["PLAYER"] call FLO_fnc_operationsFocusMap;
    };
    case "operations::mapTarget": {
        ["TARGET"] call FLO_fnc_operationsFocusMap;
    };
    case "operations::selectObjective": {
        [_data get "objectiveId", true] call FLO_fnc_operationsSelectObjective;
    };
    case "operations::close": {
        closeDialog 0;
    };
    default {
        diag_log format ["[FLO][Operations] Unhandled browser event: %1", _event];
    };
};

private _map = uiNamespace getVariable ["FLO_OperationsMapControl", controlNull];
if (!isNull _map) then {
    [_map] call FLO_fnc_operationsRestoreMapFocus;
    [FLO_fnc_operationsRestoreMapFocus, [_map]] call CBA_fnc_execNextFrame;
};

true
