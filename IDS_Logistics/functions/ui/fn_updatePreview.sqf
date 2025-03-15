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
 * including category, subcategory, class name, and resource cost.
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
if (count _entityData == 0) exitWith {
    _entityInfo ctrlSetStructuredText parseText "<t color='#FF0000'>Error: Entity data not found</t>";
};

// Extract entity data components
_entityData params ["_className", "_displayName", "_category", "_subCategory", "_cost"];

// Load and set 3D preview model
private _model = getText (configFile >> "CfgVehicles" >> _className >> "model");
private _previewCtrl = _display displayCtrl 9506;
_previewCtrl ctrlSetModel _model;

// Format and update detailed entity information panel
private _infoText = format [
    "<t size='1.2' color='#FFFFFF'>%1</t><br/>" + 
    "<t>Category: </t><t color='#AAAAFF'>%2</t><br/>" + 
    "<t>Subcategory: </t><t color='#AAAAFF'>%3</t><br/>" + 
    "<t>Class: </t><t color='#AAAAFF'>%4</t><br/>" + 
    "<t>Cost: </t><t color='#FFAA00'>%5</t>",
    _displayName, _category, _subCategory, _className, _cost
];

_entityInfo ctrlSetStructuredText parseText _infoText;