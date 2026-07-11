/*
 * Function: FLO_fnc_minefieldCanPlaceWithSpacing
 * Author: Frontline Operations Development Group
 * Description:
 *   Checks spacing against a small spatial hash instead of scanning every
 *   planned mine slot linearly.
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
if (!(_spacingIndex isEqualType createHashMap)) exitWith { true };
if (_minSpacing <= 0) exitWith { true };

private _cellSize = _minSpacing max 1;
private _cellX = floor ((_position select 0) / _cellSize);
private _cellY = floor ((_position select 1) / _cellSize);
private _canPlace = true;

for "_dx" from -1 to 1 do {
    if (!_canPlace) exitWith {};
    for "_dy" from -1 to 1 do {
        if (!_canPlace) exitWith {};
        private _bucketKey = format ["%1|%2", _cellX + _dx, _cellY + _dy];
        private _bucket = _spacingIndex getOrDefault [_bucketKey, []];
        {
            if ((_position distance2D _x) < _minSpacing) exitWith {
                _canPlace = false;
            };
        } forEach _bucket;
    };
};

_canPlace
