/*
 * Function: FLO_fnc_MissionLoad
 * Author: Frontline Operations Development Group
 * Description:
 *   PreInit function that prepares save data for the Phase Manager.
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

["LOAD", 3, "PreInit: Preparing save data for Phase Manager..."] call FLO_fnc_log;

// Initialize the flag that indicates load is complete
MissionLoadedLitterally = false;
publicVariable "MissionLoadedLitterally";

// Handle fresh start parameter
private _freshStart = "FreshStart" call BIS_fnc_getParamValue;
if (_freshStart isEqualTo 1) exitWith {
    ["LOAD", 3, "Fresh start requested - clearing save data"] call FLO_fnc_log;
    missionProfileNamespace setVariable ["FLO_MissionData", nil];
    saveMissionProfileNamespace;
    MissionLoadedLitterally = true;
    publicVariable "MissionLoadedLitterally";
    true
};

// Load save data into global variable for Phase Manager to use
private _data = missionProfileNamespace getVariable ["FLO_MissionData", nil];

if (isNil "_data" || (!(_data isEqualType createHashMap))) exitWith {
    ["LOAD", 3, "No valid save data found - fresh start"] call FLO_fnc_log;
    MissionLoadedLitterally = true;
    publicVariable "MissionLoadedLitterally";
    true
};

// Store save data globally for Phase Manager
FLO_SavedGameData = _data;
publicVariable "FLO_SavedGameData";

// Set flag indicating this is a loaded save (for Phase 5 entity restoration)
FLO_IsLoadedSave = true;
publicVariable "FLO_IsLoadedSave";

["LOAD", 3, format ["Save data loaded with %1 keys - Phase Manager will handle restoration", count keys _data]] call FLO_fnc_log;

// Mark preInit load as complete - actual restoration happens in phases
MissionLoadedLitterally = true;
publicVariable "MissionLoadedLitterally";

true
