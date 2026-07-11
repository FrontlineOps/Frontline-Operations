/*
 * Function: FLO_fnc_factionDialogAddFactionItems
 * Author: Frontline Operations Development Group
 * Description:
 *   Adds custom and auto-generated faction entries to a setup dialog control.
 *
 * Arguments:
 * 0: Control <CONTROL>
 * 1: Custom labels <ARRAY>
 * 2: Auto faction entries <ARRAY>
 * 3: Default index <NUMBER>
 *
 * Returns: None
 */
disableSerialization;
params ["_ctrl", "_customEntries", "_autoEntries", "_defaultIndex"];

{
    private _idx = _ctrl lbAdd _x;
    _ctrl lbSetData [_idx, format ["custom|%1", _x]];
} forEach _customEntries;

{
    private _idx = _ctrl lbAdd (_x get "label");
    _ctrl lbSetData [_idx, format ["auto|%1", _x get "class"]];
} forEach _autoEntries;

[_ctrl, _defaultIndex] call FLO_fnc_factionDialogSelectDefault;
