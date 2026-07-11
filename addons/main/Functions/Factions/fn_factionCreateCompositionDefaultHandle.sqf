/*
 * Function: FLO_fnc_factionCreateCompositionDefaultHandle
 * Author: Frontline Operations Development Group
 * Description:
 *   Packages default composition values into the runtime handle shape.
 *
 * Arguments:
 * 0: Ground reserve count <NUMBER>
 * 1: Air reserve count <NUMBER>
 * 2: Objective groups <ARRAY>
 * 3: Caps <ARRAY>
 * 4: Counts <ARRAY>
 *
 * Returns:
 * Composition handle <HASHMAP>
 */
params ["_groundReserve", "_airReserve", "_objectiveGroups", "_caps", "_counts"];

createHashMapFromArray [
    ["transportReserveGroundCount", _groundReserve],
    ["transportReserveAirCount", _airReserve],
    ["objectiveGroups", _objectiveGroups],
    ["objectiveGroupTypeCaps", _caps],
    ["groupCounts", _counts]
]
