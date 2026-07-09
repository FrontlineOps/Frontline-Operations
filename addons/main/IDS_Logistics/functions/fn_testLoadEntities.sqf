/**
 * @name IDS_Logistics_fnc_testLoadEntities
 * @category Logistics_Debug
 *
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 *
 * @description
 * Test function to load saved entities from missionProfileNamespace.
 * Displays debug messages and can be executed from the debug console.
 *
 * @param {None}
 *
 * @return {Nothing}
 *
 * @example
 * [] call IDS_Logistics_fnc_testLoadEntities
 */

// Display start message
hint "Starting entity load test...";
systemChat "IDS_Logistics: Starting entity load test...";

private _savedData = missionProfileNamespace getVariable ["IDS_Logistics_SavedEntities", []];
systemChat format ["IDS_Logistics: Found %1 entities in saved data", count _savedData];

// Execute load function on the server
[] remoteExec ["IDS_Logistics_fnc_loadEntities", 2];

// Wait a short time to allow server processing
[{
    // Display completion message with count of loaded entities
    systemChat format ["IDS_Logistics: Loaded %1 entities", count IDS_Logistics_PlacedEntities];
    hint format ["Entity load test complete.\n\nLoaded: %1 entities", count IDS_Logistics_PlacedEntities];
}, [], 2] call CBA_fnc_waitAndExecute;
