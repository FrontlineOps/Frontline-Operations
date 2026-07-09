/*
 * Starting OP (Outpost) Initialization
 * Author: Frontline Operations
 *
 * Description:
 * Initializes the starting Outpost near the player.
 * OPs are smaller forward positions compared to FOBs.
 *
 * This script runs on each client after the starting location is selected.
 *
 * Global Variables Set:
 * - FLO_StartingOpBuilding: Reference to the main OP building
 */

// ============================================================================
// OP BUILDING INITIALIZATION
// ============================================================================

private _opBuildings = nearestObjects [position player, [FLO_FactionCopType], 150];
if (_opBuildings isEqualTo []) exitWith {
    ["INIT_OP", 1, "Error: No OP building found within 150m of player"] call FLO_fnc_log;
};

FLO_StartingOpBuilding = _opBuildings select 0;
publicVariable "FLO_StartingOpBuilding";

[FLO_StartingOpBuilding] call FLO_fnc_initializeOP;
["INIT_OP", 3, format["OP initialized at %1", mapGridPosition FLO_StartingOpBuilding]] call FLO_fnc_log;

["INIT_OP", 3, "Starting OP initialization complete"] call FLO_fnc_log;
