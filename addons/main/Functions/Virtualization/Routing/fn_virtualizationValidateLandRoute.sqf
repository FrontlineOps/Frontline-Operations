/*
 * Function: FLO_fnc_virtualizationValidateLandRoute
 * Description:
 *   Terrain-validates an exact canonical LAND route without rewriting it.
 *   Both the live continuation and every stored segment are checked.
 *
 * Return Value:
 *   [valid, reason, sampleCount]
 */

params [
    ["_groupId", "", [""]],
    ["_startPos", [0, 0, 0], [[]], [2, 3]],
    ["_waypoints", [], [[]]],
    ["_currentWaypointIndex", 0, [0]],
    ["_autoPatrol", false, [true]],
    ["_patrolConfig", [], [[]]]
];

if (_waypoints isEqualTo []) exitWith { [true, "", 0] };
if (surfaceIsWater _startPos) exitWith { [false, "START_IN_WATER", 1] };

private _positions = _waypoints apply { +(_x select 0) };
private _hasCycle = (_waypoints findIf { toUpper (_x select 1) == "CYCLE" }) >= 0;
private _isLoop = _autoPatrol || {_patrolConfig isNotEqualTo []} || {_hasCycle};
private _sampleCount = 0;

private _continuation = if (_isLoop) then {
    private _ordered = (_positions select [_currentWaypointIndex]) + (_positions select [0, _currentWaypointIndex]);
    _ordered pushBack (+(_ordered select 0));
    _ordered
} else {
    _positions select [_currentWaypointIndex]
};

private _continuationValidation = [
    _startPos,
    _continuation,
    FLO_PF_WaterValidationStep
] call FLO_fnc_validateWaterAwarePath;
_sampleCount = _sampleCount + (_continuationValidation select 1);
if !(_continuationValidation select 0) exitWith {
    [false, format ["UNSAFE_CONTINUATION:%1", _groupId], _sampleCount]
};

private _storedSegmentsValid = true;
if (count _positions > 1) then {
    private _storedValidation = [
        _positions select 0,
        _positions select [1],
        FLO_PF_WaterValidationStep
    ] call FLO_fnc_validateWaterAwarePath;
    _sampleCount = _sampleCount + (_storedValidation select 1);
    _storedSegmentsValid = _storedValidation select 0;
};

if (!_storedSegmentsValid) exitWith {
    [false, format ["UNSAFE_STORED_SEGMENT:%1", _groupId], _sampleCount]
};

[true, "", _sampleCount]
