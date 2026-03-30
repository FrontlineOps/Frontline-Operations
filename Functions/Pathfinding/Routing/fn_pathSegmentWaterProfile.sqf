/*
 * Function: FLO_fnc_pathSegmentWaterProfile
 * Author: Frontline Operations Development Group
 * Description:
 *   Samples a route segment and reports whether it crosses water, together
 *   with the sampled entry/exit span used by the water-only route builder.
 *
 * Arguments:
 *   0: Start position <ARRAY>
 *   1: End position <ARRAY>
 *   2: Sample step meters <NUMBER>
 *
 * Return Value:
 *   [crossesWater, sampleCount, lastLandBefore, firstWater, lastWater, firstLandAfter]
 */

params [
    ["_startPos", [0, 0, 0], [[]], [2, 3]],
    ["_endPos", [0, 0, 0], [[]], [2, 3]],
    ["_sampleStep", 180, [0]]
];

private _start = +_startPos;
private _end = +_endPos;
if (count _start > 2) then { _start set [2, 0]; } else { _start pushBack 0; };
if (count _end > 2) then { _end set [2, 0]; } else { _end pushBack 0; };

private _dist = _start distance2D _end;
if (_dist <= 5) exitWith {
    [false, 0, _start, [], [], _end]
};

private _segments = ceil (_dist / (_sampleStep max 25));
if (_segments < 2) then { _segments = 2; };

private _crossesWater = false;
private _sampleCount = 0;
private _lastLandBefore = +_start;
private _firstWater = [];
private _lastWater = [];
private _firstLandAfter = [];
private _prevSample = +_start;

for "_i" from 1 to (_segments - 1) do {
    private _t = _i / _segments;
    private _sample = [
        ((_start select 0) + (((_end select 0) - (_start select 0)) * _t)),
        ((_start select 1) + (((_end select 1) - (_start select 1)) * _t)),
        0
    ];
    _sampleCount = _sampleCount + 1;

    if (surfaceIsWater _sample) then {
        if (!_crossesWater) then {
            _crossesWater = true;
            _firstWater = +_sample;
            _lastLandBefore = +_prevSample;
        };
        _lastWater = +_sample;
    } else {
        if (_crossesWater && {count _firstLandAfter == 0}) then {
            _firstLandAfter = +_sample;
        };
    };

    _prevSample = +_sample;
};

if (_crossesWater && {count _firstLandAfter == 0}) then {
    _firstLandAfter = +_end;
};

[
    _crossesWater,
    _sampleCount,
    _lastLandBefore,
    _firstWater,
    _lastWater,
    _firstLandAfter
]
