/*
 * Function: FLO_fnc_virtualizationRestoreRouteState
 * Description:
 *   Atomically restores a previously captured route-domain snapshot. Intended
 *   for transaction rollback; generic group patching cannot own these fields.
 */

params [
    ["_groupId", "", [""]],
    ["_snapshot", createHashMap, [createHashMap]]
];

private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;
private _routeFields = call FLO_fnc_virtualizationGetRouteOwnedFields;
private _candidate = [_groupData] call FLO_fnc_virtualizationCloneValue;

{
    if !(_x in _snapshot) then {
        throw format ["Route rollback for %1 is missing field %2", _groupId, _x];
    };
    _candidate set [_x, [_snapshot get _x] call FLO_fnc_virtualizationCloneValue];
} forEach _routeFields;

[_candidate, _groupId] call FLO_fnc_virtualizationValidateGroup;
private _archetype = [_candidate get "groupType"] call FLO_fnc_virtualizationGetArchetype;
if ((_archetype get "movementDomain") == "LAND") then {
    private _routeValidation = [
        _groupId,
        _candidate get "position",
        _candidate get "waypoints",
        _candidate get "currentWaypointIndex",
        _candidate get "autoPatrol",
        _candidate get "patrolConfig"
    ] call FLO_fnc_virtualizationValidateLandRoute;
    if !(_routeValidation select 0) then {
        throw format ["Route rollback for %1 rejected: %2", _groupId, _routeValidation select 1];
    };
};

_candidate set ["nextProcessAt", 0];
if (_candidate get "isActive") then {
    private _physicalRouteAllowed = [_groupId, _candidate] call FLO_fnc_virtualizationApplyRealRoute;
    if (!_physicalRouteAllowed) then {
        private _error = format ["Route rollback for %1 could not publish the physical route", _groupId];
        ["VIRTUALIZATION", 1, _error] call FLO_fnc_log;
        throw _error;
    };
};

{
    _groupData set [_x, _candidate get _x];
} forEach _routeFields;
_groupData set ["nextProcessAt", 0];

call FLO_fnc_virtualizationTouchRegistry;
[
    "FLO_Virtualization_GroupPatched",
    [_groupId, +_routeFields]
] call CBA_fnc_localEvent;
true
