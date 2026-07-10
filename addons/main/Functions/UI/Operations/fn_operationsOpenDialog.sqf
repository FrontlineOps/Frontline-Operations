if (!hasInterface) exitWith { false };
if (!FLO_MissionReady) exitWith {
    hint "Operations are unavailable while FLO initializes.";
    false
};

private _display = findDisplay FLO_OperationsDialogIdd;
if (!isNull _display) exitWith {
    [] call FLO_fnc_operationsRequestSnapshot;
    true
};

createDialog "FLO_OperationsDialog";
_display = findDisplay FLO_OperationsDialogIdd;
if (isNull _display) exitWith {
    hint "The Operations panel could not be opened.";
    false
};

private _control = _display displayCtrl FLO_OperationsBrowserIdc;
if (isNull _control) exitWith {
    closeDialog 0;
    hint "The Operations browser control is unavailable.";
    false
};

private _map = _display displayCtrl FLO_OperationsMapIdc;
if (isNull _map) exitWith {
    closeDialog 0;
    hint "The Operations map control is unavailable.";
    false
};

uiNamespace setVariable ["FLO_OperationsControl", _control];
uiNamespace setVariable ["FLO_OperationsMapControl", _map];
FLO_OperationsLastSnapshot = createHashMap;
FLO_OperationsMapDrawData = [];
FLO_OperationsMapNodeDrawData = [];
FLO_OperationsMapRouteDrawData = [];
FLO_OperationsMapEnemyLogisticsIntelDrawData = [];
FLO_OperationsMapThreatSector = createHashMapFromArray [["visible", false]];
FLO_OperationsMapInitialized = false;
FLO_OperationsSelectedObjectiveId = "";

_map ctrlAddEventHandler ["Draw", {
    [_this select 0] call FLO_fnc_operationsDrawMap;
}];
_map ctrlAddEventHandler ["MouseButtonClick", {
    _this call FLO_fnc_operationsHandleMapClick;
}];

[_control] call FLO_fnc_operationsAddWebEventHandler;
[_control, ["LoadFile", "\z\flo\addons\main\UI\Operations\index.html"]] call FLO_fnc_operationsWebAction;

true
