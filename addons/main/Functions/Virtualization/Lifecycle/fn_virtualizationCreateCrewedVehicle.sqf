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
if (count _spawnPos < 2) exitWith {
    ["VIRTUALIZATION", 1, format ["Refusing to spawn %1 at invalid position %2", _vehicleType, _spawnPos]] call FLO_fnc_log;
    objNull
};

private _vehicle = createVehicle [_vehicleType, _spawnPos, [], 0, ["NONE", "FLY"] select (_fly)];
if (isNull _vehicle) exitWith {
    ["VIRTUALIZATION", 1, format ["Engine failed to create vehicle %1 at %2", _vehicleType, _spawnPos]] call FLO_fnc_log;
    objNull
};
_realGroup addVehicle _vehicle;

if (!_fly) then {
    _vehicle setVelocity [0, 0, 0];
    _vehicle engineOn false;
};

private _crewSpawnPos = if (_fly) then { [0,0,0] } else { _spawnPos };
private _crewCreated = 0;
private _crewFailed = false;
private _createdCrew = [];
private _hasDriver = getNumber (configFile >> "CfgVehicles" >> _vehicleType >> "hasDriver") > 0;
private _turrets = allTurrets [_vehicle, false];
if (_hasDriver) then {
    private _driver = [
        _realGroup,
        _crewType,
        _crewSpawnPos,
        [],
        0,
        "NONE",
        format ["vehicle=%1 role=driver", _vehicleType]
    ] call FLO_fnc_createGroupUnit;
    if (isNull _driver) then {
        _crewFailed = true;
    } else {
        _driver moveInDriver _vehicle;
        _createdCrew pushBack _driver;
        _crewCreated = _crewCreated + 1;
    };
};

{
    private _gunner = [
        _realGroup,
        _crewType,
        _crewSpawnPos,
        [],
        0,
        "NONE",
        format ["vehicle=%1 role=turret%2", _vehicleType, _x]
    ] call FLO_fnc_createGroupUnit;
    if (isNull _gunner) then {
        _crewFailed = true;
    } else {
        _gunner moveInTurret [_vehicle, _x];
        _createdCrew pushBack _gunner;
        _crewCreated = _crewCreated + 1;
    };
} forEach _turrets;

if (!_hasDriver && {_turrets isEqualTo []}) then {
    private _operator = [
        _realGroup,
        _crewType,
        _crewSpawnPos,
        [],
        0,
        "NONE",
        format ["vehicle=%1 role=operator", _vehicleType]
    ] call FLO_fnc_createGroupUnit;
    if (isNull _operator) then {
        _crewFailed = true;
    } else {
        _createdCrew pushBack _operator;
        _crewCreated = _crewCreated + 1;
    };
};

if (_crewFailed || {_crewCreated == 0}) exitWith {
    ["VIRTUALIZATION", 1, format ["Failed to create crew %1 for vehicle %2", _crewType, _vehicleType]] call FLO_fnc_log;
    { deleteVehicle _x; } forEach _createdCrew;
    deleteVehicle _vehicle;
    objNull
};

if (!_fly) then {
    _vehicle setVelocity [0, 0, 0];
    _vehicle engineOn false;
};

_vehicle
