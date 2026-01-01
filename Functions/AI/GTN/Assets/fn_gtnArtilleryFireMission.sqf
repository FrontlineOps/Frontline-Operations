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

// === PHASE 1: Find artillery vehicle ===
private _veh = objNull;
{
    if (vehicle _x != _x) then {
        private _v = vehicle _x;
        if (_v isKindOf "Artillery" || _v isKindOf "MLRS" || _v isKindOf "StaticMortar") then { 
            _veh = _v; 
        };
        if (isNull _veh) then { _veh = _v; };
    };
} forEach units _realGroup;
if (isNull _veh) then { _veh = vehicle (leader _realGroup); };

if (isNull _veh || !alive _veh) exitWith {
    ["GTN Artillery", 1, format["Artillery %1 - no valid vehicle found", _gid]] call FLO_fnc_log;
    _gdata set ["onMission", false];
    (_mgr get "missions") deleteAt _gid;
};

["GTN Artillery", 3, format["Artillery %1 - vehicle: %2", _gid, typeOf _veh]] call FLO_fnc_log;

// === PHASE 2: Clear patrol and waypoints - artillery is now on fire mission ===
// Clear patrol config from groupData
_gdata set ["patrolConfig", []];
_gdata set ["autoPatrol", false];

// Clear the FLO_patrolConfig variable from real group (stops taskPatrol loop)
_realGroup setVariable ["FLO_patrolConfig", nil, true];

// Clear existing waypoints from real group (delete in reverse to avoid CYCLE bug)
for "_i" from (count waypoints _realGroup - 1) to 0 step -1 do {
    deleteWaypoint [_realGroup, _i];
};

// Clear virtual waypoints
_gdata set ["waypoints", []];
_gdata set ["currentWaypointIndex", 0];

// Stop movement
{ doStop _x; } forEach units _realGroup;

["GTN Artillery", 3, format["Artillery %1 - cleared patrol/waypoints for fire mission", _gid]] call FLO_fnc_log;

// === PHASE 3: Wait for crew to be ready ===
private _setupTimeout = diag_tickTime + 30;
waitUntil {
    sleep 1;
    (unitReady (gunner _veh)) || (diag_tickTime > _setupTimeout) || !alive _veh
};

if (!alive _veh) exitWith {
    _gdata set ["onMission", false];
    (_mgr get "missions") deleteAt _gid;
};

// === PHASE 4: Prepare and aim ===
// Just doWatch and let commandArtilleryFire handle the rest
// Do NOT set combat mode to BLUE - that prevents firing!
_veh doWatch _targetPos;
sleep 2;  // Brief pause to let gun orient

// === PHASE 5: Get ammo and check range ===
private _ammo = (getArtilleryAmmo [_veh]) param [0, ""];
if (_ammo isEqualTo "") exitWith {
    ["GTN Artillery", 1, format["Artillery %1 - no artillery ammo found", _gid]] call FLO_fnc_log;
    _mgr call ["_cleanupMission", [_gid, _veh]];
};

if !(_targetPos inRangeOfArtillery [[_veh], _ammo]) exitWith {
    ["GTN Artillery", 2, format["Artillery %1 - target out of range", _gid]] call FLO_fnc_log;
    _mgr call ["_cleanupMission", [_gid, _veh]];
};

// === PHASE 6: Calculate firing parameters ===
private _direction = _veh getDir _targetPos;
private _center = _targetPos getPos [_accuracy * 0.33, -_direction];  // Start point of beaten zone
private _offset = 0;
private _salvo = 1;
private _isMLRS = false;
private _isMortar = _veh isKindOf "StaticMortar";

// Detect MLRS - fires salvos
if (_veh isKindOf "MLRS" || {getText (configOf _veh >> "simulation") == "airplanex"}) then {
    _isMLRS = true;
    private _gunnerAmmo = (gunner _veh) ammo (currentMuzzle (gunner _veh));
    
    // MLRS fires in salvos of 3-6 rockets
    if (_gunnerAmmo >= 6) then {
        _salvo = 3 + floor random 4;  // 3-6 rockets per salvo
        _rounds = ceil (_rounds / _salvo);
    };
    _accuracy = _accuracy * 1.5;  // MLRS is less accurate
    
    ["GTN Artillery", 3, format["Artillery %1 - MLRS mode, %2 salvos of %3", _gid, _rounds, _salvo]] call FLO_fnc_log;
};

// Heavier artillery (SPGs, not mortars) fires more rounds, more accurately
if (!_isMortar && !_isMLRS) then {
    _rounds = _rounds * 2;
    _accuracy = _accuracy * 0.5;
};

["GTN Artillery", 3, format["Artillery %1 - firing %2 rounds (salvo %3) at %4m accuracy", 
    _gid, _rounds, _salvo, round _accuracy]] call FLO_fnc_log;

// === PHASE 7: Fire mission - round by round ===
private _roundsFired = 0;

for "_i" from 1 to _rounds do {
    if (!alive _veh) exitWith {};
    
    // Refresh ammo type each round (in case it changes)
    _ammo = (getArtilleryAmmo [_veh]) param [0, ""];
    if (_ammo isEqualTo "") exitWith {
        ["GTN Artillery", 2, format["Artillery %1 - out of ammo after %2 rounds", _gid, _roundsFired]] call FLO_fnc_log;
    };
    
    // Calculate target point in beaten zone cone
    // Offset increases with each round (walking fire towards target)
    private _target = _center getPos [_offset + random _accuracy, _direction + 45 - random 90];
    _offset = _offset + (_accuracy * 0.33);
    
    // Check if this specific target is in range
    if (_target inRangeOfArtillery [[_veh], _ammo]) then {
        // Fire!
        _veh commandArtilleryFire [_target, _ammo, _salvo];
        _roundsFired = _roundsFired + _salvo;
        
        // MLRS needs a small delay between salvos
        if (_isMLRS) then { sleep 1.5; };
        
        // Wait for gun to be ready for next round
        private _waitStart = diag_tickTime;
        waitUntil {
            sleep 0.5;
            (unitReady _veh) || !alive _veh || (diag_tickTime - _waitStart > 60)
        };
    } else {
        ["GTN Artillery", 2, format["Artillery %1 - target point out of range, skipping", _gid]] call FLO_fnc_log;
    };
};

["GTN Artillery", 3, format["Artillery %1 fire mission complete - %2 rounds fired", _gid, _roundsFired]] call FLO_fnc_log;

// === PHASE 8: Cleanup and shoot-and-scoot ===
_mgr call ["_cleanupMission", [_gid, _veh]];

