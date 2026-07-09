/*
 * Function: FLO_fnc_factionGetCustomDefinition
 * Description:
 *   Returns the setup selection name and file path for one custom faction role.
 */
params [["_role", "", [""]]];

switch (toLower _role) do {
    case "friendly": {
        ["CUSTOM_PLAYER_FACTION", "\z\flo\addons\main\Factions\Custom\blu_custom.sqf"]
    };
    case "enemy": {
        ["CUSTOM_ENEMY_FACTION", "\z\flo\addons\main\Factions\Custom\opf_custom.sqf"]
    };
    case "civilian": {
        ["CUSTOM_CIVILIAN_FACTION", "\z\flo\addons\main\Factions\Custom\civ_custom.sqf"]
    };
    default {
        throw format ["Unsupported custom faction role: %1", _role]
    };
}
