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

if ((keys _firePlan) isEqualTo []) then {
    _firePlan = [_realGroup, _targetPos, _rounds, _accuracy] call FLO_fnc_gtnBuildArtilleryFirePlan;
};

private _vehiclePlans = [];
if ((keys _firePlan) isNotEqualTo []) then {
    _vehiclePlans = _firePlan get "vehiclePlans";
};

if (_vehiclePlans isEqualTo []) exitWith {
    ["GTN Artillery", 1, format["Artillery %1 - no valid vehicles found in group of %2 units", _gid, count units _realGroup]] call FLO_fnc_log;
    [_gdata] call FLO_fnc_virtualizationClearMissionLock;
    private _missionRecord = (_mgr get "missions") get _gid;
    (_mgr get "missions") deleteAt _gid;
    if (!isNil "_missionRecord") then {
        ["FLO_GTN_ArtilleryMissionStateChanged", [_missionRecord get "side", _missionRecord get "missionId", "COMPLETED"]] call CBA_fnc_localEvent;
    };
};

["GTN Artillery", 3, format["Artillery %1 - found %2 valid guns", _gid, count _vehiclePlans]] call FLO_fnc_log;

// === PHASE 2: Clear patrol and waypoints ===
if !([_gid, [], true, "GTN_ARTILLERY_FIRE"] call FLO_fnc_updateVirtualGroupWaypoints) then {
    throw format ["Artillery %1 route clear was rejected", _gid];
};

// Clear the FLO_patrolConfig variable from real group
_realGroup setVariable ["FLO_patrolConfig", nil, true];

// Clear existing waypoints
[_realGroup] call CBA_fnc_clearWaypoints;

// Stop movement
{ doStop _x; } forEach units _realGroup;

["GTN Artillery", 3, format["Artillery %1 - cleared patrol/waypoints", _gid]] call FLO_fnc_log;

["GTN Artillery", 3, format [
    "Artillery %1 - executing %2 planned rounds across %3 guns",
    _gid,
    _firePlan get "plannedRounds",
    count _vehiclePlans
]] call FLO_fnc_log;

// === PHASE 3: EXECUTE FIRE MISSIONS (PARALLEL) ===
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
        if (_targets isEqualTo []) exitWith {};

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

// === PHASE 4: Wait for completion ===
waitUntil {
    sleep 1;
    (_activeScripts findIf { !scriptDone _x }) isEqualTo -1
};

["GTN Artillery", 3, format["Artillery %1 fire mission complete (all units)", _gid]] call FLO_fnc_log;

// === PHASE 5: Cleanup ===
// Pass objNull as vehicle since we handled multiple. Cleanup will use leader for scoot origin.
_mgr call ["_cleanupMission", [_gid, objNull]];
