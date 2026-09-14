/* Build-camera help and feedback share one measured, uncluttered overlay. */
params [["_content", "", [""]], ["_duration", 0, [0]], ["_clearOnly", false, [false]]];

if (_clearOnly || {isNil "IDS_Logistics_Camera"} || {isNull IDS_Logistics_Camera}) exitWith {
    if (!isNil "IDS_Logistics_CameraHintLayer") then { IDS_Logistics_CameraHintLayer cutText ["", "PLAIN"]; };
    if (!isNil "IDS_Logistics_CameraFlashLayer") then { IDS_Logistics_CameraFlashLayer cutText ["", "PLAIN"]; };
};
if (isNil "IDS_Logistics_CameraHintLayer") then { IDS_Logistics_CameraHintLayer = ["IDS_Logistics_Camera_Hint"] call BIS_fnc_rscLayer; };
if (isNil "IDS_Logistics_CameraFlashLayer") then { IDS_Logistics_CameraFlashLayer = ["IDS_Logistics_Camera_Flash"] call BIS_fnc_rscLayer; };

private _temporary = _duration > 0;
private _layer = [IDS_Logistics_CameraHintLayer, IDS_Logistics_CameraFlashLayer] select _temporary;
_layer cutRsc ["RscTitleDisplayEmpty", "PLAIN"];
private _display = uiNamespace getVariable "RscTitleDisplayEmpty";
private _width = 0.30 * safeZoneW;
private _padding = 0.010 * safeZoneW;
private _container = _display ctrlCreate ["RscControlsGroupNoScrollbars", 9999];
private _background = _display ctrlCreate ["RscText", 10003, _container];
private _text = _display ctrlCreate ["RscStructuredText", 10004, _container];
_text ctrlSetPosition [_padding, 0.01 * safeZoneH, _width - 2 * _padding, safeZoneH];
_text ctrlSetFontHeight (0.022 * safeZoneH);
_text ctrlSetStructuredText parseText ("<t color='#EDF2F7'>" + _content + "</t>");
_text ctrlCommit 0;
private _height = (ctrlTextHeight _text + 0.025 * safeZoneH) max (0.05 * safeZoneH);
private _y = if (_temporary) then {safeZoneY + 0.145 * safeZoneH} else {safeZoneY + 0.96 * safeZoneH - _height};
_container ctrlSetPosition [safeZoneX + 0.98 * safeZoneW - _width, _y, _width, _height];
_container ctrlCommit 0;
_background ctrlSetPosition [0, 0, _width, _height];
_background ctrlSetBackgroundColor [0.06, 0.10, 0.14, 0.95];
_background ctrlCommit 0;
_text ctrlSetPosition [_padding, 0.01 * safeZoneH, _width - 2 * _padding, _height - 0.02 * safeZoneH];
_text ctrlCommit 0;

// Camera teardown clears both layers; delayed expiry owns only this container.
if (_temporary) then {
    [{params ["_container"]; if (!isNull _container) then {ctrlDelete _container};}, [_container], _duration] call CBA_fnc_waitAndExecute;
};
