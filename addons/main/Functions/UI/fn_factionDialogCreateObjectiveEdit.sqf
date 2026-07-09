/*
 * Function: FLO_fnc_factionDialogCreateObjectiveEdit
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates a hidden objective composition edit control.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Control registry <ARRAY>
 * 2: IDC <NUMBER>
 * 3: X <NUMBER>
 * 4: Y <NUMBER>
 * 5: W <NUMBER>
 * 6: H <NUMBER>
 * 7: Tooltip <STRING>
 *
 * Returns:
 * Control <CONTROL>
 */
disableSerialization;
params ["_display", "_controls", "_idc", "_ctrlX", "_ctrlY", "_ctrlW", "_ctrlH", "_tooltip"];

private _ctrl = _display ctrlCreate ["FLO_FactionTuneEdit", _idc];
_ctrl ctrlSetTooltip _tooltip;
_ctrl ctrlSetPosition [_ctrlX, _ctrlY, _ctrlW, _ctrlH];
_ctrl ctrlCommit 0;
_ctrl ctrlShow false;
_controls pushBack _ctrl;

_ctrl
