/*
 * Function: FLO_fnc_gtnDistanceToSegment2D
 * Author: Frontline Operations Development Group
 * Description:
 *   Computes 2D point-to-segment distance.
 *
 * Arguments:
 * 0: Point <ARRAY>
 * 1: Segment start <ARRAY>
 * 2: Segment end <ARRAY>
 *
 * Return Value:
 * NUMBER - Distance in meters
 */

params ["_point", "_fromPos", "_toPos"];

private _px = _point select 0;
private _py = _point select 1;
private _ax = _fromPos select 0;
private _ay = _fromPos select 1;
private _bx = _toPos select 0;
private _by = _toPos select 1;

private _abx = _bx - _ax;
private _aby = _by - _ay;
private _abLenSq = (_abx * _abx) + (_aby * _aby);
if (_abLenSq <= 0.001) exitWith {
    _point distance2D _fromPos
};

private _apx = _px - _ax;
private _apy = _py - _ay;
private _t = ((_apx * _abx) + (_apy * _aby)) / _abLenSq;
if (_t < 0) then { _t = 0; };
if (_t > 1) then { _t = 1; };

private _closestPos = [
    _ax + (_abx * _t),
    _ay + (_aby * _t),
    0
];

_point distance2D _closestPos
