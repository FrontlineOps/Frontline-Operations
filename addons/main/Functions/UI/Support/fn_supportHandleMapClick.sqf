params ["_map", "_button", "_mouseX", "_mouseY"];

if (_button != 0) exitWith { false };

private _worldPosition = _map ctrlMapScreenToWorld [_mouseX, _mouseY];
FLO_SupportTargetPosition = [_worldPosition select 0, _worldPosition select 1, 0];
[] call FLO_fnc_supportUpdateDialog;

true
