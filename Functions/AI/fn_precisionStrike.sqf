/*
    Function: FLO_fnc_precisionStrike

    Description:
        Orders an aircraft to execute a precision strike on a target position.
        A suitable weapon is selected from the aircraft loadout using
        <https://community.bistudio.com/wiki/getPylonMagazines>. Bombs,
        rockets, missiles or the cannon can be used. The ordnance is spawned
        directly under the aircraft similar to the Antistasi
        "fn_airbomb.sqf" example so the attack is visibly executed by the
        aircraft. Spent pylons are cleared with
        <https://community.bistudio.com/wiki/setPylonLoadOut>.

    Parameters:
        _aircraft - Aircraft object executing the strike [Object]
        _targetPos - Target position [Array]
        _mission - Mission type ("CAS", "BOMB" or "LASER") [String]
        _altitude - Desired flight altitude [Number]

    Returns:
        Boolean - True if ordnance was released
*/

params [
    ["_aircraft", objNull, [objNull]],
    ["_targetPos", [0,0,0], [[]], [3]],
    ["_mission", "BOMB", [""]],
    ["_altitude", 300, [0]]
];

if (isNull _aircraft) exitWith {
    ["PrecisionStrike", 2, "Aborted - null aircraft"] call FLO_fnc_log;
    false
};

["PrecisionStrike", 3, format["Starting %1 strike with %2 at %3, alt %4m", _mission, typeOf _aircraft, _targetPos, _altitude]] call FLO_fnc_log;

private _missionUC = toUpper _mission;
private _mags = getPylonMagazines _aircraft;
["PrecisionStrike", 4, format["Available pylons: %1", _mags]] call FLO_fnc_log;

private _selectedMag = "";
private _isGun = false;

{
    private _mag = _x;
    if (_mag isEqualTo "") then {continue};
    private _ammo = getText (configFile >> "CfgMagazines" >> _mag >> "ammo");
    private _sim  = toLower getText (configFile >> "CfgAmmo" >> _ammo >> "simulation");

    switch (_missionUC) do {
        case "LASER": {
            private _laser = getNumber (configFile >> "CfgAmmo" >> _ammo >> "laserLock") == 1;
            if (_sim find "missile" >= 0 && _laser) exitWith { _selectedMag = _mag };
        };
        case "BOMB": {
            if (_sim find "bomb" >= 0) exitWith { _selectedMag = _mag };
        };
        case "CAS": {
            if (_sim find "rocket" >= 0 || (_sim find "missile" >= 0 && getNumber (configFile >> "CfgAmmo" >> _ammo >> "laserLock") == 0)) exitWith { _selectedMag = _mag };
        };
    };
} forEach _mags;

if (_missionUC == "CAS" && _selectedMag isEqualTo "") then {
    {
        private _weaponMags = getArray (configFile >> "CfgWeapons" >> _x >> "magazines");
        if (count _weaponMags > 0) exitWith {
            _selectedMag = _weaponMags select 0;
            _isGun = true;
        };
    } forEach weapons _aircraft;
};

if (_selectedMag isEqualTo "") exitWith {
    ["PrecisionStrike", 2, format["No suitable ordnance found for %1 mission on %2", _missionUC, typeOf _aircraft]] call FLO_fnc_log;
    false
};

private _ammo     = getText (configFile >> "CfgMagazines" >> _selectedMag >> "ammo");
private _bombCnt  = getNumber (configFile >> "CfgMagazines" >> _selectedMag >> "count");
private _pIndex   = (_mags find _selectedMag) + 1; // pylon index for removal
if (_bombCnt <= 0) then { _bombCnt = 1; };

["PrecisionStrike", 3, format["Selected ordnance: %1 (ammo: %2, count: %3, isGun: %4)", _selectedMag, _ammo, _bombCnt, _isGun]] call FLO_fnc_log;

_aircraft flyInHeight _altitude;
_aircraft doMove _targetPos;

["PrecisionStrike", 3, format["Aircraft en route to target, distance: %1m", round (_aircraft distance2D _targetPos)]] call FLO_fnc_log;

waitUntil { sleep 1; !alive _aircraft || (_aircraft distance2D _targetPos) < 200 };

if (!alive _aircraft) exitWith {
    ["PrecisionStrike", 2, "Aircraft destroyed before reaching target"] call FLO_fnc_log;
    false
};

["PrecisionStrike", 3, format["Aircraft in range (%1m), beginning attack run", round (_aircraft distance2D _targetPos)]] call FLO_fnc_log;

private _runLength = 250;
private _speedMS   = (speed _aircraft) / 3.6;
private _timeStep  = (_runLength / _bombCnt / _speedMS) max 0.1;

private _laserTarget = objNull;

if (_missionUC == "LASER") then {
    ["PrecisionStrike", 3, "LASER mission - searching for target"] call FLO_fnc_log;
    private _target = objNull;
    private _candidates = vehicles + allUnits;
    private _near = _candidates select {
        side _x == west && alive _x && { _x distance2D _targetPos < 25 }
    };
    if (count _near > 0) then {
        _near sort true; // nearest first
        _target = _near select 0;
        ["PrecisionStrike", 3, format["Laser locked onto %1", typeOf _target]] call FLO_fnc_log;
    } else {
        ["PrecisionStrike", 3, "No targets found, lasing ground position"] call FLO_fnc_log;
    };

    if (!isNull _target) then {
        _laserTarget = "LaserTargetE" createVehicle [0,0,0];
        _laserTarget attachTo [_target, [0,0,0]];
    } else {
        _laserTarget = "LaserTargetE" createVehicle _targetPos;
    };

    private _missile = _ammo createVehicle (getPosASL _aircraft);
    _missile setMissileTarget _laserTarget;
    _missile setDir (getDir _aircraft);
    _missile setShotParents [_aircraft, driver _aircraft];
    _missile setVelocityModelSpace [0,60,0];
    if (_pIndex > 0) then { _aircraft setPylonLoadOut [_pIndex, "", true]; };
    ["PrecisionStrike", 3, format["Laser-guided missile launched: %1", _ammo]] call FLO_fnc_log;
    [_laserTarget, _missile] spawn {
        params ["_t", "_m"];
        waitUntil { sleep 0.5; isNull _m || !alive _m };
        deleteVehicle _t;
    };
} else {
    ["PrecisionStrike", 3, format["Releasing %1x ordnance over %2 seconds", _bombCnt, round (_timeStep * _bombCnt)]] call FLO_fnc_log;
    sleep (_timeStep / 2);
    private _released = 0;
    for "_i" from 1 to _bombCnt do {
        if (!alive _aircraft) exitWith {};
        private _bombPos = (getPosATL _aircraft) vectorAdd [0,0,-5];
        private _proj = _ammo createVehicle _bombPos;
        _proj setDir (getDir _aircraft);
        if (_isGun) then {
            _proj setVelocityModelSpace [0,500,0];
        } else {
            if (_missionUC == "CAS") then {
                _proj setVelocityModelSpace [0,120,0];
            } else {
                _proj setVelocity [0,0,-50];
            };
        };
        _proj setShotParents [_aircraft, driver _aircraft];
        _released = _released + 1;
        sleep _timeStep;
    };
    if (_pIndex > 0 && !_isGun) then { _aircraft setPylonLoadOut [_pIndex, "", true]; };
    ["PrecisionStrike", 3, format["Attack complete - released %1/%2 ordnance", _released, _bombCnt]] call FLO_fnc_log;
};

["PrecisionStrike", 3, format["Mission complete: %1 strike on %2", _missionUC, _targetPos]] call FLO_fnc_log;
true
