params ["_display"];
// An unload can follow a failed display creation, before preview ownership begins.
if (isNil {_display getVariable "FLO_StorePreview"}) exitWith {};
private _state = _display getVariable "FLO_StorePreview";
private _camera = _state get "camera";
_camera cameraEffect ["Terminate", "Back"];
camDestroy _camera;
deleteVehicle (_state get "man");
deleteVehicle (_state get "model");
deleteVehicle (_state get "light");
deleteVehicle (_state get "backdrop");
_display setVariable ["FLO_StorePreview", nil];
["STORE", 3, "Closed local Store preview"] call FLO_fnc_log;
