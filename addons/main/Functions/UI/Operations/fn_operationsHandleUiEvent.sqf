params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";
private _data = _eventData get "data";
private _map = uiNamespace getVariable ["FLO_OperationsMapControl", controlNull];

switch (_event) do {
    case "operations::ready": {
        uiNamespace setVariable ["FLO_OperationsControl", _control];
        FLO_OperationsBrowserReady = true;
        if ((keys FLO_OperationsLastSnapshot) isNotEqualTo []) then {
            [FLO_OperationsLastSnapshot] call FLO_fnc_operationsUpdateDialog;
        };
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
    case "operations::mapAttack": {
        private _attackId = _data get "attackId";
        private _matched = false;
        {
            if ((_x get "id") != _attackId) then { continue };
            private _targetId = _x get "targetId";
            ["OBJECTIVE", _targetId] call FLO_fnc_operationsFocusMap;
            _matched = true;
        } forEach (FLO_OperationsLastSnapshot get "attacks");
        if (!_matched) then {
            ["UI", 4, format ["Unknown attack focus request: %1", _attackId]] call FLO_fnc_log;
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
        ["UI", 4, format ["Unhandled Operations browser event: %1", _event]] call FLO_fnc_log;
    };
};

if (!isNull _map && {ctrlShown _map}) then {
    [_map] call FLO_fnc_operationsRestoreMapFocus;
    [FLO_fnc_operationsRestoreMapFocus, [_map]] call CBA_fnc_execNextFrame;
};

true
