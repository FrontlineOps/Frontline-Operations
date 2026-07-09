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
private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", side player];
private _respawnKey = ["west", "east"] select (_activeSide isEqualTo east);
private _respawnMarkerName = format ["respawn_%1_%2", _respawnKey, str _playerPos];

// Create respawn marker at player's starting location
private _respawnMarker = createMarker [_respawnMarkerName, _playerPos];
_respawnMarker setMarkerTypeLocal "b_unknown";
_respawnMarker setMarkerSizeLocal [0.6, 0.6];
_respawnMarker setMarkerTextLocal "Respawn";
_respawnMarker setMarkerAlpha 1;

["INIT_MARKERS", 3, format["Created respawn marker at %1", mapGridPosition player]] call FLO_fnc_log;

// ============================================================================
// FINALIZATION
// ============================================================================

MarLOCC = 1;
publicVariable "MarLOCC";

["INIT_MARKERS", 3, "Marker initialization complete"] call FLO_fnc_log;
