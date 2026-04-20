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

private _fnc_createLabel = {
    params ["_text", "_ctrlX", "_ctrlY", "_ctrlW", "_ctrlH", ["_section", false]];

    private _class = if (_section) then { "FLO_FactionTuneSection" } else { "FLO_FactionTuneLabel" };
    private _ctrl = _display ctrlCreate [_class, -1];
    _ctrl ctrlSetText _text;
    _ctrl ctrlSetPosition [_ctrlX, _ctrlY, _ctrlW, _ctrlH];
    _ctrl ctrlCommit 0;
    _ctrl ctrlShow false;
    _controls pushBack _ctrl;
    _ctrl
};

private _fnc_createEdit = {
    params ["_idc", "_ctrlX", "_ctrlY", "_ctrlW", "_ctrlH", "_tooltip"];

    private _ctrl = _display ctrlCreate ["FLO_FactionTuneEdit", _idc];
    _ctrl ctrlSetTooltip _tooltip;
    _ctrl ctrlSetPosition [_ctrlX, _ctrlY, _ctrlW, _ctrlH];
    _ctrl ctrlCommit 0;
    _ctrl ctrlShow false;
    _controls pushBack _ctrl;
    _ctrl
};

private _fnc_createSide = {
    params ["_sideLabel", "_sideTitle", "_sideX", "_startIdc"];

    [_sideTitle, _sideX, _titleY, _sideW, _anchorH, true] call _fnc_createLabel;
    ["Objective", _sideX, _headerY, _labelW, _anchorH, false] call _fnc_createLabel;

    {
        _x params ["_groupType", "_groupLabel"];
        private _ctrlX = _sideX + _labelW + (_forEachIndex * _cellW);
        [_groupLabel, _ctrlX, _headerY, _cellW, _anchorH, false] call _fnc_createLabel;
    } forEach _groupTypes;

    {
        _x params ["_subtype", "_subtypeLabel"];
        private _rowIndex = _forEachIndex;
        private _rowY = _rowStartY + (_rowIndex * _rowH);
        [_subtypeLabel, _sideX, _rowY, _labelW, _anchorH, false] call _fnc_createLabel;

        {
            _x params ["_groupType", "_groupLabel"];
            private _ctrlX = _sideX + _labelW + (_forEachIndex * _cellW);
            private _idc = _startIdc + (_rowIndex * count _groupTypes) + _forEachIndex;
            private _tooltip = format ["Set %1 %2 %3 objective group count", _sideLabel, _subtypeLabel, _groupLabel];
            [_idc, _ctrlX, _rowY, _cellW, _anchorH, _tooltip] call _fnc_createEdit;
        } forEach _groupTypes;
    } forEach _subtypes;
};

["BLUFOR", "BLUFOR OBJECTIVE GROUPS", _anchorX, 2200] call _fnc_createSide;
["OPFOR", "OPFOR OBJECTIVE GROUPS", _anchorX + _sideW + _sideGap, 2248] call _fnc_createSide;

uiNamespace setVariable ["FLO_FactionObjectiveGroupControls", _controls];
