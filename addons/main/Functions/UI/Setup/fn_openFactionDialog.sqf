/*
 * Function: FLO_fnc_openFactionDialog
 * Author: Frontline Operations Development Group
 * Description:
 *   Opens the fresh-campaign setup dialog when the local client is allowed to
 *   configure the mission.
 *
 * Arguments: None
 * Returns: BOOL - true when the dialog opened
 */

if (!hasInterface) exitWith { false };
if !([] call FLO_fnc_shouldOpenFactionDialog) exitWith { false };

disableSerialization;

if (!isNull (uiNamespace getVariable ["FLO_FactionDialog", displayNull])) exitWith { true };

["INIT_CLIENT", 3, "Launching faction selection dialog for setup admin"] call FLO_fnc_log;
private _opened = createDialog "factionselect_dialog2";
if (!_opened) then {
    ["INIT_CLIENT", 1, "Failed to create faction selection dialog"] call FLO_fnc_log;
};

_opened
