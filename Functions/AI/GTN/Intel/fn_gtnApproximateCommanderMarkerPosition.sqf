/*
 * Function: FLO_fnc_gtnApproximateCommanderMarkerPosition
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies a deterministic, stable reporting error to a marker position so
 *   remote virtual friendly markers are not rendered with perfect precision.
 *
 * Arguments:
 *   0: Base position <ARRAY>
 *   1: Stable marker key <STRING>
 *   2: Precision meters <NUMBER>
 *
 * Return Value:
 *   Approximated position <ARRAY>
 */

params [
    ["_position", [0, 0, 0], [[]], [3]],
    ["_markerKey", "", [""]],
    ["_precision", 0, [0]]
];

if (_precision <= 0 || {_markerKey isEqualTo ""}) exitWith { _position };

private _chars = toArray _markerKey;
private _seedA = 0;
private _seedB = 0;

{
    _seedA = (_seedA + (((_x + 17) * (_forEachIndex + 1)) mod 997)) mod 997;
    _seedB = (_seedB + (((_x + 43) * (_forEachIndex + 3)) mod 991)) mod 991;
} forEach _chars;

private _dir = (_seedA / 997) * 360;
private _dist = (_precision * 0.2) + ((_seedB / 991) * (_precision * 0.6));
private _gridPos = [
    (round ((_position select 0) / _precision)) * _precision,
    (round ((_position select 1) / _precision)) * _precision,
    _position select 2
];

[
    (_gridPos select 0) + ((sin _dir) * _dist),
    (_gridPos select 1) + ((cos _dir) * _dist),
    _gridPos select 2
]
