/*
 * Function: FLO_fnc_civilianApplyInitialRoutine
 * Description:
 *   Applies the first routine for a newly seeded civilian as one transaction.
 *   A route rejection removes the new seed from the registry.
 *
 * Return Value:
 *   BOOL - True when the seeded civilian owns a valid initial routine
 */

params [
    ["_groupId", "", [""]],
    ["_ambientContext", createHashMap, [createHashMap]],
    ["_poiCache", createHashMap, [createHashMap]]
];

private _groupData = [_groupId] call FLO_fnc_virtualizationGetGroup;
private _plan = [_groupData, _ambientContext, _poiCache, diag_tickTime] call FLO_fnc_civilianPlanRoutine;
if ((keys _plan) isEqualTo []) then {
    ["CIVILIAN", 1, format ["New civilian %1 produced no initial routine plan", _groupId]] call FLO_fnc_log;
    throw format ["FLO_fnc_civilianApplyInitialRoutine: new civilian %1 produced no plan", _groupId];
};

if ([_groupId, _plan] call FLO_fnc_civilianApplyRoutinePlan) exitWith { true };

if !([_groupId] call FLO_fnc_virtualizationRemoveGroup) then {
    ["CIVILIAN", 1, format ["Failed to roll back civilian %1 after initial route rejection", _groupId]] call FLO_fnc_log;
    throw format ["FLO_fnc_civilianApplyInitialRoutine: failed to remove rejected seed %1", _groupId];
};

false
