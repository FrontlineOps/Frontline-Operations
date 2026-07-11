/*
 * Function: FLO_fnc_factionDialogNormalizeMultiSelection
 * Author: Frontline Operations Development Group
 * Description:
 *   Keeps faction multi-select controls from mixing custom and auto entries.
 *
 * Arguments:
 *   0: Control <CONTROL>
 *   1: Selected row index <NUMBER>
 *
 * Return Value:
 *   None
 */

disableSerialization;

params [
    ["_ctrl", controlNull, [controlNull]],
    ["_selectedIndex", -1, [0]]
];

if (isNull _ctrl) exitWith {};
if ((ctrlType _ctrl) != 5) exitWith {};
if (_selectedIndex < 0) exitWith {};

private _selectedData = _ctrl lbData _selectedIndex;
private _selectedIsAuto = (_selectedData find "auto|") == 0;
private _selectedRows = lbSelection _ctrl;

if (_selectedIsAuto) then {
    {
        private _rowData = _ctrl lbData _x;
        if ((_rowData find "auto|") isNotEqualTo 0) then {
            _ctrl lbSetSelected [_x, false];
        };
    } forEach _selectedRows;
} else {
    {
        if (_x != _selectedIndex) then {
            _ctrl lbSetSelected [_x, false];
        };
    } forEach _selectedRows;
};
