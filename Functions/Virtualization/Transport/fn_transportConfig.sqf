/*
 * Function: FLO_fnc_transportConfig
 * Author: Frontline Operations Development Group
 * Description:
 *   Configuration constants and utility functions for the transport system.
 *   Initializes global transport settings and provides capacity/speed lookups.
 *
 * Return Value:
 *   None (initializes globals)
 */

if (!isServer) exitWith {};

// ============================================================================
// CONFIGURATION CONSTANTS
// ============================================================================

// Minimum distance (meters) to warrant transport request
FLO_Transport_MinDistance = 500;

// Maximum search radius (meters) for finding transports
FLO_Transport_SearchRadius = 5000;

// Transport speeds by group type (m/s)
FLO_Transport_Speeds = createHashMapFromArray [
    ["motorized", 15],      // ~54 km/h
    ["mechanized", 12],     // ~43 km/h
    ["helicopter", 50],     // ~180 km/h
    ["armor", 10],          // ~36 km/h
    ["truck", 14]           // ~50 km/h
];

// Fallback capacity estimates by group type
FLO_Transport_CapacityEstimates = createHashMapFromArray [
    ["motorized", 8],
    ["mechanized", 8],
    ["helicopter", 12],
    ["armor", 0],
    ["truck", 10]
];

["TRANSPORT", 3, "Transport configuration initialized"] call FLO_fnc_log;
