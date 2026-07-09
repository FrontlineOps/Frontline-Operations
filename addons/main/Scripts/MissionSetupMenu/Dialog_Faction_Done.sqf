/*
 * Script: Dialog_Faction_Done.sqf
 * Author: Frontline Operations
 *
 * Description:
 * LEGACY WRAPPER - This script is kept for backward compatibility.
 * The functionality has been moved to FLO_fnc_factionDialogStart.
 *
 * This script is called from the old dialog's START button action.
 * New code should use the dialog's onLoad handler which calls
 * FLO_fnc_factionDialogStart directly.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

["UI", 2, "Dialog_Faction_Done.sqf called - this is a legacy script"] call FLO_fnc_log;

// Call the new function that handles mission start
[] call FLO_fnc_factionDialogStart;
