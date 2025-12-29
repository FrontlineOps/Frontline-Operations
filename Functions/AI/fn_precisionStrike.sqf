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
private _driver = driver _aircraft;

// Attack parameters - helicopters get closer, jets stay further
private _approachDist = if (_isHeli) then { 600 } else { 1500 };
private _attackAlt = if (_isHeli) then { _altitude max 100 } else { _altitude max 250 };
private _diveAlt = if (_isHeli) then { 40 } else { 150 };  // Altitude at release point
private _releaseRange = if (_isHeli) then { 300 } else { 600 };
private _attackSpeed = if (_isHeli) then { 45 } else { 120 };  // m/s
private _maxPasses = 6;

private _passCount = 0;
private _totalReleased = 0;
private _hasOrdnance = true;

// Helper function to find BLUFOR targets near position
private _fnc_findTargets = {
    params ["_pos", "_radius"];
    private _targets = [];

    // Find vehicles first (priority targets)
    private _vehicles = vehicles select {
        alive _x &&
        side _x == west &&
        _x distance2D _pos < _radius &&
        !(_x isKindOf "Air")
    };

    // Sort by threat (armor > cars > static)
    private _armor = _vehicles select { _x isKindOf "Tank" || _x isKindOf "APC" };
    private _cars = _vehicles select { _x isKindOf "Car" && !(_x in _armor) };
    private _static = _vehicles select { _x isKindOf "StaticWeapon" };

    // Add in priority order
    _targets append _armor;
    _targets append _cars;
    _targets append _static;

    // Add infantry if no vehicles
    if (count _targets == 0) then {
        private _infantry = allUnits select {
            alive _x && side _x == west && _x distance2D _pos < _radius
        };
        _targets append _infantry;
    };

    _targets
};

// Multi-pass attack loop
while {_hasOrdnance && alive _aircraft && _passCount < _maxPasses} do {
    _passCount = _passCount + 1;
    _aircraft setVariable ["FLO_lastActivityTime", time, true];

    // Re-check ordnance for this pass
    private _passOrdnance = [_aircraft, _missionUC] call _fnc_findOrdnance;
    _passOrdnance params ["_passMag", "_passAmmo", "_passPIndex", "_passIsGun"];

    if (_passMag isEqualTo "") exitWith {
        _hasOrdnance = false;
        ["PrecisionStrike", 3, "No more ordnance available - ending attack"] call FLO_fnc_log;
    };

    private _passBombCnt = getNumber (configFile >> "CfgMagazines" >> _passMag >> "count");
    if (_passBombCnt <= 0) then { _passBombCnt = 1 };

    // Find actual BLUFOR targets for this pass
    private _targets = [_targetPos, 100] call _fnc_findTargets;
    private _actualTarget = if (count _targets > 0) then {
        getPosATL (_targets select 0)
    } else {
        _targetPos
    };

    ["PrecisionStrike", 3, format["Pass %1: Using %2 (%3 rounds), %4 targets found", _passCount, _passMag, _passBombCnt, count _targets]] call FLO_fnc_log;

    // Calculate attack geometry
    private _approachVariation = ((_passCount - 1) * 60) % 360;
    private _baseDir = _aircraft getDir _actualTarget;
    private _approachDir = _baseDir + _approachVariation;

    private _ipPos = _actualTarget getPos [_approachDist, _approachDir + 180];
    _ipPos set [2, _attackAlt];

    private _egressPos = _actualTarget getPos [_approachDist * 1.5, _approachDir];
    _egressPos set [2, _attackAlt + 50];

    ["PrecisionStrike", 3, format["Pass %1: IP at bearing %2, target at %3", _passCount, round _approachDir, _actualTarget]] call FLO_fnc_log;

    // ========== PHASE 1: Fly to Initial Point (AI assisted) ==========
    _grp setBehaviour "CARELESS";
    _grp setCombatMode "BLUE";
    _aircraft flyInHeight _attackAlt;
    _aircraft doMove _ipPos;

    waitUntil {
        sleep 0.5;
        _aircraft setVariable ["FLO_lastActivityTime", time, true];
        !alive _aircraft || (_aircraft distance2D _ipPos) < 200
    };

    if (!alive _aircraft) exitWith {};

    // ========== PHASE 2: Attack Run (FULL MANUAL CONTROL) ==========
    ["PrecisionStrike", 3, format["Pass %1: At IP - initiating controlled attack run", _passCount]] call FLO_fnc_log;

    // Disable ALL AI behaviors during attack run
    _driver disableAI "AUTOTARGET";
    _driver disableAI "TARGET";
    _driver disableAI "SUPPRESSION";
    _driver disableAI "AUTOCOMBAT";
    _driver disableAI "COVER";
    _driver disableAI "FSM";
    _grp setBehaviour "CARELESS";
    _grp setCombatMode "BLUE";

    // Re-acquire target just before attack (may have moved)
    _targets = [_targetPos, 100] call _fnc_findTargets;
    if (count _targets > 0) then {
        _actualTarget = getPosATL (_targets select 0);
        ["PrecisionStrike", 3, format["Pass %1: Locked onto target at %2", _passCount, _actualTarget]] call FLO_fnc_log;
    };

    // Calculate dive parameters
    private _startPos = getPosASL _aircraft;
    private _distToTarget = _aircraft distance2D _actualTarget;
    private _altDiff = (_startPos select 2) - _diveAlt;
    private _diveAngle = atan(_altDiff / (_distToTarget max 1));
    private _dirToTarget = _aircraft getDir _actualTarget;

    ["PrecisionStrike", 3, format["Pass %1: Dive angle %2 deg, distance %3m", _passCount, round _diveAngle, round _distToTarget]] call FLO_fnc_log;

    // Attack run loop - force-fly toward target
    private _released = 0;
    private _releaseInterval = (_distToTarget / _attackSpeed / _passBombCnt) max 0.2;
    private _lastRelease = time;
    private _attackStartTime = time;
    private _maxAttackTime = 30; // Safety timeout

    while {alive _aircraft && (_aircraft distance2D _actualTarget) > 50 && (time - _attackStartTime) < _maxAttackTime} do {
        // Recalculate direction to target each frame
        private _currentPos = getPosASL _aircraft;
        private _currentDist = _aircraft distance2D _actualTarget;
        private _currentAlt = _currentPos select 2;

        // Calculate desired altitude (linear descent toward dive altitude)
        private _progress = 1 - ((_currentDist - 50) / (_distToTarget max 1));
        private _desiredAlt = _attackAlt - ((_attackAlt - _diveAlt) * (_progress min 1 max 0));

        // Calculate velocity vector toward target with dive
        _dirToTarget = _aircraft getDir _actualTarget;
        private _targetAltDiff = _currentAlt - _desiredAlt;
        private _verticalSpeed = -(_targetAltDiff min 20 max -5);  // Descend toward desired alt

        // Force velocity toward target
        private _velX = sin(_dirToTarget) * _attackSpeed;
        private _velY = cos(_dirToTarget) * _attackSpeed;
        private _velZ = if (_currentDist > 100) then { _verticalSpeed } else { -10 };  // Dive steeper close in

        _aircraft setVelocity [_velX, _velY, _velZ];

        // Force heading toward target
        _aircraft setDir _dirToTarget;

        // Set pitch for dive (vectorDirAndUp)
        private _pitch = -(_diveAngle * (_progress min 0.8));  // Nose down during dive
        private _dirVec = [sin(_dirToTarget) * cos(_pitch), cos(_dirToTarget) * cos(_pitch), sin(_pitch)];
        private _upVec = [0, 0, 1];  // Keep wings level
        _aircraft setVectorDirAndUp [_dirVec, _upVec];

        // Release ordnance at intervals when in range
        if (_currentDist < _releaseRange && (time - _lastRelease) >= _releaseInterval && _released < _passBombCnt) then {
            private _bombPos = _currentPos vectorAdd [0, 0, -2];
            private _proj = _passAmmo createVehicle _bombPos;
            _proj setShotParents [_aircraft, _driver];

            // Calculate velocity toward actual target position
            private _targetASL = ATLToASL _actualTarget;
            private _toTarget = _targetASL vectorDiff _currentPos;
            private _toTargetNorm = vectorNormalized _toTarget;

            // Handle LASER guided missiles specially
            if (_missionUC == "LASER") then {
                // Create laser designator on target
                private _laserTarget = "LaserTargetE" createVehicle _actualTarget;
                _proj setMissileTarget _laserTarget;
                _proj setDir _dirToTarget;
                _proj setVelocityModelSpace [0, 80, 0];  // Forward launch velocity

                // Clean up laser after missile impacts
                [_laserTarget, _proj] spawn {
                    params ["_lt", "_m"];
                    waitUntil { sleep 0.5; isNull _m || !alive _m };
                    deleteVehicle _lt;
                };
            } else {
                // Unguided ordnance - aim directly at target
                private _projSpeed = if (_passIsGun) then { 500 } else {
                    if (_missionUC == "CAS") then { 200 } else { 50 }
                };

                private _projVel = (velocity _aircraft) vectorAdd (_toTargetNorm vectorMultiply _projSpeed);
                _proj setVelocity _projVel;
                _proj setDir _dirToTarget;
            };

            _released = _released + 1;
            _lastRelease = time;
            _aircraft setVariable ["FLO_lastActivityTime", time, true];
        };

        sleep 0.05;  // ~20 Hz control loop
    };

    // Clear expended pylon
    if (_passPIndex > 0 && !_passIsGun && _released > 0) then {
        _aircraft setPylonLoadOut [_passPIndex, "", true];
    };
    _totalReleased = _totalReleased + _released;

    ["PrecisionStrike", 3, format["Pass %1: Released %2/%3 ordnance", _passCount, _released, _passBombCnt]] call FLO_fnc_log;

    // ========== PHASE 3: Egress (Restore AI, climb out) ==========
    // Re-enable AI
    _driver enableAI "AUTOTARGET";
    _driver enableAI "TARGET";
    _driver enableAI "SUPPRESSION";
    _driver enableAI "AUTOCOMBAT";
    _driver enableAI "COVER";
    _driver enableAI "FSM";
    _grp setBehaviour "AWARE";
    _grp setCombatMode "YELLOW";

    // Climb and egress
    _aircraft flyInHeight (_attackAlt + 50);
    _aircraft doMove _egressPos;

    // Force initial climb velocity
    private _climbVel = velocity _aircraft;
    _climbVel set [2, 15];  // Add upward velocity
    _aircraft setVelocity _climbVel;

    waitUntil {
        sleep 1;
        _aircraft setVariable ["FLO_lastActivityTime", time, true];
        !alive _aircraft || (_aircraft distance2D _egressPos) < 300
    };

    // Check remaining ordnance
    private _nextCheck = [_aircraft, _missionUC] call _fnc_findOrdnance;
    if ((_nextCheck select 0) isEqualTo "") then {
        _hasOrdnance = false;
    };

    if (_hasOrdnance && alive _aircraft) then {
        ["PrecisionStrike", 3, format["Pass %1 complete - setting up next pass", _passCount]] call FLO_fnc_log;
        sleep 1;
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
