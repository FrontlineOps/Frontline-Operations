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
 *   objectiveGroupTypeCaps, and groupCounts.
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
        ["helicopter", if (_limited) then { 10 } else { _uncapped }],
        ["jet", if (_limited) then { 10 } else { _uncapped }],
        ["air", 5],
        ["artillery", if (_limited) then { 5 } else { _uncapped }],
        ["mobile_aa", if (_limited) then { _mobileAACap } else { _uncapped }],
        ["static_aa", if (_limited) then { _staticAACap } else { _uncapped }]
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

private _fnc_defaults = {
    params ["_groundReserve", "_airReserve", "_caps", "_counts"];

    createHashMapFromArray [
        ["transportReserveGroundCount", _groundReserve],
        ["transportReserveAirCount", _airReserve],
        ["objectiveGroupTypeCaps", _caps],
        ["groupCounts", _counts]
    ]
};

if ((_data find "auto|") == 0) exitWith {
    [
        10,
        4,
        [true, 4, 12] call _fnc_caps,
        [1, 1, 8] call _fnc_counts
    ] call _fnc_defaults
};

switch (toUpper _sideLabel) do {
    case "BLUFOR": {
        private _maneuverCount = 1;
        private _caps = if (_selection isEqualTo "AAF _ Woodland") then {
            [false, 3, 20] call _fnc_caps
        } else {
            [true, 3, 20] call _fnc_caps
        };

        [20, 10, _caps, [_maneuverCount, 3, 10] call _fnc_counts] call _fnc_defaults
    };
    case "OPFOR": {
        private _maneuverCount = if (_selection isEqualTo "CUSTOM_ENEMY_FACTION") then { 2 } else { 1 };
        private _caps = if (_selection isEqualTo "CSAT _ Desert") then {
            [false, 3, 20] call _fnc_caps
        } else {
            [true, 3, 20] call _fnc_caps
        };

        [20, 10, _caps, [_maneuverCount, 3, 10] call _fnc_counts] call _fnc_defaults
    };
    default {
        ["FACTIONS", 1, format ["Unknown force composition side '%1' for %2", _sideLabel, _selection]] call FLO_fnc_log;
        [20, 10, [true, 3, 20] call _fnc_caps, [1, 3, 10] call _fnc_counts] call _fnc_defaults
    };
};
