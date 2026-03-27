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
 * 1: Active Unit Cap <NUMBER> - Max live non-player AI before further activations are deferred (default 200)
 * 2: Auto Start PFH <BOOL> - Start the update PFH immediately (default true)
 *
 * Return Value:
 * Virtual Groups HashMap <HASHMAP>
 *
 * Example:
 * [2000, 200, true] call FLO_fnc_initVirtualization;
 */

params [
    ["_activationDistance", 2000, [0]],
    ["_activationUnitCap", 200, [0]],
    ["_autoStart", true, [true]]
];

["VIRTUALIZATION", 3, format["Initializing Virtualization System (activation: %1m cap: %2)", _activationDistance, _activationUnitCap]] call FLO_fnc_log;

// ============================================================================
// CREATE MAIN DATA STRUCTURE
// ============================================================================
FLO_virtualGroups = createHashMapFromArray [
    ["_groups", createHashMap],
    ["_activationDistance", _activationDistance],
    ["_activationUnitCap", _activationUnitCap],
    ["_activationResumeCap", ((_activationUnitCap - 20) max 0)],
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

if (_autoStart) then {
    // Start update loop (Unscheduled PFH)
    ["start"] call FLO_fnc_virtualizationUpdatePFH;
};

// Initialize debug manager
["init"] call FLO_fnc_virtualizationDebugManager;

// Initialize Transport System
call FLO_fnc_transportConfig;
call FLO_fnc_transportPool;

// Set ready flag
FLO_VirtualizationReady = true;
publicVariable "FLO_VirtualizationReady";

["VIRTUALIZATION", 3, format [
    "Virtualization System initialized (PFH %1)",
    ["deferred", "started"] select _autoStart
]] call FLO_fnc_log;

FLO_virtualGroups
