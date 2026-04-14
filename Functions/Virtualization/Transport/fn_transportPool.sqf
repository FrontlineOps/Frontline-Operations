/*
 * Function: FLO_fnc_transportPool
 * Author: Frontline Operations Development Group
 * Description:
 *   Singleton pool manager for tracking available and active transports.
 *   Initializes the shared transport pool state.
 *
 * Return Value:
 *   FLO_TransportPool <HASHMAP>
 */

if (!isServer) exitWith {};

if (!isNil "FLO_TransportPool") exitWith { FLO_TransportPool };

["TRANSPORT", 3, "Initializing Transport Pool Manager"] call FLO_fnc_log;

FLO_TransportPool = createHashMapFromArray [
    ["available", createHashMap],
    ["active", createHashMap]
];

["TRANSPORT", 3, "Transport Pool Manager initialized"] call FLO_fnc_log;

FLO_TransportPool
