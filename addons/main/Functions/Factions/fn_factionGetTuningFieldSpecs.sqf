/*
 * Function: FLO_fnc_factionGetTuningFieldSpecs
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns mission setup force composition field specs for a side.
 *
 * Arguments:
 *   0: Side label <STRING> - "BLUFOR" or "OPFOR"
 *
 * Return Value:
 *   ARRAY of [idc, category, key]
 */

params [["_sideLabel", "", [""]]];

private _specs = switch (toUpper _sideLabel) do {
    case "BLUFOR": {
        [2050, 2051, 2052, 2062] call FLO_fnc_factionBuildTuningFieldSpecsFromIdcs
    };
    case "OPFOR": {
        [2072, 2073, 2074, 2084] call FLO_fnc_factionBuildTuningFieldSpecsFromIdcs
    };
    default {
        ["FACTIONS", 1, format ["Unknown force composition side '%1'", _sideLabel]] call FLO_fnc_log;
        []
    };
};

_specs + ([_sideLabel] call FLO_fnc_factionGetObjectiveGroupFieldSpecs)
