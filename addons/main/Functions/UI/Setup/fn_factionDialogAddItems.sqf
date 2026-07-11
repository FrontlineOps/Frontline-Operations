/*
 * Function: FLO_fnc_factionDialogAddItems
 * Author: Frontline Operations Development Group
 * Description:
 *   Adds plain text options to a setup dialog control.
 *
 * Arguments:
 * 0: Control <CONTROL>
 * 1: Items <ARRAY>
 * 2: Default index <NUMBER>
 *
 * Returns: None
 */
disableSerialization;
params ["_ctrl", "_items", "_defaultIndex"];

{
    _ctrl lbAdd _x;
} forEach _items;

[_ctrl, _defaultIndex] call FLO_fnc_factionDialogSelectDefault;
