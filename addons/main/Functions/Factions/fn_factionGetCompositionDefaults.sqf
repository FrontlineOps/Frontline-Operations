/*
 * Function: FLO_fnc_factionGetCompositionDefaults
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns default numeric force composition values for the selected faction.
 *
 * Arguments:
 *   0: Side label <STRING> - "BLUFOR" or "OPFOR"
 *   1: Faction selection label <STRING>
 * Return Value:
 *   HASHMAP with transportReserveGroundCount, transportReserveAirCount,
 *   objectiveGroups, objectiveGroupTypeCaps, and groupCounts.
 */

params [
    ["_sideLabel", "", [""]],
    ["_selection", "", [""]]
];

private _objectiveGroups = [] call FLO_fnc_factionCompositionDefaultObjectiveGroups;

switch (toUpper _sideLabel) do {
    case "BLUFOR": {
        private _maneuverCount = 1;
        private _caps = [true, 3, 20] call FLO_fnc_factionCompositionDefaultCaps;

        [20, 10, _objectiveGroups, _caps, [_maneuverCount, 3, 10] call FLO_fnc_factionCompositionDefaultCounts] call FLO_fnc_factionCreateCompositionDefaultHandle
    };
    case "OPFOR": {
        private _maneuverCount = [1, 2] select (_selection isEqualTo "CUSTOM_ENEMY_FACTION");
        private _caps = [true, 3, 20] call FLO_fnc_factionCompositionDefaultCaps;

        [20, 10, _objectiveGroups, _caps, [_maneuverCount, 3, 10] call FLO_fnc_factionCompositionDefaultCounts] call FLO_fnc_factionCreateCompositionDefaultHandle
    };
    default {
        ["FACTIONS", 1, format ["Unknown force composition side '%1' for %2", _sideLabel, _selection]] call FLO_fnc_log;
        [20, 10, _objectiveGroups, [true, 3, 20] call FLO_fnc_factionCompositionDefaultCaps, [1, 3, 10] call FLO_fnc_factionCompositionDefaultCounts] call FLO_fnc_factionCreateCompositionDefaultHandle
    };
};
