/*
 * Function: FLO_fnc_civilianProtest
 * Author: Frontline Operations Development Group
 * Description:
 *   Spawns hostile civilians near players in low-reputation areas.
 *   Civilians gather around players, play protest animations, and throw objects.
 *   Called periodically by the Civilian Manager when in hostile areas.
 *
 * Arguments:
 *   0: Player to protest near <OBJECT>
 *   1: Number of protesters <NUMBER> (default: 3-6)
 *
 * Returns: Array of spawned protesters
 */

params [["_targetPlayer", objNull], ["_count", floor (3 + random 4)]];

if (isNull _targetPlayer) exitWith { [] };
if (!isServer) exitWith { [] };

// Check if player is in a valid protest area (populated location)
private _playerPos = getPosATL _targetPlayer;
private _nearbyLocations = nearestLocations [_playerPos, ["NameCity", "NameCityCapital", "NameVillage"], 500];
if (count _nearbyLocations == 0) exitWith { [] };

// Find spawn positions out of player's line of sight
private _spawnPositions = [];
for "_i" from 0 to (_count - 1) do {
    private _angle = random 360;
    private _distance = 30 + random 40;  // 30-70m away
    private _testPos = _playerPos getPos [_distance, _angle];
    
    // Check if out of line of sight
    private _los = lineIntersects [
        AGLToASL (_playerPos vectorAdd [0, 0, 1.5]),
        AGLToASL (_testPos vectorAdd [0, 0, 1.5])
    ];
    
    if (_los) then {
        // Position is hidden - good spawn point
        _spawnPositions pushBack _testPos;
    } else {
        // Try behind buildings
        private _buildings = _testPos nearObjects ["House", 30];
        if (count _buildings > 0) then {
            private _bldg = _buildings select 0;
            private _behindPos = getPos _bldg getPos [15, _bldg getDir _playerPos + 180];
            _spawnPositions pushBack _behindPos;
        } else {
            // Fallback - spawn further away
            private _farPos = _playerPos getPos [80 + random 20, _angle];
            _spawnPositions pushBack _farPos;
        };
    };
};

// Limit to requested count
_spawnPositions = _spawnPositions select [0, _count min count _spawnPositions];

if (count _spawnPositions == 0) exitWith { [] };

// Create protester group
private _protestGroup = createGroup [civilian, true];
private _protesters = [];

// Protest animations - valid Arma 3 animations
private _protestAnims = [
    "Acts_Excited_Loop",              // Excited/agitated stance
    "Acts_listeningToRadio_Loop",     // Standing idle
    "Acts_CivilTalking_1",            // Talking/gesturing
    "Acts_CivilTalking_2",            // Talking/gesturing
    "Acts_Ambient_Aggressive",        // Waving arms
    "Acts_WalkingChecking"            // Moving around
];

// Throwable objects (rocks, bottles)
private _throwables = [
    "Land_Stone_sharp_F",
    "Land_Stone_small_F",
    "Land_BottlePlastic_V1_F",
    "Land_BottlePlastic_V2_F"
];

{
    private _spawnPos = _x;
    private _unitType = selectRandom CivMenArray;
    
    private _protester = _protestGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
    _protester setBehaviour "CARELESS";
    _protester setSpeedMode "NORMAL";
    
    // Mark as protester
    _protester setVariable ["FLO_isProtester", true, true];
    
    // Move toward player
    private _gatherPos = _playerPos getPos [10 + random 15, random 360];
    _protester doMove _gatherPos;
    
    // Once close, start protesting
    [_protester, _targetPlayer, _protestAnims, _throwables] spawn {
        params ["_protester", "_target", "_anims", "_throwables"];
        
        // Wait until close to target
        waitUntil { 
            sleep 1; 
            !alive _protester || isNull _target || 
            _protester distance2D _target < 20 
        };
        
        if (!alive _protester || isNull _target) exitWith {};
        
        // Start protesting
        _protester disableAI "PATH";
        _protester setDir (_protester getDir _target);
        
        // Play protest animation
        private _anim = selectRandom _anims;
        [_protester, _anim] remoteExec ["playMove", 0];
        
        // Occasionally throw objects
        private _throwChance = 0.3;  // 30% chance to throw
        
        while {alive _protester && alive _target && _protester distance2D _target < 50} do {
            sleep (3 + random 5);
            
            if (random 1 < _throwChance) then {
                // Create and throw object
                private _objType = selectRandom _throwables;
                private _proj = createVehicle [_objType, getPosATL _protester vectorAdd [0, 0, 1.5], [], 0, "CAN_COLLIDE"];
                
                // Calculate throw direction toward player
                private _throwDir = _protester getDir _target;
                private _throwVel = [
                    (sin _throwDir) * 10 + random 2,
                    (cos _throwDir) * 10 + random 2,
                    4 + random 3
                ];
                
                _proj setVelocity _throwVel;
                
                // Object cleanup after a few seconds
                [_proj] spawn {
                    params ["_obj"];
                    sleep 10;
                    if (!isNull _obj) then { deleteVehicle _obj };
                };
                
                // Play throwing animation
                [_protester, "Acts_Ambient_Aggressive"] remoteExec ["playMove", 0];
            } else {
                // Play random protest animation
                [_protester, selectRandom _anims] remoteExec ["playMove", 0];
            };
            
            // Face target
            _protester setDir (_protester getDir _target);
        };
    };
    
    _protesters pushBack _protester;
    
} forEach _spawnPositions;

// Cleanup after timeout
[_protesters] spawn {
    params ["_protesters"];
    
    sleep 180;  // 3 minutes
    
    {
        if (alive _x) then {
            _x enableAI "PATH";
            _x setBehaviour "CARELESS";
            private _fleeDir = random 360;
            private _fleePos = getPosATL _x getPos [100, _fleeDir];
            _x doMove _fleePos;
            
            // Delete after fleeing
            [_x] spawn {
                params ["_unit"];
                sleep 60;
                if (!isNull _unit) then { deleteVehicle _unit };
            };
        };
    } forEach _protesters;
};

["CIVILIAN", 2, format["Spawned %1 protesters near %2", count _protesters, name _targetPlayer]] call FLO_fnc_log;

_protesters
