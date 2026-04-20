/*
 * Function: FLO_fnc_factionApplyTuningOverrides
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies validated mission setup faction tuning overrides to a side catalog
 *   and mirrors the tuned values back to legacy side globals.
 *
 * Arguments:
 *   0: Side faction catalog <HASHMAP>
 *   1: Tuning overrides <HASHMAP>
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

if ((count keys _tuning) == 0) exitWith { true };

private _fnc_mergePairs = {
    params ["_basePairs", "_overridePairs"];

    private _merged = createHashMap;
    {
        if (_x isEqualType [] && {count _x >= 2}) then {
            _merged set [_x select 0, _x select 1];
        };
    } forEach _basePairs;

    {
        if (_x isEqualType [] && {count _x >= 2}) then {
            _merged set [_x select 0, _x select 1];
        };
    } forEach _overridePairs;

    private _result = [];
    {
        _result pushBack [_x, _y];
    } forEach _merged;

    _result
};

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
        _catalog set [_x, [_catalog get _x, _tuning get _x] call _fnc_mergePairs];
    };
} forEach [
    "objectiveGroupTypeCaps",
    "groupCounts"
];

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

["FACTIONS", 2, format [
    "Applied %1 faction tuning overrides: %2",
    _sideLabel,
    keys _tuning
]] call FLO_fnc_log;

true
