/*
 * Function: FLO_fnc_gtnBuildArtilleryFirePlan
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a deterministic fire plan for an artillery mission so alert
 *   visualization and the actual fire mission use the same impact pattern.
 *
 * Arguments:
 *   0: Real artillery group <GROUP>
 *   1: Target position <ARRAY>
 *   2: Number of rounds <NUMBER>
 *   3: Accuracy / dispersion meters <NUMBER>
 *
 * Return Value:
 *   HASHMAP
 */

params [
    ["_realGroup", grpNull, [grpNull]],
    ["_targetPos", [0, 0, 0], [[]], [3]],
    ["_rounds", 0, [0]],
    ["_accuracy", 100, [0]]
];

if (isNull _realGroup) exitWith { createHashMap };

private _vehicles = [_realGroup] call FLO_fnc_gtnCollectArtilleryVehicles;
if (_vehicles isEqualTo []) exitWith { createHashMap };

private _gunCount = count _vehicles;
private _roundsPerGun = ceil (_rounds / _gunCount);
if (_rounds > 0 && {_roundsPerGun < 1}) then {
    _roundsPerGun = 1;
};

private _vehiclePlans = [];
private _impactPoints = [];
private _etaMin = 1e12;
private _etaMax = 0;

{
    private _veh = _x;
    private _ammo = (getArtilleryAmmo [_veh]) param [0, ""];
    if (_ammo isEqualTo "") then { continue };

    private _isMLRS = _veh isKindOf "MLRS" || {getText (configOf _veh >> "simulation") == "airplanex"};
    private _localAccuracy = _accuracy;
    private _salvo = 1;
    private _shotCount = _roundsPerGun;

    if (_isMLRS) then {
        _localAccuracy = _localAccuracy * 1.5;
        private _gunner = gunner _veh;
        if (!isNull _gunner) then {
            private _gunnerAmmo = _gunner ammo (currentMuzzle _gunner);
            if (_gunnerAmmo >= 6) then {
                _salvo = 3 + floor random 4;
                _shotCount = ceil (_shotCount / _salvo);
            };
        };
    };

    private _direction = _veh getDir _targetPos;
    private _center = _targetPos getPos [_localAccuracy * 0.33, -_direction];
    private _offset = 0;
    private _targets = [];

    for "_i" from 1 to _shotCount do {
        private _impactPos = _center getPos [_offset + random _localAccuracy, _direction + 45 - random 90];
        _targets pushBack _impactPos;
        if ((count _impactPoints) < 6) then {
            _impactPoints pushBack _impactPos;
        };
        _offset = _offset + (_localAccuracy * 0.33);
    };

    if (_targets isEqualTo []) then { continue };

    private _ammoSpeed = getNumber (configFile >> "CfgAmmo" >> _ammo >> "typicalSpeed");
    if (_ammoSpeed <= 0) then {
        _ammoSpeed = switch (true) do {
            case (_isMLRS): { 320 };
            case (_veh isKindOf "StaticMortar"): { 110 };
            default { 240 };
        };
    };

    private _setupDelay = switch (true) do {
        case (_isMLRS): { 8 };
        case (_veh isKindOf "StaticMortar"): { 10 };
        default { 12 };
    };
    private _cadenceSeconds = [5, 1.5] select (_salvo > 1);
    private _flightSeconds = (((_veh distance2D (_targets select 0)) / _ammoSpeed) * 1.35) max 4;
    private _vehicleEtaMin = ceil (_setupDelay + _flightSeconds);
    private _vehicleEtaMax = ceil (_vehicleEtaMin + (((count _targets) - 1) * _cadenceSeconds));

    if (_vehicleEtaMin < _etaMin) then {
        _etaMin = _vehicleEtaMin;
    };
    if (_vehicleEtaMax > _etaMax) then {
        _etaMax = _vehicleEtaMax;
    };

    _vehiclePlans pushBack (createHashMapFromArray [
        ["vehicle", _veh],
        ["ammo", _ammo],
        ["salvo", _salvo],
        ["targets", _targets]
    ]);
} forEach _vehicles;

if (_vehiclePlans isEqualTo []) exitWith { createHashMap };
if (_etaMin isEqualTo 1e12) then {
    _etaMin = -1;
};

createHashMapFromArray [
    ["vehiclePlans", _vehiclePlans],
    ["impactPoints", _impactPoints],
    ["etaMin", _etaMin],
    ["etaMax", _etaMax]
]
