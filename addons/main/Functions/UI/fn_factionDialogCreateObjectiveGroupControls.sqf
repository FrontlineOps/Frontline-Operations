/*
 * Function: FLO_fnc_factionDialogCreateObjectiveGroupControls
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates the mission setup objective group tab controls.
 *
 * Arguments:
 *   0: Dialog display <DISPLAY>
 *
 * Return Value:
 *   None
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {
    ["UI", 1, "Cannot create objective group controls - display is null"] call FLO_fnc_log;
};

private _existing = uiNamespace getVariable ["FLO_FactionObjectiveGroupControls", []];
if (_existing isNotEqualTo [] && {!isNull (_existing select 0)}) exitWith {};

private _anchor = _display displayCtrl 2096;
if (isNull _anchor) exitWith {
    ["UI", 1, "Cannot create objective group controls - anchor is missing"] call FLO_fnc_log;
};

private _anchorPos = ctrlPosition _anchor;
_anchorPos params ["_anchorX", "_anchorY", "_anchorW", "_anchorH"];

private _subtypes = [
    ["capital", "Capital"],
    ["city", "City"],
    ["village", "Village"],
    ["local", "Local"],
    ["marine", "Marine"],
    ["cluster", "Cluster"]
];
private _groupTypes = [
    ["infantry", "Inf"],
    ["motorized", "Mot"],
    ["mechanized", "Mech"],
    ["armor", "Arm"],
    ["air", "Air"],
    ["artillery", "Art"],
    ["mobile_aa", "MAA"],
    ["static_aa", "SAA"]
];

private _controls = [];
private _rowH = _anchorH * 1.16;
private _sideGap = _anchorH * 2;
private _sideW = (_anchorW - _sideGap) / 2;
private _labelW = _sideW * 0.20;
private _cellW = (_sideW - _labelW) / count _groupTypes;
private _titleY = _anchorY - (_rowH * 1.12);
private _headerY = _anchorY;
private _rowStartY = _anchorY + _rowH;

private _layout = createHashMapFromArray [
    ["groupTypes", _groupTypes],
    ["subtypes", _subtypes],
    ["titleY", _titleY],
    ["headerY", _headerY],
    ["rowStartY", _rowStartY],
    ["rowH", _rowH],
    ["sideW", _sideW],
    ["labelW", _labelW],
    ["cellW", _cellW],
    ["anchorH", _anchorH]
];

[_display, _controls, "BLUFOR", "BLUFOR OBJECTIVE GROUPS", _anchorX, 2200, _layout] call FLO_fnc_factionDialogCreateObjectiveSideControls;
[_display, _controls, "OPFOR", "OPFOR OBJECTIVE GROUPS", _anchorX + _sideW + _sideGap, 2248, _layout] call FLO_fnc_factionDialogCreateObjectiveSideControls;

uiNamespace setVariable ["FLO_FactionObjectiveGroupControls", _controls];
