/* The display owns every preview object. Nothing is created on the server. */
params ["_display"];
if (!hasInterface || {isNull _display}) exitWith {false};
private _position = [worldSize + 1000, worldSize + 1000, 1000];
private _man = (typeOf player) createVehicleLocal _position;
if (isNull _man) then {throw "Store preview: failed to create local mannequin"};
_man setPosASL _position;
_man enableSimulation false;
_man allowDamage false;
_man disableAI "ALL";
_man setUnitLoadout (getUnitLoadout player);
_man setFace (face player);
_man setDir 0;
_man switchMove "AmovPercMstpSnonWnonDnon";
// The built-in editor sphere provides a local neutral floor and backdrop.
private _backdrop = createSimpleObject ["Sphere_3DEN", _position, true];
private _camera = "camera" camCreate _position;
_camera cameraEffect ["Internal", "Back"];
showCinemaBorder false;
_camera camSetFov 0.7;
private _light = "#lightpoint" createVehicleLocal _position;
_light setLightDayLight true;
_light setLightAmbient [0.6, 0.65, 0.72];
_light setLightColor [1, 0.95, 0.9];
_light setLightBrightness 3;
_display setVariable ["FLO_StorePreview", createHashMapFromArray [
    ["camera", _camera], ["man", _man], ["model", objNull], ["light", _light], ["backdrop", _backdrop],
    ["position", _position], ["baseline", getUnitLoadout player],
    ["subject", _man], ["angle", 135], ["pitch", 8], ["zoom", 1],
    ["mode", "character"], ["selection", createHashMap],
    ["viewport", [0.42, 0.18, 0.32, 0.5]]
]];
[_display] call FLO_fnc_storePreviewUpdateCamera;
["STORE", 3, "Opened local Store preview"] call FLO_fnc_log;
true
