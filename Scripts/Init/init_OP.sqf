/*
 * Starting OP (Outpost) Initialization
 * Author: Frontline Operations
 *
 * Description:
 * Initializes the starting Outpost near the player.
 * OPs are smaller forward positions compared to FOBs.
 *
 * If ACE3 is installed, enables the ACE Arsenal on the OP.
 *
 * This script runs on each client after the starting location is selected.
 *
 * Global Variables Set:
 * - FOBB: Reference to the main OP building (shared variable name with FOB)
 */

// ============================================================================
// OP BUILDING INITIALIZATION
// ============================================================================

FOBB = nearestObjects [position player, [F_OP_01], 150] select 0;
publicVariable "FOBB";

if (!isNil "FOBB") then {
    [FOBB] call FLO_fnc_initializeOP;
    ["INIT_OP", 3, format["OP initialized at %1", mapGridPosition FOBB]] call FLO_fnc_log;
} else {
    ["INIT_OP", 1, "Error: No OP building found within 150m of player"] call FLO_fnc_log;
};

// ============================================================================
// ACE3 ARSENAL INTEGRATION
// ============================================================================

// Enable full ACE Arsenal on the OP only when restricted arsenal is disabled
if (
    isClass (configFile >> "CfgPatches" >> "ace_main") &&
    {("RestrictedArsenal" call BIS_fnc_getParamValue) != 0}
) then {
    if (!isNil "FOBB") then {
        [FOBB, true] remoteExec ["ace_arsenal_fnc_initBox", 0];
        ["INIT_OP", 3, "ACE Arsenal enabled on OP"] call FLO_fnc_log;
    };
};

["INIT_OP", 3, "Starting OP initialization complete"] call FLO_fnc_log;
