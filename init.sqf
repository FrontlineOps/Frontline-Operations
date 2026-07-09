/*
 * FLO Mission Initialization
 * Author: Frontline Operations
 *
 * Description:
 * Main init.sqf executed for all machines (server, clients, headless clients).
 * This runs after description.ext is parsed but before other init scripts.
 *
 * Execution order:
 * 1. preInit functions (CfgFunctions)
 * 2. init.sqf (this file)
 * 3. initServer.sqf (server only)
 * 4. initPlayerLocal.sqf (clients only)
 * 5. Object init event handlers
 *
 * See also:
 * - initServer.sqf: Server-specific initialization
 * - initPlayerLocal.sqf: Client-specific initialization
 */

// ============================================================================
// NOTIFICATION SYSTEM INITIALIZATION
// ============================================================================

// Initialize the notification HUD layer for all machines with interface
if (hasInterface) then {
    ("NotificationHudLayer" call BIS_fnc_rscLayer) cutRsc ["RscNotifications", "PLAIN"];
};
