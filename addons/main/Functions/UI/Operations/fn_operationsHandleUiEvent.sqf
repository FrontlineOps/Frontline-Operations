params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";
private _data = _eventData get "data";
private _map = uiNamespace getVariable ["FLO_OperationsMapControl", controlNull];

switch (_event) do {
    case "operations::ready": {
        uiNamespace setVariable ["FLO_OperationsControl", _control];
        FLO_OperationsBrowserReady = true;
        [] call FLO_fnc_operationsRequestSnapshot;
        if (FLO_OperationsGuideRequested) then {
            [FLO_fnc_operationsShowGuide, []] call CBA_fnc_execNextFrame;
        };
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
    case "operations::mapOperation": {
        private _operationId = _data get "operationId";
        private _matched = false;
        {
            if ((_x get "id") != _operationId) then { continue };
            private _targetId = _x get "targetId";
            if (_targetId != "") then {
                ["OBJECTIVE", _targetId] call FLO_fnc_operationsFocusMap;
            } else {
                private _sector = _x get "threatSector";
                if (_sector get "visible") then {
                    ["POSITION", "", _sector get "position"] call FLO_fnc_operationsFocusMap;
                };
            };
            _matched = true;
        } forEach (FLO_OperationsLastSnapshot get "operations");
        if (!_matched) then {
            diag_log format ["[FLO][Operations] Unknown operation focus request: %1", _operationId];
        };
    };
    case "operations::selectObjective": {
        [_data get "objectiveId", true] call FLO_fnc_operationsSelectObjective;
    };
    case "operations::developmentOpen": {
        closeDialog 0;
        [FLO_fnc_developmentOpenDialog, []] call CBA_fnc_execNextFrame;
    };
    case "operations::guideOpen": {
        if (!isNull _map) then { _map ctrlShow false; };
    };
    case "operations::guideComplete": {
        profileNamespace setVariable ["FLO_GuideSeenVersion", FLO_OperationsGuideVersion];
        saveProfileNamespace;
        if (!isNull _map) then { _map ctrlShow true; };
    };
    case "operations::close": {
        closeDialog 0;
    };
    default {
        diag_log format ["[FLO][Operations] Unhandled browser event: %1", _event];
    };
};

if (!isNull _map && {ctrlShown _map}) then {
    [_map] call FLO_fnc_operationsRestoreMapFocus;
    [FLO_fnc_operationsRestoreMapFocus, [_map]] call CBA_fnc_execNextFrame;
};

true
