/*
 * Function: FLO_fnc_factionGetObjectiveGroupFieldSpecs
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns mission setup objective group field specs for a side.
 *
 * Arguments:
 *   0: Side label <STRING> - "BLUFOR" or "OPFOR"
 *
 * Return Value:
 *   ARRAY of [idc, "objective", subtype, groupType]
 */

params [["_sideLabel", "", [""]]];

switch (toUpper _sideLabel) do {
    case "BLUFOR": {
        [2200] call FLO_fnc_factionBuildObjectiveGroupFieldSpecs
    };
    case "OPFOR": {
        [2248] call FLO_fnc_factionBuildObjectiveGroupFieldSpecs
    };
    default {
        ["FACTIONS", 1, format ["Unknown objective group field side '%1'", _sideLabel]] call FLO_fnc_log;
        []
    };
};
