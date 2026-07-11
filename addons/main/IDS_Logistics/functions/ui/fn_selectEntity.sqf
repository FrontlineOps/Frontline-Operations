/**
 * @name IDS_Logistics_fnc_selectEntity
 * @category Logistics_UI
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Handles entity selection from the build menu.
 * Retrieves the selected entity class from the list control,
 * closes the dialog, and initiates the placement process.
 *
 * @param {None} - Called from UI button click
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_selectEntity
 */

// Get the dialog
private _display = findDisplay 9500;

// Get the entities list
private _entitiesList = _display displayCtrl 9503;

// Get the selected index
private _selectedIndex = lbCurSel _entitiesList;

// Check if something is selected
if (_selectedIndex < 0) exitWith { hint "No entity selected"; };

// Get the selected class
private _className = _entitiesList lbData _selectedIndex;

// Close dialog
closeDialog 0;

// Start placement
[_className] call IDS_Logistics_fnc_startPlacement;
