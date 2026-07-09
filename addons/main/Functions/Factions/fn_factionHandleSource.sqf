/*
 * Function: FLO_fnc_factionHandleSource
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns a faction handle source, preserving "preset" as the legacy
 *   default for handles without a source key.
 *
 * Arguments:
 * 0: Faction handle <HASHMAP>
 *
 * Returns:
 * Source <STRING>
 */
params ["_handle"];

if ("source" in _handle) exitWith { _handle get "source" };
"preset"
