/*
 * Function: FLO_fnc_factionApplyTuningOverrides
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies validated mission setup faction composition values to a side catalog
 *   and mirrors the tuned values back to legacy side globals.
 *
 * Arguments:
 *   0: Side faction catalog <HASHMAP>
 *   1: Tuning values <HASHMAP>
 *   2: Side label <STRING>
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_catalog", createHashMap, [createHashMap]],
    ["_tuning", createHashMap, [createHashMap]],
    ["_sideLabel", "", [""]]
];

if ((keys _tuning) isNotEqualTo []) then {
    {
        if (_x in _tuning) then {
            _catalog set [_x, _tuning get _x];
        };
    } forEach [
        "transportReserveGroundCount",
        "transportReserveAirCount",
        "objectiveGroups"
    ];

    {
        if (_x in _tuning) then {
            _catalog set [_x, [_catalog get _x, _tuning get _x] call FLO_fnc_factionMergePairs];
        };
    } forEach [
        "objectiveGroupTypeCaps",
        "groupCounts"
    ];

    ["FACTIONS", 3, format [
        "Applied %1 force composition values: %2",
        _sideLabel,
        keys _tuning
    ]] call FLO_fnc_log;
};

[_catalog, _sideLabel] call FLO_fnc_factionSanitizeCompositionForCatalog;

switch (_sideLabel) do {
    case "OPFOR": {
        East_Transport_Reserve_Ground_Count = _catalog get "transportReserveGroundCount";
        East_Transport_Reserve_Air_Count = _catalog get "transportReserveAirCount";
        OPFOR_Objective_Groups = _catalog get "objectiveGroups";
        East_Objective_Group_Type_Caps = _catalog get "objectiveGroupTypeCaps";
        OPFOR_Group_Counts = _catalog get "groupCounts";
    };
    case "BLUFOR": {
        West_Transport_Reserve_Ground_Count = _catalog get "transportReserveGroundCount";
        West_Transport_Reserve_Air_Count = _catalog get "transportReserveAirCount";
        BLUFOR_Objective_Groups = _catalog get "objectiveGroups";
        West_Objective_Group_Type_Caps = _catalog get "objectiveGroupTypeCaps";
        BLUFOR_Group_Counts = _catalog get "groupCounts";
    };
};

true
