/*
 * Function: FLO_fnc_factionDialogOnUnload
 * Author: Frontline Operations
 * 
 * Description:
 * Handles the onUnload event for the Faction Selection Dialog.
 * Cleans up event handlers and clears dialog reference.
 * 
 * Arguments:
 * None (uses _this from dialog event)
 * 
 * Return Value:
 * None
 * 
 * Example:
 * [] call FLO_fnc_factionDialogOnUnload;
 */

disableSerialization;

private _display = _this select 0;

// Remove escape key handler
private _eh = _display getVariable ["FLO_FactionDialog_EH", -1];
if (_eh >= 0) then {
	_display displayRemoveEventHandler ["KeyDown", _eh];
};

// Clear dialog reference
uiNamespace setVariable ["FLO_FactionDialog", displayNull];
uiNamespace setVariable ["FLO_FactionObjectiveGroupControls", []];
uiNamespace setVariable ["FLO_FactionCompositionTab", "composition"];

["UI", 3, "Faction dialog unloaded"] call FLO_fnc_log;

