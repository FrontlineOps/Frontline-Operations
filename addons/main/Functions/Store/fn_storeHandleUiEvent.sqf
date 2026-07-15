params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";
private _data = createHashMap;

if ("data" in _eventData) then {
    _data = _eventData get "data";
};

switch (_event) do {
    case "store::ready": {
        uiNamespace setVariable ["FLO_StoreControl", _control];
        [player, FLO_StoreActiveBaseNetId] remoteExecCall ["FLO_fnc_storeRequestHydrate", 2];
    };
    case "store::category": {
        [player, FLO_StoreActiveBaseNetId, _data get "category"] remoteExecCall ["FLO_fnc_storeRequestCategory", 2];
    };
    case "store::checkout": {
        [player, FLO_StoreActiveBaseNetId, _data get "items"] remoteExecCall ["FLO_fnc_storeRequestCheckout", 2];
    };
    case "store::refresh": {
        [player, FLO_StoreActiveBaseNetId] remoteExecCall ["FLO_fnc_storeRequestHydrate", 2];
    };
    case "store::kitsOpen": {
        [] call FLO_fnc_storeOpenKitsDialog;
    };
    case "store::close": {
        closeDialog 0;
    };
    default {
        ["UI", 4, format ["Unhandled Store browser event: %1", _event]] call FLO_fnc_log;
    };
};

true
