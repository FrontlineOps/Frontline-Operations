/*
 * Function: FLO_fnc_operationsRestoreMapFocus
 * Description:
 *   Returns focus and visibility to the native map after CtrlWebBrowser input.
 */

params ["_map"];

if (isNull _map) exitWith { false };

_map ctrlShow true;
_map ctrlSetFade 0;
_map ctrlCommit 0;
ctrlSetFocus _map;
true
