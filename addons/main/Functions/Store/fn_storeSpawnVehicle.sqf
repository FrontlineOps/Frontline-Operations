params ["_access", "_vehicleClass"];

if (!isServer) exitWith { objNull };
if !(isClass (configFile >> "CfgVehicles" >> _vehicleClass)) exitWith { objNull };

private _base = _access get "base";
private _player = _access get "player";
private _origin = if (!isNull _base) then { getPosATL _base } else { getPosATL _player };
private _spawnPos = _origin findEmptyPosition [8, 45, _vehicleClass];

if (_spawnPos isEqualTo []) then {
    _spawnPos = _origin vectorAdd [8, 0, 0];
};

private _vehicle = createVehicle [_vehicleClass, _spawnPos, [], 0, "NONE"];
_vehicle setDir (getDir _base);
_vehicle allowDamage true;
[_vehicle, _vehicleClass, true] call FLO_fnc_vehicleConfigureRequestedVehicle;

["STORE", 3, format ["Spawned purchased vehicle %1 at %2", _vehicleClass, mapGridPosition _vehicle]] call FLO_fnc_log;

_vehicle
