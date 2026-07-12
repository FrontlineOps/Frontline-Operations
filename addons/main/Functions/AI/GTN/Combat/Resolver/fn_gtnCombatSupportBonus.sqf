/*
 * Function: FLO_fnc_gtnCombatSupportBonus
 * Author: Frontline Operations Development Group
 * Description:
 *   Preserves the support summary contract. Artillery and air effects are
 *   applied only by explicit authorized missions.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Support availability map <HASHMAP>
 *
 * Return Value:
 *   Support bonus summary <HASHMAP>
 */

params ["_side", "_supportAvailability"];

createHashMapFromArray [
    ["total", 0],
    ["artillery", 0],
    ["air", 0]
]
