/*
 * Function: FLO_fnc_factionDialogGetSelections
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns all selected text/data pairs for a faction list, falling back to
 *   the current selection for combo controls.
 *
 * Arguments:
 * 0: Dialog display <DISPLAY>
 * 1: Control IDC <NUMBER>
 *
 * Returns:
 * Selections <ARRAY>
 */
disableSerialization;
params ["_display", "_idc"];

private _ctrl = _display displayCtrl _idc;
private _indexes = if ((ctrlType _ctrl) == 5) then {
    lbSelection _ctrl
} else {
    []
};

if (_indexes isEqualTo [] && {lbCurSel _ctrl >= 0}) then {
    _indexes = [lbCurSel _ctrl];
};

_indexes apply { [_ctrl lbText _x, _ctrl lbData _x] }
