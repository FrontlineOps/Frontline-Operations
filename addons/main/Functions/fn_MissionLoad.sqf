/*
 * Function: FLO_fnc_MissionLoad
 * Author: Frontline Operations Development Group
 * Description:
 *   PreInit function that marks the mission shell as ready for the addon
 *   bootstrap. Save/load selection is handled later by the CBA campaign launch
 *   mode during Phase 0.
 *
 *   IMPORTANT: This function runs at preInit, BEFORE the Phase Manager.
 *   It should NOT initialize any systems - just prepare data.
 *
 *   The actual entity restoration happens in Phase 5 (fn_initPhase5_MissionSystems)
 *   after factions and objectives are properly initialized.
 *
 * Returns: <BOOL> - Success status
 */

if (!isServer) exitWith {false};

["LOAD", 3, "PreInit: mission shell ready for addon bootstrap"] call FLO_fnc_log;

MissionLoadedLitterally = false;
publicVariable "MissionLoadedLitterally";

MissionLoadedLitterally = true;
publicVariable "MissionLoadedLitterally";

true
