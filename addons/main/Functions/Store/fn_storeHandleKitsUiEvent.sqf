params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";
private _data = createHashMap;
if ("data" in _eventData) then {
    _data = _eventData get "data";
};

switch (_event) do {
    case "storeKits::ready";
    case "storeKits::refresh": {
        uiNamespace setVariable ["FLO_StoreKitsControl", _control];
        private _payload = [true, ""] call FLO_fnc_storeBuildKitsPayload;
        [_payload] call FLO_fnc_storeUpdateKitsDialog;
    };
    case "storeKits::save": {
        private _result = [_data get "name"] call FLO_fnc_storeSavedKitsSave;
        private _payload = [
            _result get "success",
            _result get "message"
        ] call FLO_fnc_storeBuildKitsPayload;
        [_payload] call FLO_fnc_storeUpdateKitsDialog;
    };
    case "storeKits::delete": {
        private _result = [_data get "id"] call FLO_fnc_storeSavedKitsDelete;
        private _payload = [
            _result get "success",
            _result get "message"
        ] call FLO_fnc_storeBuildKitsPayload;
        [_payload] call FLO_fnc_storeUpdateKitsDialog;
    };
    case "storeKits::load": {
        private _kitId = _data get "id";
        private _kit = createHashMap;
        {
            if ((_x get "id") == _kitId) exitWith {
                _kit = _x;
            };
        } forEach ([] call FLO_fnc_storeSavedKitsLoad);

        if ((keys _kit) isEqualTo []) then {
            [[false, "Saved kit no longer exists."] call FLO_fnc_storeBuildKitsPayload] call FLO_fnc_storeUpdateKitsDialog;
        } else {
            ["store::kitLoaded", createHashMapFromArray [
                ["success", true],
                ["message", ""],
                ["kit", _kit]
            ]] call FLO_fnc_storeUpdateDialog;

            private _display = findDisplay FLO_StoreKitsDialogIdd;
            if (!isNull _display) then {
                _display closeDisplay 1;
            };
        };
    };
    case "storeKits::close": {
        private _display = findDisplay FLO_StoreKitsDialogIdd;
        if (!isNull _display) then {
            _display closeDisplay 1;
        };
    };
    default {
        ["UI", 4, format ["Unhandled Store kits browser event: %1", _event]] call FLO_fnc_log;
    };
};

true
