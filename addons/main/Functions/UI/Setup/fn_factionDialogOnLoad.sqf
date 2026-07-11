/*
 * Function: FLO_fnc_factionDialogOnLoad
 * Author: Frontline Operations
 * 
 * Description:
 * Handles the onLoad event for the Faction Selection Dialog.
 * Stores dialog reference, adds escape key handler, and populates dropdowns.
 * 
 * Arguments:
 * None (uses _this from dialog event)
 * 
 * Return Value:
 * None
 * 
 * Example:
 * [] call FLO_fnc_factionDialogOnLoad;
 */

disableSerialization;

private _display = _this select 0;

// Store dialog reference in uiNamespace
uiNamespace setVariable ["FLO_FactionDialog", _display];

// Add escape key handler
private _eh = _display displayAddEventHandler ["KeyDown", {
	params ["_display", "_key"];
	if (_key isEqualTo 1) then {
		closeDialog 0;
		true
	} else {
		false
	}
}];
_display setVariable ["FLO_FactionDialog_EH", _eh];

// Populate dropdowns
[] call FLO_fnc_factionDialogPopulate;

["UI", 3, "Faction dialog loaded"] call FLO_fnc_log;

