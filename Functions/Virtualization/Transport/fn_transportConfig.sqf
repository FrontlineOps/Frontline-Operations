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

// Minimum reassignment distance for foot infantry to request pickup
FLO_Transport_ReassignmentPickupMinDistance = 1500;

// Maximum search radius (meters) for finding transports
FLO_Transport_SearchRadius = 5000;

// Minimum long-haul distance (meters) before airlift is considered
FLO_Transport_AirPickupMinDistance = 4000;

// Maximum search radius (meters) for dedicated transport helicopters
FLO_Transport_AirSearchRadius = 12000;

// Default dismount standoff (meters) from the final destination
FLO_Transport_DismountDistance = 400;

// Threat-driven unload radius (meters) around the carrier
FLO_Transport_ThreatDismountRadius = 500;

// Fallback capacity estimates by group type
FLO_Transport_CapacityEstimates = createHashMapFromArray [
    ["motorized", 8],
    ["mechanized", 8],
    ["helicopter", 12],
    ["armor", 0],
    ["truck", 10]
];

["TRANSPORT", 3, "Transport configuration initialized"] call FLO_fnc_log;
