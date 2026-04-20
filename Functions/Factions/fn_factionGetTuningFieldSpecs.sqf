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

private _groupTypes = [
    ["infantry", 0],
    ["motorized", 1],
    ["mechanized", 2],
    ["armor", 3],
    ["helicopter", 4],
    ["jet", 5],
    ["air", 6],
    ["artillery", 7],
    ["mobile_aa", 8],
    ["static_aa", 9]
];

private _fnc_buildSpecs = {
    params ["_reserveGroundIdc", "_reserveAirIdc", "_capStartIdc", "_countStartIdc"];

    private _specs = [
        [_reserveGroundIdc, "scalar", "transportReserveGroundCount"],
        [_reserveAirIdc, "scalar", "transportReserveAirCount"]
    ];

    {
        _x params ["_key", "_offset"];
        _specs pushBack [_capStartIdc + _offset, "cap", _key];
    } forEach _groupTypes;

    {
        _x params ["_key", "_offset"];
        _specs pushBack [_countStartIdc + _offset, "count", _key];
    } forEach _groupTypes;

    _specs
};

private _specs = switch (toUpper _sideLabel) do {
    case "BLUFOR": {
        [2050, 2051, 2052, 2062] call _fnc_buildSpecs
    };
    case "OPFOR": {
        [2072, 2073, 2074, 2084] call _fnc_buildSpecs
    };
    default {
        ["FACTIONS", 1, format ["Unknown force composition side '%1'", _sideLabel]] call FLO_fnc_log;
        []
    };
};

_specs + ([_sideLabel] call FLO_fnc_factionGetObjectiveGroupFieldSpecs)
