/*
 * Function: FLO_fnc_factionDialogSelectDefault
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects the default row for setup dialog list/combo controls.
 *
 * Arguments:
 * 0: Control <CONTROL>
 * 1: Default index <NUMBER>
 *
 * Returns: None
 */
disableSerialization;
params ["_ctrl", "_defaultIndex"];

_ctrl lbSetCurSel _defaultIndex;
if ((ctrlType _ctrl) == 5) then {
    _ctrl lbSetSelected [_defaultIndex, true];
};
