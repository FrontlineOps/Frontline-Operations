/* Resolves deterministic off-map reserve and terrain-edge route positions. */
params [
    ["_side", sideUnknown],
    ["_referencePos", [0, 0, 0], [[]]]
];

if !(_side in [east, west]) then {
    throw format ["Cannot resolve air reserve positions for side %1", _side];
};

private _mapSize = worldSize;
if (_mapSize <= 1000) then {
    private _message = format ["Engine worldSize is invalid while resolving air reserve routes: %1", _mapSize];
    ["GTN Air", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _referenceY = (_referencePos select 1) max 500 min (_mapSize - 500);
private _west = _side isEqualTo west;
private _reserveX = [-2000, _mapSize + 2000] select (!_west);
private _ingressX = [250, _mapSize - 250] select (!_west);
private _egressX = [-250, _mapSize + 250] select (!_west);

[
    [_reserveX, _referenceY, 500],
    [_ingressX, _referenceY, 500],
    [_egressX, _referenceY, 500]
]
