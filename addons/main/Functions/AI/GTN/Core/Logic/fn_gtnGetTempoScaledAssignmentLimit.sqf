/*
 * Function: FLO_fnc_gtnGetTempoScaledAssignmentLimit
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Resolves a commander's fixed per-cycle assignment cap. Commander tempo
 *   controls decision cadence; it must not multiply the number of orders
 *   emitted by a slower cycle.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 * 1: Config key <STRING>
 *
 * Return Value:
 * Per-cycle assignment limit <NUMBER>
 */

params ["_cmdr", "_configKey"];

((_cmdr get "_config") get _configKey) max 0
