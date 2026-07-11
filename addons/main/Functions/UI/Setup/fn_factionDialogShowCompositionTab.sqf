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

private _objectiveVisible = (toLower _tab) isEqualTo "objectives";
private _compositionVisible = !_objectiveVisible;
private _objectiveControls = uiNamespace getVariable ["FLO_FactionObjectiveGroupControls", []];

private _anchor = _display displayCtrl 2096;
private _bottomCtrl = _display displayCtrl 2093;
if (isNull _anchor || {isNull _bottomCtrl}) exitWith {
    ["UI", 1, "Cannot switch composition tab - anchor controls are missing"] call FLO_fnc_log;
};

private _anchorPos = ctrlPosition _anchor;
private _bottomPos = ctrlPosition _bottomCtrl;
private _top = (_anchorPos select 1) - ((_anchorPos select 3) * 1.8);
private _bottom = (_bottomPos select 1) + (_bottomPos select 3) + 0.01;

{
    private _idc = ctrlIDC _x;
    private _pos = ctrlPosition _x;
    private _y = _pos select 1;

    if (_y >= _top && {_y <= _bottom} && {!(_x in _objectiveControls)} && {!(_idc in [2094, 2095, 2096])}) then {
        _x ctrlShow _compositionVisible;
    };
} forEach (allControls _display);

{
    _x ctrlShow _objectiveVisible;
} forEach _objectiveControls;

(_display displayCtrl 2094) ctrlSetBackgroundColor (if (_compositionVisible) then {[0.35, 0.35, 0.35, 1]} else {[0.20, 0.20, 0.20, 1]});
(_display displayCtrl 2095) ctrlSetBackgroundColor ([[0.20, 0.20, 0.20, 1], [0.35, 0.35, 0.35, 1]] select (_objectiveVisible));

uiNamespace setVariable ["FLO_FactionCompositionTab", ["composition", "objectives"] select (_objectiveVisible)];
