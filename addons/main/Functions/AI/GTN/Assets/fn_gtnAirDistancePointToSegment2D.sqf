/* Returns the 2D distance from a point to a finite line segment. */
params [
    ["_point", [0, 0, 0], [[]]],
    ["_start", [0, 0, 0], [[]]],
    ["_end", [0, 0, 0], [[]]]
];

private _vx = (_end select 0) - (_start select 0);
private _vy = (_end select 1) - (_start select 1);
private _lengthSq = (_vx * _vx) + (_vy * _vy);
if (_lengthSq <= 0.001) exitWith { _point distance2D _start };

private _wx = (_point select 0) - (_start select 0);
private _wy = (_point select 1) - (_start select 1);
private _factor = (((_wx * _vx) + (_wy * _vy)) / _lengthSq) max 0 min 1;
private _projection = [
    (_start select 0) + (_vx * _factor),
    (_start select 1) + (_vy * _factor),
    0
];

_point distance2D _projection
