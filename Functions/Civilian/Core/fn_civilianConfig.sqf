/*
 * Function: FLO_fnc_civilianConfig
 * Author: Frontline Operations Development Group
 * Description:
 *   Central configuration for the rewritten civilian simulation and intel
 *   system. This is the source of truth for civilian ambient behavior policy.
 *
 * Return Value:
 * HASHMAP - Civilian configuration
 */

FLO_CivilianConfig = createHashMapFromArray [
    ["REP_FRIENDLY", 12],
    ["REP_NEUTRAL", 8],
    ["REP_WARY", 4],
    ["REP_HOSTILE", 0],

    ["DENSITY", createHashMapFromArray [
        ["NameCityCapital", [8, 12, 4, 6]],
        ["NameCity", [4, 8, 2, 4]],
        ["NameVillage", [1, 3, 0, 2]]
    ]],

    ["BUILDING_MULTIPLIER", createHashMapFromArray [
        ["NameCityCapital", 1.5],
        ["NameCity", 1.0],
        ["NameVillage", 0.5]
    ]],

    ["CIV_LOCATION_TYPES", ["NameCity", "NameCityCapital", "NameVillage"]],
    ["UPDATE_INTERVAL", 45],
    ["INTEL_COOLDOWN_SECONDS", 420],
    ["MAX_LOCAL_INTEL_RADIUS", 750],
    ["FLEE_RADIUS", 150],
    ["FLEE_DISTANCE", 100],
    ["FLEE_DURATION", 180]
];

publicVariable "FLO_CivilianConfig";

FLO_CivilianConfig
