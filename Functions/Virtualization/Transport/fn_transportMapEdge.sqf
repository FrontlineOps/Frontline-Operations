/*
 * Function: FLO_fnc_transportMapEdge
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes cached map edge state for transport/reinforcement spawning.
 *
 * Return Value:
 *   None (initializes globals)
 */

if (!isServer) exitWith {};

// Cache for map edge positions
FLO_Transport_MapEdgePositions = [];
FLO_Transport_MapEdgeCacheTime = 0;

["TRANSPORT", 3, "Map edge spawning utilities initialized"] call FLO_fnc_log;
