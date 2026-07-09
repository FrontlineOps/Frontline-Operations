/*
 * Function: FLO_fnc_factionDialogCreateObjectiveSideControls
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates one side's objective composition grid controls.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Control registry <ARRAY>
 * 2: Side label <STRING>
 * 3: Side title <STRING>
 * 4: X <NUMBER>
 * 5: Start IDC <NUMBER>
 * 6: Layout values <HASHMAP>
 *
 * Returns: None
 */
disableSerialization;
params ["_display", "_controls", "_sideLabel", "_sideTitle", "_sideX", "_startIdc", "_layout"];

private _groupTypes = _layout get "groupTypes";
private _subtypes = _layout get "subtypes";
private _titleY = _layout get "titleY";
private _headerY = _layout get "headerY";
private _rowStartY = _layout get "rowStartY";
private _rowH = _layout get "rowH";
private _sideW = _layout get "sideW";
private _labelW = _layout get "labelW";
private _cellW = _layout get "cellW";
private _anchorH = _layout get "anchorH";

[_display, _controls, _sideTitle, _sideX, _titleY, _sideW, _anchorH, true] call FLO_fnc_factionDialogCreateObjectiveLabel;
[_display, _controls, "Objective", _sideX, _headerY, _labelW, _anchorH, false] call FLO_fnc_factionDialogCreateObjectiveLabel;

{
    _x params ["_groupType", "_groupLabel"];
    private _ctrlX = _sideX + _labelW + (_forEachIndex * _cellW);
    [_display, _controls, _groupLabel, _ctrlX, _headerY, _cellW, _anchorH, false] call FLO_fnc_factionDialogCreateObjectiveLabel;
} forEach _groupTypes;

{
    _x params ["_subtype", "_subtypeLabel"];
    private _rowIndex = _forEachIndex;
    private _rowY = _rowStartY + (_rowIndex * _rowH);
    [_display, _controls, _subtypeLabel, _sideX, _rowY, _labelW, _anchorH, false] call FLO_fnc_factionDialogCreateObjectiveLabel;

    {
        _x params ["_groupType", "_groupLabel"];
        private _ctrlX = _sideX + _labelW + (_forEachIndex * _cellW);
        private _idc = _startIdc + (_rowIndex * count _groupTypes) + _forEachIndex;
        private _tooltip = format ["Set %1 %2 %3 objective group count", _sideLabel, _subtypeLabel, _groupLabel];
        [_display, _controls, _idc, _ctrlX, _rowY, _cellW, _anchorH, _tooltip] call FLO_fnc_factionDialogCreateObjectiveEdit;
    } forEach _groupTypes;
} forEach _subtypes;
