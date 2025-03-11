/**
 * @name IDS_Logistics_fnc_updateEntityList
 * @category Logistics_UI
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Updates the entity list control based on the selected category and search text.
 * Filters entities to show only those matching both the category and search criteria.
 * Sets tooltips with cost information and automatically selects the first item.
 *
 * @param {Control} _control - The category list control
 * @param {Number} _selectedIndex - The index of the selected category
 *
 * @return {Nothing}
 *
 * @example
 * [_categoryListControl, 0] call IDS_Logistics_fnc_updateEntityList
 */

params [
    ["_control", controlNull, [controlNull]],
    ["_selectedIndex", -1, [0]]
];

// Exit if no valid selection
if (_selectedIndex < 0) exitWith {};

// Get the dialog and controls
private _display = ctrlParent _control;
private _category = _control lbData _selectedIndex;
private _entitiesList = _display displayCtrl 9503;

// Clear the existing list content
lbClear _entitiesList;

// Get current search filter text (empty string if none)
private _searchText = toLower (uiNamespace getVariable ["IDS_Logistics_BuildMenu_SearchText", ""]);

// Process each buildable entity
{
    _x params ["_className", "_displayName", "_entityCategory", "_entitySubCategory", "_cost"];
    
    // Skip if doesn't match selected category
    if (_entityCategory != _category) then { continue };
    
    // Skip if doesn't match search text filter
    if (_searchText != "" && {!(toLower _displayName find _searchText > -1)}) then { continue };
    
    // Add matching entity to the list with associated data
    _entitiesList lbAdd _displayName;
    _entitiesList lbSetData [(lbSize _entitiesList) - 1, _className];
    _entitiesList lbSetTooltip [(lbSize _entitiesList) - 1, format ["%1\nCost: %2", _displayName, _cost]];
} forEach IDS_Logistics_buildableEntities;

// Auto-select first item if list is not empty
if (lbSize _entitiesList > 0) then { _entitiesList lbSetCurSel 0; };