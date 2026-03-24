/*
 * Function: FLO_fnc_initVirtualization
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes the OPFOR virtualization system.
 *   Creates HashMap for tracking virtualized groups.
 *   Uses unscheduled CBA PerFrameHandler for reliable updates.
 *
 * Arguments:
 * 0: Activation Distance <NUMBER> - Distance at which virtual groups activate (default 2000m)
 *
 * Return Value:
 * Virtual Groups HashMap <HASHMAP>
 *
 * Example:
 * [2000] call FLO_fnc_initVirtualization;
 */

params [["_activationDistance", 2000, [0]]];

["VIRTUALIZATION", 3, format["Initializing Virtualization System (activation: %1m)", _activationDistance]] call FLO_fnc_log;

// ============================================================================
// CREATE MAIN DATA STRUCTURE
// ============================================================================
FLO_virtualGroups = createHashMapFromArray [
    ["_groups", createHashMap],
    ["_activationDistance", _activationDistance],
    ["_enabled", true],
    ["_debugMode", false]
];

// ============================================================================
// INITIALIZE SUB-SYSTEMS
// ============================================================================

// Initialize spatial index for fast proximity queries
[500] call FLO_fnc_virtualizationSpatialInit;

// Register CBA event handlers for GTN/AI Commander integration
["init"] call FLO_fnc_virtualizationEvents;

// Start update loop (Unscheduled PFH)
["start"] call FLO_fnc_virtualizationUpdatePFH;

// Initialize debug manager
["init"] call FLO_fnc_virtualizationDebugManager;

// Initialize Transport System
call FLO_fnc_transportConfig;
call FLO_fnc_transportPool;
call FLO_fnc_transportMapEdge;

// Set ready flag
FLO_VirtualizationReady = true;
publicVariable "FLO_VirtualizationReady";

["VIRTUALIZATION", 3, "Virtualization System initialized (PFH mode)"] call FLO_fnc_log;

FLO_virtualGroups
