/*
 * Function: FLO_fnc_virtualizationGetRemainingWaypoints
 * Description:
 *   Returns the remaining activation route and revalidates LAND geometry from
 *   the actual activation position without skipping required detour pivots.
 *
 * Return Value:
 *   [Allowed, Remaining waypoints, Rejection reason] <ARRAY>
 */

params [
    "_groupId",
    "_position",
    "_allWaypoints",
    "_currentWpIdx",
    ["_generatedPatrol", false, [false]]
];

private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;
private _archetype = [_groupData get "groupType"] call FLO_fnc_virtualizationGetArchetype;
private _movementDomain = _archetype get "movementDomain";
if (_movementDomain != "LAND" || {_allWaypoints isEqualTo []}) exitWith {
    private _remainingIndex = _currentWpIdx;
    if (!_generatedPatrol && {_remainingIndex == 0} && {count _allWaypoints > 1}) then {
        private _nearestDist = 999999;
        private _nearestIdx = -1;
        {
            private _dist = ((_x select 0) distance2D _position);
            if (_dist < _nearestDist) then {
                _nearestDist = _dist;
                _nearestIdx = _forEachIndex;
            };
        } forEach _allWaypoints;

        if (_nearestIdx > 0) then {
            private _distToFirst = ((_allWaypoints select 0) select 0) distance2D _position;
            if (_nearestDist < 500 && {_distToFirst > (_nearestDist + 200)}) then {
                _remainingIndex = _nearestIdx;
            };
        };
    };

    private _remainingWaypoints = +_allWaypoints;
    if (_remainingIndex > 0 && {_remainingIndex < count _allWaypoints}) then {
        _remainingWaypoints = _allWaypoints select [_remainingIndex, count _allWaypoints - _remainingIndex];
    };
    [true, _remainingWaypoints, ""]
};

private _routeResult = [
    _position,
    _allWaypoints,
    _currentWpIdx,
    _generatedPatrol || {_groupData get "autoPatrol"},
    "ACTIVATION_REBASE"
] call FLO_fnc_virtualizationResolveLandRouteContinuation;
_routeResult params ["_resolved", "_resolvedWaypoints", "_reason"];
if (!_resolved) exitWith { [false, [], _reason] };

[true, _resolvedWaypoints, ""]
