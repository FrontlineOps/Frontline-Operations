/*
 * Function: FLO_fnc_virtualizationComputeDeferredActivationPos
 */

params ["_position", "_activationDistance"];

private _cachedPlayers = FLO_VirtUpdate get "cachedPlayerPositions";
private _nearestPlayerPos = [];
private _nearestDist = 1e10;

{
    _x params ["_playerPos", "_inAir"];
    if (!_inAir) then {
        private _dist = _position distance2D _playerPos;
        if (_dist < _nearestDist) then {
            _nearestDist = _dist;
            _nearestPlayerPos = _playerPos;
        };
    };
} forEach _cachedPlayers;

if (_nearestPlayerPos isEqualTo []) exitWith { _position };

private _direction = if (_nearestDist < 1) then {
    random 360
} else {
    _nearestPlayerPos getDir _position
};

private _deferredPos = _nearestPlayerPos getPos [_activationDistance + 25, _direction];
_deferredPos set [2, _position param [2, 0]];
_deferredPos
