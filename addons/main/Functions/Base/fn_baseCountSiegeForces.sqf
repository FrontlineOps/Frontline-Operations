/* Counts friendly and hostile siege presence relative to one base's owner. */
params [
    ["_base", objNull, [objNull]],
    ["_radius", 0, [0]],
    ["_baseSide", sideUnknown, [sideUnknown]]
];

if (isNull _base || {_radius <= 0} || {!(_baseSide in [west, east])}) then {
    ["BASE", 1, format ["Invalid siege count request: base=%1 radius=%2 side=%3", _base, _radius, _baseSide]] call FLO_fnc_log;
    throw "FLO_fnc_baseCountSiegeForces received invalid required state";
};

private _enemySide = [_baseSide] call FLO_fnc_opposingSide;
private _basePos = getPosATL _base;
private _nearEntities = _base nearEntities [["Man", "LandVehicle"], _radius];
private _friendlyCount = 0;
private _enemyCount = 0;

{
    if (!alive _x || {(_x distance2D _basePos) > _radius}) then { continue };

    private _entitySide = if (isPlayer _x) then { side group _x } else { side _x };
    if (_entitySide isEqualTo _baseSide) then { _friendlyCount = _friendlyCount + 1 };
    if (_entitySide isEqualTo _enemySide) then { _enemyCount = _enemyCount + 1 };
} forEach _nearEntities;

{
    if (!alive _x || {_x in _nearEntities} || {(_x distance2D _basePos) > _radius}) then { continue };

    private _playerSide = side group _x;
    if (_playerSide isEqualTo _baseSide) then { _friendlyCount = _friendlyCount + 1 };
    if (_playerSide isEqualTo _enemySide) then { _enemyCount = _enemyCount + 1 };
} forEach ([] call FLO_fnc_getConnectedHumanPlayers);

[_friendlyCount, _enemyCount]
