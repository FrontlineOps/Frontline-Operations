/*
 * Function: FLO_fnc_validateWaterAwarePath
 * Description:
 *   Validates every segment of a resolved land path at a bounded sampling
 *   interval. The path excludes the supplied start and includes its endpoint.
 *
 * Return Value:
 *   [isValid, sampleCount]
 */

params [
    ["_startPos", [0, 0, 0], [[]], [2, 3]],
    ["_path", [], [[]]],
    ["_sampleStep", 40, [0]]
];

if (surfaceIsWater _startPos) exitWith { [false, 1] };

private _cursor = +_startPos;
private _sampleCount = 0;
private _valid = true;

{
    if (surfaceIsWater _x) then {
        _valid = false;
        _sampleCount = _sampleCount + 1;
        continue;
    };

    private _profile = [_cursor, _x, _sampleStep] call FLO_fnc_pathSegmentWaterProfile;
    _sampleCount = _sampleCount + (_profile select 1);
    if (_profile select 0) then {
        _valid = false;
        continue;
    };

    _cursor = +_x;
} forEach _path;

[_valid, _sampleCount]
