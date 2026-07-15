/*
 * Function: FLO_fnc_virtualizationCreateArchetypeCatalog
 * Description:
 *   Defines stable behavior traits for every supported virtual-group type.
 */

private _catalog = createHashMap;
{
    _x params ["_groupType", "_traits"];
    _catalog set [_groupType, _traits call FLO_fnc_virtualizationCreateArchetype];
} forEach [
    ["infantry",          ["INFANTRY",         true,  false, "PERSONNEL",        1, 6.5, 1,    true,  "FACTION",    false, "LAND"]],
    ["civilian",          ["CIVILIAN",         false, false, "PERSONNEL",        1, 6.5, 1,    false, "RANDOM_CIV", false, "LAND"]],
    ["civ_pedestrian",    ["CIVILIAN",         false, false, "PERSONNEL",        1, 6.5, 1,    false, "RANDOM_CIV", false, "LAND"]],
    ["civ_building",      ["CIVILIAN",         false, false, "PERSONNEL",        1, 6.5, 1,    false, "RANDOM_CIV", false, "LAND"]],
    ["civilianVehicle",   ["CIVILIAN_VEHICLE", true,  true,  "CIVILIAN_VEHICLE", 1, 14,  1,    false, "FIXED_ONE",  false, "LAND"]],
    ["civ_car",           ["CIVILIAN_VEHICLE", true,  true,  "CIVILIAN_VEHICLE", 1, 14,  1,    false, "FIXED_ONE",  false, "LAND"]],
    ["motorized",         ["GROUND",           false, true,  "ASSET",            3, 18,  0.75, true,  "FACTION",    true,  "LAND"]],
    ["mechanized",        ["GROUND",           false, true,  "ASSET",            3, 15,  0.7,  true,  "FACTION",    true,  "LAND"]],
    ["armor",             ["GROUND",           false, true,  "ASSET",            3, 12,  0.65, true,  "FACTION",    true,  "LAND"]],
    ["mobile_aa",         ["GROUND",           false, true,  "ASSET",            3, 12,  0.65, false, "FACTION",    true,  "LAND"]],
    ["artillery",         ["ARTILLERY",        true,  true,  "ASSET",            3, 12,  0.65, false, "FACTION",    false, "LAND"]],
    ["static_aa",         ["STATIC_AA",        true,  true,  "STATIC_AA",        1, 12,  0.65, false, "FACTION",    false, "LAND"]],
    ["helicopter",        ["AIR",              true,  true,  "ASSET",            2, 65,  0.9,  false, "FACTION",    false, "AIR"]],
    ["air",               ["AIR",              true,  true,  "ASSET",            2, 65,  0.9,  false, "FACTION",    false, "AIR"]],
    ["jet",               ["AIR",              true,  true,  "ASSET",            2, 180, 1,    false, "FACTION",    false, "AIR"]],
    ["boat",              ["COMPOSITION_ONLY", true,  false, "ASSET",            1, 6.5, 1,    false, "FACTION",    false, "WATER"]],
    ["naval",             ["COMPOSITION_ONLY", true,  false, "ASSET",            1, 6.5, 1,    false, "FACTION",    false, "WATER"]],
    ["submarine",         ["COMPOSITION_ONLY", true,  false, "ASSET",            1, 6.5, 1,    false, "FACTION",    false, "WATER"]]
];

_catalog
