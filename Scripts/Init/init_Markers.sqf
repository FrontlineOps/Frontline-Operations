/*
 * Marker and Objective System Initialization
 * Author: Frontline Operations
 *
 * Description:
 * Creates the respawn marker at the player's starting position and
 * initializes the objective system on the server.
 *
 * This script runs on each client after the starting location is selected.
 *
 * Global Variables Set:
 * - MarLOCC: Marker initialization complete flag
 */

// ============================================================================
// RESPAWN MARKER CREATION
// ============================================================================

private _playerPos = position player;
private _respawnMarkerName = format ["respawn_west_%1", str _playerPos];

// Create respawn marker at player's starting location
private _respawnMarker = createMarker [_respawnMarkerName, _playerPos];
_respawnMarker setMarkerType "b_unknown";
_respawnMarker setMarkerSize [0.6, 0.6];
_respawnMarker setMarkerText "Respawn";
_respawnMarker setMarkerAlpha 1;

["INIT_MARKERS", 3, format["Created respawn marker at %1", mapGridPosition player]] call FLO_fnc_log;

// ============================================================================
// OBJECTIVE SYSTEM INITIALIZATION (SERVER)
// ============================================================================

// Index all objectives on the map
[] remoteExec ["FLO_fnc_indexObjectives", 2];

// Build road network connections between objectives
[false] remoteExec ["FLO_fnc_startObjectiveGraph", 2];

// Start monitoring objective dominance/control
[] remoteExec ["FLO_fnc_monitorObjectiveDominance", 2];

// ============================================================================
// FINALIZATION
// ============================================================================

MarLOCC = 1;
publicVariable "MarLOCC";

["INIT_MARKERS", 3, "Marker initialization complete"] call FLO_fnc_log;