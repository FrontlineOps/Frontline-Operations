/*
    Function: FLO_fnc_precisionStrike

    Description:
        Orders an aircraft to execute precision strikes on a target position.
        Performs multiple attack passes while ordnance remains available.
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

// Helper function to find available ordnance for the mission type
private _fnc_findOrdnance = {
    params ["_ac", "_missionType"];
    private _result = ["", "", -1, false]; // [magazine, ammo, pylonIndex, isGun]
    private _mags = getPylonMagazines _ac;

    {
        private _mag = _x;
        if (_mag isEqualTo "") then { continue };
        private _ammoType = getText (configFile >> "CfgMagazines" >> _mag >> "ammo");
        private _sim = toLower getText (configFile >> "CfgAmmo" >> _ammoType >> "simulation");

        private _matches = switch (_missionType) do {
            case "LASER": {
                private _laser = getNumber (configFile >> "CfgAmmo" >> _ammoType >> "laserLock") == 1;
                (_sim find "missile" >= 0 && _laser)
            };
            case "BOMB": { _sim find "bomb" >= 0 };
            case "CAS": {
                _sim find "rocket" >= 0 ||
                (_sim find "missile" >= 0 && getNumber (configFile >> "CfgAmmo" >> _ammoType >> "laserLock") == 0)
            };
            default { false };
        };

        if (_matches) exitWith {
            _result = [_mag, _ammoType, _forEachIndex + 1, false];
        };
    } forEach _mags;

    // Fallback to guns for CAS if no pylon ordnance
    if (_missionType == "CAS" && (_result select 0) isEqualTo "") then {
        {
            private _weaponMags = getArray (configFile >> "CfgWeapons" >> _x >> "magazines");
            if (count _weaponMags > 0) exitWith {
                private _mag = _weaponMags select 0;
                private _ammoType = getText (configFile >> "CfgMagazines" >> _mag >> "ammo");
                _result = [_mag, _ammoType, -1, true];
            };
        } forEach weapons _ac;
    };

    _result
};

private _missionUC = toUpper _mission;

["PrecisionStrike", 3, format["Starting %1 strike with %2 at %3, alt %4m", _mission, typeOf _aircraft, _targetPos, _altitude]] call FLO_fnc_log;

// Update activity timestamp - prevents ATO timeout during multi-pass attacks
_aircraft setVariable ["FLO_lastActivityTime", time, true];

// Find initial ordnance
private _ordnanceData = [_aircraft, _missionUC] call _fnc_findOrdnance;
_ordnanceData params ["_selectedMag", "_ammo", "_pIndex", "_isGun"];

if (_selectedMag isEqualTo "") exitWith {
    ["PrecisionStrike", 2, format["No suitable ordnance found for %1 mission on %2", _missionUC, typeOf _aircraft]] call FLO_fnc_log;
    false
};

private _bombCnt = getNumber (configFile >> "CfgMagazines" >> _selectedMag >> "count");
if (_bombCnt <= 0) then { _bombCnt = 1 };

["PrecisionStrike", 3, format["Selected ordnance: %1 (ammo: %2, count: %3, isGun: %4)", _selectedMag, _ammo, _bombCnt, _isGun]] call FLO_fnc_log;

// Get the group and clear any existing waypoints
private _grp = group _aircraft;
while {count waypoints _grp > 0} do {
    deleteWaypoint [_grp, 0];
};

// Determine if this is a helicopter or fixed-wing
private _isHeli = _aircraft isKindOf "Helicopter";

// Attack parameters
private _approachDist = if (_isHeli) then { 800 } else { 1500 };
private _attackAlt = if (_isHeli) then { _altitude max 80 } else { _altitude max 200 };
private _releaseRange = if (_isHeli) then { 400 } else { 600 };
private _maxPasses = 6;  // Limit total passes to prevent infinite loops

private _passCount = 0;
private _totalReleased = 0;
private _hasOrdnance = true;

// Multi-pass attack loop - continue while ordnance available
while {_hasOrdnance && alive _aircraft && _passCount < _maxPasses} do {
    _passCount = _passCount + 1;

    // Update activity timestamp each pass
    _aircraft setVariable ["FLO_lastActivityTime", time, true];

    // Re-check ordnance for this pass (may have expended previous pylon)
    private _passOrdnance = [_aircraft, _missionUC] call _fnc_findOrdnance;
    _passOrdnance params ["_passMag", "_passAmmo", "_passPIndex", "_passIsGun"];

    if (_passMag isEqualTo "") exitWith {
        _hasOrdnance = false;
        ["PrecisionStrike", 3, "No more ordnance available - ending attack"] call FLO_fnc_log;
    };

    private _passBombCnt = getNumber (configFile >> "CfgMagazines" >> _passMag >> "count");
    if (_passBombCnt <= 0) then { _passBombCnt = 1 };

    ["PrecisionStrike", 3, format["Pass %1: Using %2 (%3 rounds)", _passCount, _passMag, _passBombCnt]] call FLO_fnc_log;

    // Calculate attack geometry for this pass
    // Vary approach angle slightly each pass to avoid predictable pattern
    private _approachVariation = ((_passCount - 1) * 45) % 360;
    private _baseDir = _aircraft getDir _targetPos;
    private _approachDir = _baseDir + _approachVariation;

    private _ipPos = _targetPos getPos [_approachDist, _approachDir + 180];
    _ipPos set [2, _attackAlt];

    private _egressPos = _targetPos getPos [_approachDist, _approachDir];
    _egressPos set [2, _attackAlt + 100];

    ["PrecisionStrike", 3, format["Pass %1 geometry: IP bearing %2, distance %3m", _passCount, round _approachDir, _approachDist]] call FLO_fnc_log;

    // Phase 1: Fly to Initial Point
    _aircraft flyInHeight _attackAlt;
    _aircraft doMove _ipPos;
    _aircraft doWatch _targetPos;

    waitUntil {
        sleep 1;
        _aircraft setVariable ["FLO_lastActivityTime", time, true]; // Keep activity alive
        !alive _aircraft || (_aircraft distance2D _ipPos) < 300
    };

    if (!alive _aircraft) exitWith {};

    ["PrecisionStrike", 3, format["Pass %1: At IP - beginning attack run", _passCount]] call FLO_fnc_log;

    // Phase 2: Attack run toward target
    _aircraft doMove _egressPos;
    _aircraft doWatch _targetPos;

    if (_isHeli) then {
        (driver _aircraft) doTarget (nearestObject [_targetPos, "All"]);
        _aircraft flyInHeight (_attackAlt - 50);
    };

    waitUntil {
        sleep 0.5;
        !alive _aircraft || (_aircraft distance2D _targetPos) < _releaseRange
    };

    if (!alive _aircraft) exitWith {};

    ["PrecisionStrike", 3, format["Pass %1: In release range (%2m), weapons free", _passCount, round (_aircraft distance2D _targetPos)]] call FLO_fnc_log;

    // Calculate release timing
    private _speedMS = ((speed _aircraft) max 50) / 3.6;
    private _runLength = _releaseRange * 0.8;
    private _timeStep = (_runLength / _passBombCnt / _speedMS) max 0.15;

    // Release ordnance
    if (_missionUC == "LASER") then {
        // Laser-guided - single missile per pass
        private _target = objNull;
        private _candidates = vehicles + allUnits;
        private _near = _candidates select { side _x == west && alive _x && _x distance2D _targetPos < 50 };
        if (count _near > 0) then { _target = _near select 0 };

        private _laserTarget = if (!isNull _target) then {
            private _lt = "LaserTargetE" createVehicle [0,0,0];
            _lt attachTo [_target, [0,0,0]];
            _lt
        } else {
            "LaserTargetE" createVehicle _targetPos
        };

        private _missile = _passAmmo createVehicle (getPosASL _aircraft);
        _missile setMissileTarget _laserTarget;
        _missile setDir (getDir _aircraft);
        _missile setShotParents [_aircraft, driver _aircraft];
        _missile setVelocityModelSpace [0,60,0];
        if (_passPIndex > 0) then { _aircraft setPylonLoadOut [_passPIndex, "", true] };

        _totalReleased = _totalReleased + 1;
        ["PrecisionStrike", 3, format["Pass %1: Laser missile launched", _passCount]] call FLO_fnc_log;

        [_laserTarget, _missile] spawn {
            params ["_t", "_m"];
            waitUntil { sleep 0.5; isNull _m || !alive _m };
            deleteVehicle _t;
        };
    } else {
        // Unguided ordnance - release salvo
        private _released = 0;
        for "_i" from 1 to _passBombCnt do {
            if (!alive _aircraft) exitWith {};

            private _aircraftVel = velocity _aircraft;
            private _dirToTarget = _aircraft getDir _targetPos;
            private _distToTarget = _aircraft distance2D _targetPos;

            private _bombPos = (getPosASL _aircraft) vectorAdd [0, 0, -3];
            private _proj = _passAmmo createVehicle _bombPos;
            _proj setDir _dirToTarget;
            _proj setShotParents [_aircraft, driver _aircraft];

            if (_passIsGun) then {
                _proj setVelocity (_aircraftVel vectorAdd [
                    sin(_dirToTarget) * 400,
                    cos(_dirToTarget) * 400,
                    -20
                ]);
            } else {
                if (_missionUC == "CAS") then {
                    private _pitchDown = atan((_attackAlt - 10) / (_distToTarget max 100));
                    _proj setVelocity (_aircraftVel vectorAdd [
                        sin(_dirToTarget) * 150,
                        cos(_dirToTarget) * 150,
                        -30 - (tan(_pitchDown) * 50)
                    ]);
                } else {
                    _proj setVelocity (_aircraftVel vectorAdd [0, 0, -15]);
                };
            };

            _released = _released + 1;
            sleep _timeStep;
        };

        if (_passPIndex > 0 && !_passIsGun) then { _aircraft setPylonLoadOut [_passPIndex, "", true] };
        _totalReleased = _totalReleased + _released;
        ["PrecisionStrike", 3, format["Pass %1: Released %2 ordnance", _passCount, _released]] call FLO_fnc_log;
    };

    // Phase 3: Egress from this pass
    _aircraft flyInHeight (_attackAlt + 100);
    _aircraft doMove _egressPos;

    // Wait for egress before next pass
    waitUntil {
        sleep 1;
        _aircraft setVariable ["FLO_lastActivityTime", time, true];
        !alive _aircraft || (_aircraft distance2D _egressPos) < 400
    };

    // Check if more ordnance remains for another pass
    private _nextCheck = [_aircraft, _missionUC] call _fnc_findOrdnance;
    if ((_nextCheck select 0) isEqualTo "") then {
        _hasOrdnance = false;
    };

    // Brief pause between passes
    if (_hasOrdnance && alive _aircraft) then {
        ["PrecisionStrike", 3, format["Pass %1 complete - setting up for next pass", _passCount]] call FLO_fnc_log;
        sleep 2;
    };
};

// Final update before mission complete
_aircraft setVariable ["FLO_lastActivityTime", time, true];

private _exitReason = if (!alive _aircraft) then { "aircraft destroyed" } else {
    if (!_hasOrdnance) then { "ordnance expended" } else { "max passes reached" }
};

["PrecisionStrike", 3, format["Mission complete: %1 passes, %2 ordnance released, exit: %3", _passCount, _totalReleased, _exitReason]] call FLO_fnc_log;

// Return to base altitude and head away
if (alive _aircraft) then {
    _aircraft flyInHeight (_altitude + 200);
    private _rtbDir = _aircraft getDir _targetPos + 180;
    private _rtbPos = _aircraft getPos [2000, _rtbDir];
    _aircraft doMove _rtbPos;
};

true
