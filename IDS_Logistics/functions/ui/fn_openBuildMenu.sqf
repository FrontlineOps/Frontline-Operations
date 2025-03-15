/**
 * @name IDS_Logistics_fnc_openBuildMenu
 * @category Logistics_UI
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Opens the logistics build menu dialog and initializes all controls.
 * Populates category list from available buildable entities and sets up the UI state.
 *
 * @param {None}
 *
 * @return {Boolean} True if dialog was created successfully, false otherwise
 *
 * @example
 * [] call IDS_Logistics_fnc_openBuildMenu
 */

// Check if dialog is already open
if (!isNull (findDisplay 9500)) exitWith { false };

// Create dialog
private _success = createDialog "IDS_Logistics_BuildMenuDialog";
if (!_success) exitWith { false };

// Get the dialog
private _display = findDisplay 9500;

// Get controls
private _categoryList = _display displayCtrl 9501;
private _entitiesList = _display displayCtrl 9503;
private _searchBox = _display displayCtrl 9502;
private _entityInfo = _display displayCtrl 9504;
private _selectButton = _display displayCtrl 9505;

// Clear lists
lbClear _categoryList;
lbClear _entitiesList;

// Generate categories from available buildable entities
private _categories = [];
{
    private _category = _x select 2;
    if !(_category in _categories) then {
        _categories pushBack _category;
    };
} forEach IDS_Logistics_Entities;

// Fill categories list
{
    _categoryList lbAdd _x;
    _categoryList lbSetData [(lbSize _categoryList) - 1, _x];
} forEach _categories;

// Select first category if available
if (lbSize _categoryList > 0) then {
    _categoryList lbSetCurSel 0;
    
    // Update entity list immediately
    [_categoryList, 0] call IDS_Logistics_fnc_updateEntityList;
    
    // Update preview with first entity if available
    [_display, _entitiesList] spawn {
        params ["_display", "_entitiesList"];
        sleep 0.1;

        if (lbSize _entitiesList > 0) then {
            _entitiesList lbSetCurSel 0;
            [_entitiesList, 0] call IDS_Logistics_fnc_updatePreview;
        };
    };
};

// Clear entity info panel
_entityInfo ctrlSetStructuredText parseText "";

// Initialize search text variable
uiNamespace setVariable ["IDS_Logistics_BuildMenu_SearchText", ""];

// Return success
true