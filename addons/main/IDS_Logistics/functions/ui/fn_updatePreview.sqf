/**
 * @name IDS_Logistics_fnc_updatePreview
 * @category Logistics_UI
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Updates the 3D preview model and information panel in the build menu.
 * Displays the selected entity's visual model and detailed information 
 * including category and resource cost.
 *
 * @param {Control} _control - The entities list control
 * @param {Number} _selectedIndex - The index of the selected entity
 *
 * @return {Nothing}
 *
 * @example
 * [_entitiesListControl, 2] call IDS_Logistics_fnc_updatePreview
 */

params [
    ["_control", controlNull, [controlNull]],
    ["_selectedIndex", -1, [0]]
];

// Exit if no valid selection
if (_selectedIndex < 0) exitWith {};

// Get the dialog and controls
private _display = ctrlParent _control;
private _className = _control lbData _selectedIndex;
private _entityInfo = _display displayCtrl 9504;

// Find the full entity data from global array
private _entityData = [];
{
    if (_x select 0 == _className) exitWith { _entityData = _x; };
} forEach IDS_Logistics_Entities;

// Handle case where entity data is not found
if (_entityData isEqualTo []) exitWith {
    _entityInfo ctrlSetStructuredText parseText "<t color='#FF0000'>Error: Entity data not found</t>";
};

// Extract entity data components
_entityData params ["_className", "_category", "_cost"];

// Get display name from config
private _cfg = configFile >> "CfgVehicles" >> _className;
private _displayName = if (isClass _cfg) then {
    getText (_cfg >> "displayName")
} else {
    _className
};

// Load and set 3D preview model
private _model = getText (configFile >> "CfgVehicles" >> _className >> "model");
private _previewCtrl = _display displayCtrl 9506;
_previewCtrl ctrlSetModel _model;

// Frame each model by its real dimensions; one fixed scale makes small props unreadable.
private _sample = createSimpleObject [_model, [worldSize + 1000, worldSize + 1000, 1000], true];
if (!isNull _sample) then {
    private _bounds = boundingBoxReal [_sample, "Geometry"];
    if ((_bounds select 0) isEqualTo (_bounds select 1)) then { _bounds = boundingBoxReal _sample; };
    private _extent = (_bounds select 1) vectorDiff (_bounds select 0);
    deleteVehicle _sample;
    private _scale = 0.14 / ((selectMax _extent) max 0.1);
    _display setVariable ["IDS_Logistics_previewBaseScale", _scale];
    uiNamespace setVariable ["IDS_Logistics_previewZoom", _scale];
    _previewCtrl ctrlSetModelScale _scale;
};

// Format and update detailed entity information panel
private _infoText = format [
    "<t size='1.1' color='#EDF4FA'>%1</t><br/><t color='#BED2E1'>%2</t><br/><t color='#F0D191'>Cost: %3</t>",
    [_displayName] call FLO_fnc_notificationEscapeStructuredText,
    [_category] call FLO_fnc_notificationEscapeStructuredText,
    _cost
];

_entityInfo ctrlSetStructuredText parseText _infoText;
