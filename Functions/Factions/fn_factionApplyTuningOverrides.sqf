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

if ((count keys _tuning) == 0) exitWith { true };

private _fnc_mergePairs = {
    params ["_basePairs", "_overridePairs"];

    private _overrideMap = createHashMap;
    private _overrideOrder = [];
    {
        if (_x isEqualType [] && {count _x >= 2}) then {
            private _key = _x select 0;
            _overrideMap set [_key, _x select 1];
            _overrideOrder pushBackUnique _key;
        };
    } forEach _overridePairs;

    private _seen = createHashMap;
    private _result = [];
    {
        if (_x isEqualType [] && {count _x >= 2}) then {
            private _key = _x select 0;
            private _value = if (_key in _overrideMap) then { _overrideMap get _key } else { _x select 1 };
            _result pushBack [_key, _value];
            _seen set [_key, true];
        };
    } forEach _basePairs;

    {
        if !(_x in _seen) then {
            _result pushBack [_x, _overrideMap get _x];
        };
    } forEach _overrideOrder;

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
    "Applied %1 force composition values: %2",
    _sideLabel,
    keys _tuning
]] call FLO_fnc_log;

true
