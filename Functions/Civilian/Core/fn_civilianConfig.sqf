/*
 * Function: FLO_fnc_civilianConfig
 * Author: Frontline Operations Development Group
 * Description:
 *   Configuration for the civilian system. All tunable parameters in one place.
 *
 * Returns: HashMap - Configuration object
 */

FLO_CivilianConfig = createHashMapFromArray [
    // ========================================================================
    // BEHAVIOR THRESHOLDS (Reputation 0-16)
    // ========================================================================
    ["REP_FRIENDLY", 12],       // >= this: proactive help, high intel
    ["REP_NEUTRAL", 8],         // >= this: normal behavior
    ["REP_WARY", 4],            // >= this: reduced intel, some flee
    ["REP_HOSTILE", 0],         // below WARY: flee, may report to OPFOR

    // ========================================================================
    // INTEL CHANCES BY DISPOSITION
    // ========================================================================
    ["INTEL_CHANCE_FRIENDLY", 0.75],
    ["INTEL_CHANCE_NEUTRAL", 0.45],
    ["INTEL_CHANCE_WARY", 0.20],
    ["INTEL_CHANCE_HOSTILE", 0.0],

    // ========================================================================
    // DENSITY CONFIG (Civilians per location type)
    // [minPedestrians, maxPedestrians, minCars, maxCars]
    // ========================================================================
    ["DENSITY", createHashMapFromArray [
        ["NameCityCapital", [8, 12, 4, 6]],
        ["NameCity", [4, 8, 2, 4]],
        ["NameVillage", [1, 3, 0, 2]]
    ]],

    // Building occupant multipliers by location type
    ["BUILDING_MULTIPLIER", createHashMapFromArray [
        ["NameCityCapital", 1.5],
        ["NameCity", 1.0],
        ["NameVillage", 0.5]
    ]],

    // ========================================================================
    // UPDATE INTERVALS
    // ========================================================================
    ["UPDATE_INTERVAL", 60],        // Seconds between disposition updates
    ["INTEL_INTERVAL", 300],        // Seconds between passive intel gen

    // ========================================================================
    // FLEE BEHAVIOR
    // ========================================================================
    ["FLEE_RADIUS", 150],           // Civilians flee within this of combat
    ["FLEE_DURATION", 180],         // Seconds before fleeing civs return
    ["FLEE_DISTANCE", 100],         // How far civilians flee

    // ========================================================================
    // CIVILIAN UNIT TYPES (can override from faction config)
    // ========================================================================
    ["CIV_LOCATION_TYPES", ["NameCity", "NameCityCapital", "NameVillage"]]
];

publicVariable "FLO_CivilianConfig";

FLO_CivilianConfig
