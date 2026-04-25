/*
 * Function: FLO_fnc_minefieldRegisterSpacingPos
 * Author: Frontline Operations Development Group
 * Description:
 *   Registers one accepted mine position in the spatial spacing hash.
 *
 * Arguments:
 * 0: Position <ARRAY>
 * 1: Spacing index <HASHMAP>
 * 2: Minimum spacing <SCALAR>
 *
 * Return Value:
 * BOOL
 */

params [
    ["_position", [0, 0, 0]],
    ["_spacingIndex", createHashMap],
    ["_minSpacing", 0]
];

if ((count _position) < 2) exitWith { false };
if !(_spacingIndex isEqualType createHashMap) exitWith { false };
if (_minSpacing <= 0) exitWith { false };

private _cellSize = _minSpacing max 1;
private _cellX = floor ((_position select 0) / _cellSize);
private _cellY = floor ((_position select 1) / _cellSize);
private _bucketKey = format ["%1|%2", _cellX, _cellY];
private _bucket = _spacingIndex getOrDefault [_bucketKey, []];
_bucket pushBack _position;
_spacingIndex set [_bucketKey, _bucket];

true
