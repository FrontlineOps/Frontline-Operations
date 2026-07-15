/*
 * Function: FLO_fnc_virtualizationResolveLandRouteContinuation
 * Description:
 *   Rotates an authoritative LAND loop to its current target and resolves the
 *   complete continuation from a new physical/activation position.
 *
 * Return Value:
 *   FLO_fnc_virtualizationResolveLandWaypoints result
 */

params [
    ["_startPos", [0, 0, 0], [[]], [2, 3]],
    ["_allWaypoints", [], [[]]],
    ["_currentWaypointIndex", 0, [0]],
    ["_loopRoute", false, [true]],
    ["_sourceTag", "LAND_CONTINUATION", [""]]
];

if (_allWaypoints isEqualTo []) exitWith {
    [true, [], "", createHashMapFromArray [["segments", 0], ["emitted", 0]], []]
};

private _cycleIndex = _allWaypoints findIf { toUpper (_x select 1) == "CYCLE" };
private _isLoop = _loopRoute || {_cycleIndex >= 0};
private _remaining = [];

if (_isLoop) then {
    private _movementWaypoints = +_allWaypoints;
    private _cycleWaypoint = [];
    if (_cycleIndex >= 0) then {
        _cycleWaypoint = +(_movementWaypoints deleteAt _cycleIndex);
    };
    if (_cycleIndex < 0
        && {count _movementWaypoints > 1}
        && {((_movementWaypoints select 0) select 0) distance2D ((_movementWaypoints select -1) select 0) <= 1}) then {
        _movementWaypoints deleteAt (count _movementWaypoints - 1);
    };

    private _rotationIndex = _currentWaypointIndex;
    if (_rotationIndex >= count _movementWaypoints) then { _rotationIndex = 0; };
    _remaining = (_movementWaypoints select [_rotationIndex]) + (_movementWaypoints select [0, _rotationIndex]);
    if (_cycleWaypoint isNotEqualTo []) then { _remaining pushBack _cycleWaypoint; };
} else {
    if (_currentWaypointIndex < count _allWaypoints) then {
        _remaining = _allWaypoints select [_currentWaypointIndex];
    };
};

[
    _startPos,
    _remaining,
    true,
    _sourceTag,
    _loopRoute && {_cycleIndex < 0}
] call FLO_fnc_virtualizationResolveLandWaypoints
