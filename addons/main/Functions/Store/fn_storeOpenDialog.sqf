params [["_base", objNull, [objNull]]];

if (!hasInterface) exitWith { false };
if (isNull _base) exitWith {
    hint "Store is unavailable.";
    false
};

FLO_StoreActiveBaseNetId = netId _base;

private _display = findDisplay FLO_StoreDialogIdd;

if (!isNull _display) exitWith {
    [player, FLO_StoreActiveBaseNetId] remoteExecCall ["FLO_fnc_storeRequestHydrate", 2];
    true
};

createDialog "FLO_StoreDialog";
_display = findDisplay FLO_StoreDialogIdd;

if (isNull _display) exitWith { false };

private _control = _display displayCtrl FLO_StoreBrowserIdc;
uiNamespace setVariable ["FLO_StoreControl", _control];

[_control] call FLO_fnc_storeAddWebEventHandler;
[_control, ["LoadFile", "\z\flo\addons\main\UI\Store\index.html"]] call FLO_fnc_storeWebAction;

true
