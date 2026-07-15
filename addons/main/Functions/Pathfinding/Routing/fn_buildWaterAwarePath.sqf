/*
 * Function: FLO_fnc_buildWaterAwarePath
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a coarse path that only cares about keeping ground movement off
 *   water. Straight land segments resolve directly; water crossings are split
 *   through coarse detour pivots.
 *
 * Arguments:
 *   0: Start position <ARRAY>
 *   1: End position <ARRAY>
 *   2: Sample step meters <NUMBER>
 *   3: Recursion depth <NUMBER>
 *
 * Return Value:
 *   [pathPositions, sampleCount, usedFallback]
 */

params [
    ["_startPos", [0, 0, 0], [[]], [2, 3]],
    ["_endPos", [0, 0, 0], [[]], [2, 3]],
    ["_sampleStep", 180, [0]],
    ["_depth", 0, [0]]
];

private _start = +_startPos;
private _end = +_endPos;
if (count _start > 2) then { _start set [2, 0]; } else { _start pushBack 0; };
if (count _end > 2) then { _end set [2, 0]; } else { _end pushBack 0; };

private _profile = [_start, _end, _sampleStep] call FLO_fnc_pathSegmentWaterProfile;
private _sampleCount = _profile select 1;
if !(_profile select 0) exitWith { [[_end], _sampleCount, false] };

if (_depth >= FLO_PF_WaterRouteMaxDepth) exitWith {
    [[], _sampleCount, true]
};

private _detourResult = [_start, _end, _profile, _sampleStep] call FLO_fnc_findWaterDetour;
private _detourPoints = _detourResult select 0;
_sampleCount = _sampleCount + (_detourResult select 1);

if (_detourPoints isEqualTo []) exitWith {
    [[], _sampleCount, true]
};

private _route = [];
private _cursor = +_start;
private _usedFallback = false;
private _failed = false;

{
    private _segment = [_cursor, _x, _sampleStep, _depth + 1] call FLO_fnc_buildWaterAwarePath;
    _sampleCount = _sampleCount + (_segment select 1);
    _usedFallback = _usedFallback || (_segment select 2);

    if ((_segment select 0) isEqualTo [] || {_segment select 2}) then {
        _failed = true;
        continue;
    };

    {
        if (_route isEqualTo [] || {(_route select -1) distance2D _x > 5}) then {
            _route pushBack _x;
        };
    } forEach (_segment select 0);

    _cursor = +_x;
} forEach _detourPoints;

if (_failed) exitWith { [[], _sampleCount, true] };

private _tail = [_cursor, _end, _sampleStep, _depth + 1] call FLO_fnc_buildWaterAwarePath;
_sampleCount = _sampleCount + (_tail select 1);
_usedFallback = _usedFallback || (_tail select 2);

if ((_tail select 0) isEqualTo [] || {_tail select 2}) exitWith {
    [[], _sampleCount, true]
};

{
    if (_route isEqualTo [] || {(_route select -1) distance2D _x > 5}) then {
        _route pushBack _x;
    };
} forEach (_tail select 0);

private _lastRouteIndex = count _route - 1;
if ((_route select _lastRouteIndex) isNotEqualTo _end) then {
    if ((_route select _lastRouteIndex) distance2D _end <= 5) then {
        _route set [_lastRouteIndex, +_end];
    } else {
        _route pushBack (+_end);
    };
};

[_route, _sampleCount, _usedFallback]
