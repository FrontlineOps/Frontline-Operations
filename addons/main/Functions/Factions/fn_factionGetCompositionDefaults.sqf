/*
 * Function: FLO_fnc_factionGetCompositionDefaults
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns default numeric force composition values for the selected faction.
 *
 * Arguments:
 *   0: Side label <STRING> - "BLUFOR" or "OPFOR"
 *   1: Faction selection label <STRING>
 *   2: Faction selection data <STRING>
 *
 * Return Value:
 *   HASHMAP with transportReserveGroundCount, transportReserveAirCount,
 *   objectiveGroups, objectiveGroupTypeCaps, and groupCounts.
 */

params [
    ["_sideLabel", "", [""]],
    ["_selection", "", [""]],
    ["_data", "", [""]]
];

private _uncapped = 999;

private _fnc_caps = {
    params [
        ["_limited", true, [true]],
        ["_staticAACap", 3, [0]],
        ["_mobileAACap", 20, [0]]
    ];

    [
        ["infantry", _uncapped],
        ["motorized", _uncapped],
        ["mechanized", _uncapped],
        ["armor", _uncapped],
        ["helicopter", [_uncapped, 10] select (_limited)],
        ["jet", [_uncapped, 10] select (_limited)],
        ["air", 5],
        ["artillery", [_uncapped, 5] select (_limited)],
        ["mobile_aa", [_uncapped, _mobileAACap] select (_limited)],
        ["static_aa", [_uncapped, _staticAACap] select (_limited)]
    ]
};

private _fnc_counts = {
    params [
        ["_maneuverCount", 1, [0]],
        ["_artilleryCount", 3, [0]],
        ["_infantryCount", 10, [0]]
    ];

    [
        ["infantry", _infantryCount],
        ["motorized", _maneuverCount],
        ["mechanized", _maneuverCount],
        ["armor", _maneuverCount],
        ["helicopter", 1],
        ["jet", 1],
        ["air", 1],
        ["artillery", _artilleryCount],
        ["mobile_aa", 1],
        ["static_aa", 1]
    ]
};

private _fnc_objectiveGroups = {
    [
        ["capital", [
            ["infantry", 12],
            ["motorized", 2],
            ["mechanized", 1],
            ["air", 1],
            ["armor", 1],
            ["artillery", 1],
            ["static_aa", 1],
            ["mobile_aa", 1]
        ]],
        ["city", [
            ["infantry", 12],
            ["motorized", 2],
            ["mechanized", 1],
            ["air", 1],
            ["armor", 1],
            ["artillery", 1],
            ["static_aa", 1],
            ["mobile_aa", 1]
        ]],
        ["village", [
            ["infantry", 3]
        ]],
        ["local", [
            ["infantry", 6],
            ["motorized", 2],
            ["mechanized", 1],
            ["mobile_aa", 1]
        ]],
        ["marine", [
            ["infantry", 3],
            ["motorized", 1]
        ]],
        ["cluster", [
            ["infantry", 2]
        ]]
    ]
};

private _fnc_defaults = {
    params ["_groundReserve", "_airReserve", "_objectiveGroups", "_caps", "_counts"];

    createHashMapFromArray [
        ["transportReserveGroundCount", _groundReserve],
        ["transportReserveAirCount", _airReserve],
        ["objectiveGroups", _objectiveGroups],
        ["objectiveGroupTypeCaps", _caps],
        ["groupCounts", _counts]
    ]
};

private _objectiveGroups = call _fnc_objectiveGroups;

switch (toUpper _sideLabel) do {
    case "BLUFOR": {
        private _maneuverCount = 1;
        private _caps = if (_selection isEqualTo "AAF _ Woodland") then {
            [false, 3, 20] call _fnc_caps
        } else {
            [true, 3, 20] call _fnc_caps
        };

        [20, 10, _objectiveGroups, _caps, [_maneuverCount, 3, 10] call _fnc_counts] call _fnc_defaults
    };
    case "OPFOR": {
        private _maneuverCount = [1, 2] select (_selection isEqualTo "CUSTOM_ENEMY_FACTION");
        private _caps = [true, 3, 20] call _fnc_caps;

        [20, 10, _objectiveGroups, _caps, [_maneuverCount, 3, 10] call _fnc_counts] call _fnc_defaults
    };
    default {
        ["FACTIONS", 1, format ["Unknown force composition side '%1' for %2", _sideLabel, _selection]] call FLO_fnc_log;
        [20, 10, _objectiveGroups, [true, 3, 20] call _fnc_caps, [1, 3, 10] call _fnc_counts] call _fnc_defaults
    };
};
