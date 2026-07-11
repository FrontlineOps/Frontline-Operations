params [["_showGuide", false, [false]]];

if (!hasInterface) exitWith { false };
if (!FLO_MissionReady) exitWith {
    ["Operations are unavailable while FLO initializes.", "warning"] call FLO_fnc_displayNotification;
    false
};

private _display = findDisplay FLO_OperationsDialogIdd;
if (!isNull _display) exitWith {
    if (_showGuide) then { [] call FLO_fnc_operationsShowGuide; };
    [] call FLO_fnc_operationsRequestSnapshot;
    true
};

if (_showGuide) then { FLO_OperationsGuideRequested = true; };

createDialog "FLO_OperationsDialog";
_display = findDisplay FLO_OperationsDialogIdd;
if (isNull _display) exitWith {
    ["The Operations panel could not be opened.", "error"] call FLO_fnc_displayNotification;
    false
};

private _control = _display displayCtrl FLO_OperationsBrowserIdc;
if (isNull _control) exitWith {
    closeDialog 0;
    ["The Operations browser control is unavailable.", "error"] call FLO_fnc_displayNotification;
    false
};

private _map = _display displayCtrl FLO_OperationsMapIdc;
if (isNull _map) exitWith {
    closeDialog 0;
    ["The Operations map control is unavailable.", "error"] call FLO_fnc_displayNotification;
    false
};

uiNamespace setVariable ["FLO_OperationsControl", _control];
uiNamespace setVariable ["FLO_OperationsMapControl", _map];
FLO_OperationsLastSnapshot = createHashMap;
FLO_OperationsMapDrawData = [];
FLO_OperationsMapNodeDrawData = [];
FLO_OperationsMapRouteDrawData = [];
FLO_OperationsMapEnemyLogisticsIntelDrawData = [];
FLO_OperationsMapThreatSectors = [];
FLO_OperationsMapInitialized = false;
FLO_OperationsSelectedObjectiveId = "";
FLO_OperationsMapDrawPerfStartedAt = diag_tickTime;
FLO_OperationsMapDrawPerfCalls = 0;
FLO_OperationsMapDrawPerfTotal = 0;
FLO_OperationsMapDrawPerfMax = 0;
FLO_OperationsMapDrawPerfObjectiveTotal = 0;

_map ctrlAddEventHandler ["Draw", {
    [_this select 0] call FLO_fnc_operationsDrawMap;
}];
_map ctrlAddEventHandler ["MouseButtonClick", {
    _this call FLO_fnc_operationsHandleMapClick;
}];

[_control] call FLO_fnc_operationsAddWebEventHandler;
[_control, ["LoadFile", "\z\flo\addons\main\UI\Operations\index.html"]] call FLO_fnc_operationsWebAction;

true
