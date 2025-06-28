/*
 * Function: FLO_fnc_startObjectiveGraph
 * Author: Frontline Operations Development Group
 * Description:
 *   Wrapper function to start objective graph building on the server.
 *   This function spawns the graph building process.
 *
 * Arguments:
 *   0: Debug mode <BOOLEAN> (optional, default: false)
 *
 * Example:
 *   [false] remoteExec ["FLO_fnc_startObjectiveGraph", 2];
 */

params [ ["_debug", false, [true]] ];

if (!isServer) exitWith {};

[_debug] spawn FLO_fnc_buildObjectiveGraph; 