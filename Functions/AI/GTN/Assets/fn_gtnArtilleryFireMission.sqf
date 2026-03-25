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
    6: Fire plan <HASHMAP>
    7: Artillery Manager reference <HASHMAP>

    Example:
    [_gid, _gdata, _realGroup, _targetPos, 6, 100, _firePlan, _mgr] spawn FLO_fnc_gtnArtilleryFireMission;
*/

params ["_gid", "_gdata", "_realGroup", "_targetPos", "_rounds", "_accuracy", ["_firePlan", createHashMap], "_mgr"];

if (count (keys _firePlan) == 0) then {
    _firePlan = [_realGroup, _targetPos, _rounds, _accuracy] call FLO_fnc_gtnBuildArtilleryFirePlan;
};

private _vehiclePlans = [];
if (count (keys _firePlan) > 0) then {
    _vehiclePlans = _firePlan get "vehiclePlans";
};

if (count _vehiclePlans == 0) exitWith {
    ["GTN Artillery", 1, format["Artillery %1 - no valid vehicles found in group of %2 units", _gid, count units _realGroup]] call FLO_fnc_log;
    [_gdata] call FLO_fnc_virtualizationClearMissionLock;
    (_mgr get "missions") deleteAt _gid;
};

["GTN Artillery", 3, format["Artillery %1 - found %2 valid guns", _gid, count _vehiclePlans]] call FLO_fnc_log;

// === PHASE 2: Clear patrol and waypoints ===
// Clear patrol config from groupData
_gdata set ["patrolConfig", []];
_gdata set ["autoPatrol", false];

// Clear the FLO_patrolConfig variable from real group
_realGroup setVariable ["FLO_patrolConfig", nil, true];

// Clear existing waypoints
[_realGroup] call CBA_fnc_clearWaypoints;

// Clear virtual waypoints
_gdata set ["waypoints", []];
_gdata set ["currentWaypointIndex", 0];

// Stop movement
{ doStop _x; } forEach units _realGroup;

["GTN Artillery", 3, format["Artillery %1 - cleared patrol/waypoints", _gid]] call FLO_fnc_log;

// === PHASE 3: Distribute Rounds ===
private _gunCount = count _vehiclePlans;
private _roundsPerGun = ceil (_rounds / _gunCount);
// Safety clamp - always at least 1 round if requested > 0
if (_rounds > 0 && _roundsPerGun < 1) then { _roundsPerGun = 1 };

["GTN Artillery", 3, format["Artillery %1 - distributing %2 total rounds: %3 rounds per gun (%4 guns)", 
    _gid, _rounds, _roundsPerGun, _gunCount]] call FLO_fnc_log;

// === PHASE 4: EXECUTE FIRE MISSIONS (PARALLEL) ===
private _activeScripts = [];

{
    private _script = [_x, _gid] spawn {
        params ["_vehiclePlan", "_gid"];
        private _veh = _vehiclePlan get "vehicle";
        private _ammo = _vehiclePlan get "ammo";
        private _salvo = _vehiclePlan get "salvo";
        private _targets = _vehiclePlan get "targets";
        
        // --- PREPARE ---
        private _setupTimeout = diag_tickTime + 30;
        waitUntil {
            sleep 1;
            (unitReady (gunner _veh)) || (diag_tickTime > _setupTimeout) || !alive _veh
        };
        
        if (!alive _veh) exitWith {};
        if ((count _targets) == 0) exitWith {};

        private _watchPos = _targets select 0;
        _veh doWatch _watchPos;
        sleep 2;
        
        // --- CHECK AMMO/RANGE ---
        if (_ammo isEqualTo "") exitWith {
            ["GTN Artillery", 2, format["Artillery %1 (Unit %2) - no ammo", _gid, _veh]] call FLO_fnc_log;
        };
        if !((_targets select 0) inRangeOfArtillery [[_veh], _ammo]) exitWith {
            ["GTN Artillery", 2, format["Artillery %1 (Unit %2) - target out of range", _gid, _veh]] call FLO_fnc_log;
        };
        
        // --- FIRE LOOP ---
        {
            if (!alive _veh) exitWith {};
            if (_x inRangeOfArtillery [[_veh], _ammo]) then {
                _veh commandArtilleryFire [_x, _ammo, _salvo];
                if (_salvo > 1) then { sleep 1.5; };
                
                private _waitStart = diag_tickTime;
                waitUntil {
                    sleep 0.5;
                    (unitReady _veh) || !alive _veh || (diag_tickTime - _waitStart > 60)
                };
            };
        } forEach _targets;
    };
    _activeScripts pushBack _script;
} forEach _vehiclePlans;

// === PHASE 5: Wait for completion ===
waitUntil {
    sleep 1;
    { !scriptDone _x } count _activeScripts == 0
};

["GTN Artillery", 3, format["Artillery %1 fire mission complete (all units)", _gid]] call FLO_fnc_log;

// === PHASE 6: Cleanup ===
// Pass objNull as vehicle since we handled multiple. Cleanup will use leader for scoot origin.
_mgr call ["_cleanupMission", [_gid, objNull]];
