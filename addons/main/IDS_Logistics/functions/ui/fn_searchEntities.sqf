/**
 * @name IDS_Logistics_fnc_searchEntities
 * @category Logistics_UI
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Handles search functionality in the build menu.
 * Extracts search text from the input control, stores it,
 * and triggers an update of the entity list based on the search text.
 *
 * @param {Control} _control - The search input control
 * @param {Number} _key - The key code of the pressed key (unused but provided by onKeyUp event)
 *
 * @return {Nothing}
 *
 * @example
 * [_searchBoxControl, _keyCode] call IDS_Logistics_fnc_searchEntities
 */

params [
    ["_control", controlNull, [controlNull]],
    ["_key", 0, [0]]
];

// Extract search text from control
private _searchText = ctrlText _control;

// Store search text in UI namespace for filtering
uiNamespace setVariable ["IDS_Logistics_BuildMenu_SearchText", _searchText];

// Get parent display and category list
private _display = ctrlParent _control;
private _categoryList = _display displayCtrl 9501;
private _selectedIndex = lbCurSel _categoryList;

// Update entity list if a category is selected
if (_selectedIndex >= 0) then { [_categoryList, _selectedIndex] call IDS_Logistics_fnc_updateEntityList; };
