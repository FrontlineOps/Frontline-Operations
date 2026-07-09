/*
 * Function: FLO_fnc_factionDialogGetSelection
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the text/data pair for the current combo/list selection.
 *
 * Arguments:
 * 0: Dialog display <DISPLAY>
 * 1: Control IDC <NUMBER>
 *
 * Returns:
 * Selection <ARRAY> [text, data]
 */
disableSerialization;
params ["_display", "_idc"];

private _ctrl = _display displayCtrl _idc;
private _idx = lbCurSel _ctrl;
if (_idx < 0) exitWith { ["", ""] };

[_ctrl lbText _idx, _ctrl lbData _idx]
