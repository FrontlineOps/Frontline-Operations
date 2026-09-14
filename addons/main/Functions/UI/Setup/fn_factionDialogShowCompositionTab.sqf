/*
 * Function: FLO_fnc_factionDialogShowCompositionTab
 * Author: Frontline Operations Development Group
 * Description:
 *   Switches the mission setup composition card between numeric composition
 *   and objective group templates.
 *
 * Arguments:
 *   0: Tab <STRING> - "composition" or "objectives"
 *
 * Return Value:
 *   None
 */

disableSerialization;

params [["_tab", "composition", [""]]];

private _display = uiNamespace getVariable ["FLO_FactionDialog", displayNull];
if (isNull _display) exitWith {
    ["UI", 1, "Cannot switch composition tab - display is null"] call FLO_fnc_log;
};

private _objectiveSelected = (toLower _tab) isEqualTo "objectives";
private _objectiveVisible = _objectiveSelected;
private _compositionVisible = !_objectiveSelected;
{ _x ctrlShow _compositionVisible } forEach (_display getVariable "FLO_SetupNumericControls");
{ _x ctrlShow _objectiveVisible } forEach (uiNamespace getVariable ["FLO_FactionObjectiveGroupControls", []]);

(_display displayCtrl 2094) ctrlSetBackgroundColor (if (_compositionVisible) then {[0.35, 0.35, 0.35, 1]} else {[0.20, 0.20, 0.20, 1]});
(_display displayCtrl 2095) ctrlSetBackgroundColor ([[0.20, 0.20, 0.20, 1], [0.35, 0.35, 0.35, 1]] select (_objectiveVisible));

uiNamespace setVariable ["FLO_FactionCompositionTab", ["composition", "objectives"] select _objectiveSelected];
