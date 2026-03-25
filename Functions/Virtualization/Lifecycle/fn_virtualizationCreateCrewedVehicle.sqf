/*
 * Function: FLO_fnc_virtualizationCreateCrewedVehicle
 */

params [
    "_realGroup",
    "_vehicleType",
    "_spawnPos",
    "_crewType",
    ["_fly", false, [true]]
];

private _vehicle = createVehicle [_vehicleType, _spawnPos, [], 0, if (_fly) then { "FLY" } else { "NONE" }];

if (!_fly) then {
    _vehicle setPos [getPos _vehicle select 0, getPos _vehicle select 1, 0];
    _vehicle setVectorUp [0,0,1];
};

private _crewSpawnPos = if (_fly) then { [0,0,0] } else { _spawnPos };
private _driver = _realGroup createUnit [_crewType, _crewSpawnPos, [], 0, "NONE"];
_driver moveInDriver _vehicle;

{
    private _gunner = _realGroup createUnit [_crewType, _crewSpawnPos, [], 0, "NONE"];
    _gunner moveInTurret [_vehicle, _x];
} forEach (allTurrets [_vehicle, false]);

_vehicle
