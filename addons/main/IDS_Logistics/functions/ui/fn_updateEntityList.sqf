/**
 * @name IDS_Logistics_fnc_updateEntityList
 * @category Logistics_UI
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Updates the entities list in the build menu based on the selected category.
 * Filters entities by category and search text, then populates the list control.
 *
 * @param {Control} _categoryList - The category list control
 * @param {Number} _selectedIndex - The selected category index
 *
 * @return {Nothing}
 *
 * @example
 * [_categoryList, 0] call IDS_Logistics_fnc_updateEntityList;
 */

params [
    ["_categoryList", controlNull, [controlNull]],
    ["_selectedIndex", -1, [0]]
];

// Get the dialog
private _display = ctrlParent _categoryList;

// Get the entities list
private _entitiesList = _display displayCtrl 9503;

// Get the search box
private _searchBox = _display displayCtrl 9502;

// Get the search text
private _searchText = toLower (ctrlText _searchBox);

// Clear the entities list
lbClear _entitiesList;

// Get the selected category
private _category = _categoryList lbData _selectedIndex;

// Get entities for the selected category
private _categoryEntities = [_category] call IDS_Logistics_fnc_getEntitiesByCategory;

// Populate the entities list
{
    _x params ["_className", "_entityCategory", "_cost"];
    
    // Get display name from config
    private _cfg = configFile >> "CfgVehicles" >> _className;
    private _displayName = if (isClass _cfg) then {
        getText (_cfg >> "displayName")
    } else {
        _className // Fallback to className if config not found
    };
    
    // Skip if doesn't match search text filter
    if (_searchText != "" && {(toLower _displayName find _searchText) < 0}) then { continue };
    
    // Add matching entity to the list with associated data
    _entitiesList lbAdd _displayName;
    _entitiesList lbSetData [(lbSize _entitiesList) - 1, _className];
    _entitiesList lbSetTooltip [(lbSize _entitiesList) - 1, format ["%1\nCost: %2", _displayName, _cost]];
} forEach _categoryEntities;

// Auto-select first item if list is not empty
if (lbSize _entitiesList > 0) then { _entitiesList lbSetCurSel 0; };
