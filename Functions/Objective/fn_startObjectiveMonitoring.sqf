/*
 * Function: FLO_fnc_startObjectiveMonitoring
 * Author: Frontline Operations Development Group
 * Description:
 *   Wrapper function to start objective dominance monitoring on the server.
 *   This function spawns the monitoring loop.
 *
 * Arguments: None
 *
 * Example:
 *   [] remoteExec ["FLO_fnc_startObjectiveMonitoring", 2];
 */

if (!isServer) exitWith {};

[] spawn FLO_fnc_monitorObjectiveDominance; 