/*
    Function: FLO_fnc_gtnArtilleryFireMission

    Description:
    Executes an artillery fire mission using a beaten zone pattern.
    Fires one round at a time with waitUntil unitReady for reliable completion.
    
    Pattern: Beaten zone cone spreading towards target
    - Offset increases with each round (walking fire towards target)
    - Random lateral dispersion within accuracy radius
    - MLRS fires salvos instead of single rounds
    - Heavier artillery (SPGs) fire more rounds, more accurately

    Arguments:
    0: Group ID <STRING>
    1: Group Data <HASHMAP>
    2: Real Group <GROUP>
    3: Target Position <ARRAY>
    4: Number of rounds <NUMBER>
    5: Accuracy/dispersion in meters <NUMBER>
    6: Artillery Manager reference <HASHMAP>

    Example:
    [_gid, _gdata, _realGroup, _targetPos, 6, 100, _mgr] spawn FLO_fnc_gtnArtilleryFireMission;
*/

params ["_gid", "_gdata", "_realGroup", "_targetPos", "_rounds", "_accuracy", "_mgr"];

// === PHASE 1: Find ALL artillery vehicles ===
private _vehicles = [];
{
    private _v = vehicle _x;
    ["GTN Artillery", 3, format["Checking unit %1, vehicle: %2 (Type: %3)", _x, _v, typeOf _v]] call FLO_fnc_log;

    if (_v != _x && {alive _v}) then {
        private _artyAmmo = getArtilleryAmmo [_v];
        if (count _artyAmmo > 0 || _v isKindOf "Artillery" || _v isKindOf "MLRS" || _v isKindOf "StaticMortar" || _v isKindOf "Tank_F") then { 
            if (count _artyAmmo > 0 || count (allTurrets _v) > 0) then {
              _vehicles pushBackUnique _v; 
            };
        };
    };
} forEach units _realGroup;

if (count _vehicles == 0) exitWith {
    ["GTN Artillery", 1, format["Artillery %1 - no valid vehicles found in group of %2 units", _gid, count units _realGroup]] call FLO_fnc_log;
    _gdata set ["onMission", false];
    (_mgr get "missions") deleteAt _gid;
};

["GTN Artillery", 3, format["Artillery %1 - found %2 valid guns", _gid, count _vehicles]] call FLO_fnc_log;

// === PHASE 2: Clear patrol and waypoints ===
// Clear patrol config from groupData
_gdata set ["patrolConfig", []];
_gdata set ["autoPatrol", false];

// Clear the FLO_patrolConfig variable from real group
_realGroup setVariable ["FLO_patrolConfig", nil, true];

// Clear existing waypoints
for "_i" from (count waypoints _realGroup - 1) to 0 step -1 do {
    deleteWaypoint [_realGroup, _i];
};

// Clear virtual waypoints
_gdata set ["waypoints", []];
_gdata set ["currentWaypointIndex", 0];

// Stop movement
{ doStop _x; } forEach units _realGroup;

["GTN Artillery", 3, format["Artillery %1 - cleared patrol/waypoints", _gid]] call FLO_fnc_log;

// === PHASE 3: Distribute Rounds ===
private _gunCount = count _vehicles;
private _roundsPerGun = ceil (_rounds / _gunCount);
// Safety clamp - always at least 1 round if requested > 0
if (_rounds > 0 && _roundsPerGun < 1) then { _roundsPerGun = 1 };

["GTN Artillery", 3, format["Artillery %1 - distributing %2 total rounds: %3 rounds per gun (%4 guns)", 
    _gid, _rounds, _roundsPerGun, _gunCount]] call FLO_fnc_log;

// === PHASE 4: EXECUTE FIRE MISSIONS (PARALLEL) ===
private _activeScripts = [];

{
    private _script = [_x, _targetPos, _roundsPerGun, _accuracy, _gid] spawn {
        params ["_veh", "_targetPos", "_rounds", "_accuracy", "_gid"];
        
        // --- PREPARE ---
        private _setupTimeout = diag_tickTime + 30;
        waitUntil {
            sleep 1;
            (unitReady (gunner _veh)) || (diag_tickTime > _setupTimeout) || !alive _veh
        };
        
        if (!alive _veh) exitWith {};
        
        _veh doWatch _targetPos;
        sleep 2;
        
        // --- CHECK AMMO/RANGE ---
        private _ammo = (getArtilleryAmmo [_veh]) param [0, ""];
        if (_ammo isEqualTo "") exitWith {
            ["GTN Artillery", 2, format["Artillery %1 (Unit %2) - no ammo", _gid, _veh]] call FLO_fnc_log;
        };
        
        if !(_targetPos inRangeOfArtillery [[_veh], _ammo]) exitWith {
            ["GTN Artillery", 2, format["Artillery %1 (Unit %2) - target out of range", _gid, _veh]] call FLO_fnc_log;
        };
        
        // --- CALC PARAMETERS ---
        private _direction = _veh getDir _targetPos;
        private _center = _targetPos getPos [_accuracy * 0.33, -_direction];
        private _offset = 0;
        private _salvo = 1;
        private _isMLRS = false;
        private _isMortar = _veh isKindOf "StaticMortar";

        if (_veh isKindOf "MLRS" || {getText (configOf _veh >> "simulation") == "airplanex"}) then {
            _isMLRS = true;
            private _gunnerAmmo = (gunner _veh) ammo (currentMuzzle (gunner _veh));
            if (_gunnerAmmo >= 6) then {
                _salvo = 3 + floor random 4; 
                _rounds = ceil (_rounds / _salvo);
            };
            _accuracy = _accuracy * 1.5;
        };
        
        // --- FIRE LOOP ---
        for "_i" from 1 to _rounds do {
            if (!alive _veh) exitWith {};
            
            _ammo = (getArtilleryAmmo [_veh]) param [0, ""];
            if (_ammo isEqualTo "") exitWith {};
            
            private _target = _center getPos [_offset + random _accuracy, _direction + 45 - random 90];
            _offset = _offset + (_accuracy * 0.33);
            
            if (_target inRangeOfArtillery [[_veh], _ammo]) then {
                _veh commandArtilleryFire [_target, _ammo, _salvo];
                if (_isMLRS) then { sleep 1.5; };
                
                private _waitStart = diag_tickTime;
                waitUntil {
                    sleep 0.5;
                    (unitReady _veh) || !alive _veh || (diag_tickTime - _waitStart > 60)
                };
            };
        };
    };
    _activeScripts pushBack _script;
} forEach _vehicles;

// === PHASE 5: Wait for completion ===
waitUntil {
    sleep 1;
    { !scriptDone _x } count _activeScripts == 0
};

["GTN Artillery", 3, format["Artillery %1 fire mission complete (all units)", _gid]] call FLO_fnc_log;

// === PHASE 6: Cleanup ===
// Pass objNull as vehicle since we handled multiple. Cleanup will use leader for scoot origin.
_mgr call ["_cleanupMission", [_gid, objNull]];

