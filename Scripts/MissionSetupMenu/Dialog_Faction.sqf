/*
 * Script: Dialog_Faction.sqf
 * Author: Frontline Operations
 *
 * Description:
 * Opens the Faction Selection Dialog for mission setup.
 * This is a simple launcher script - all logic is handled by the dialog's
 * onLoad handler (FLO_fnc_factionDialogOnLoad) and button actions.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * execVM "Scripts\MissionSetupMenu\Dialog_Faction.sqf";
 */

disableSerialization;

// Create the faction selection dialog
// The new dialog class FLO_FactionSelectDialog handles everything via onLoad
// factionselect_dialog2 is an alias for backward compatibility
(findDisplay 46) createDisplay "FLO_FactionSelectDialog";

["UI", 3, "Faction selection dialog opened"] call FLO_fnc_log;


