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

if (isNull _realGroup) exitWith {
    ["VIRTUALIZATION", 1, format [
        "Refusing to spawn crewed vehicle %1 because target group is null",
        _vehicleType
    ]] call FLO_fnc_log;
    objNull
};

private _vehicle = createVehicle [_vehicleType, _spawnPos, [], 0, if (_fly) then { "FLY" } else { "NONE" }];

if (!_fly) then {
    _vehicle setPos [getPos _vehicle select 0, getPos _vehicle select 1, 0];
    _vehicle setVectorUp [0,0,1];
    _vehicle setVelocity [0, 0, 0];
    _vehicle engineOn false;
};

private _crewSpawnPos = if (_fly) then { [0,0,0] } else { _spawnPos };
private _driver = _realGroup createUnit [_crewType, _crewSpawnPos, [], 0, "NONE"];
if (isNull _driver) exitWith {
    ["VIRTUALIZATION", 1, format [
        "Failed to create driver %1 for vehicle %2 - deleting empty vehicle",
        _crewType,
        _vehicleType
    ]] call FLO_fnc_log;
    deleteVehicle _vehicle;
    objNull
};
_driver moveInDriver _vehicle;

{
    private _gunner = _realGroup createUnit [_crewType, _crewSpawnPos, [], 0, "NONE"];
    _gunner moveInTurret [_vehicle, _x];
} forEach (allTurrets [_vehicle, false]);

if (!_fly) then {
    _vehicle setVelocity [0, 0, 0];
    _vehicle engineOn false;
};

_vehicle
