/*
 * Function: FLO_fnc_civMission1
 * Description: Civilian Mission 1 - Repair Vehicle
 *   Finds a damaged civilian vehicle to repair.
 *   Spawns vehicle, creates marker (globally), adds repair action.
 */

if (!isServer) exitWith {};

// Find Location
private _players = allPlayers select {alive _x};
if (count _players == 0) exitWith { ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager; };
private _centerPlayer = selectRandom _players;

private _nearRoads = (getPos _centerPlayer) nearRoads 800 select { _x distance2D _centerPlayer > 200 };
if (count _nearRoads == 0) exitWith { 
    ["CIV_MISSION", 2, "Mission 1 cancelled: No valid roads found"] call FLO_fnc_log;
    ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager; 
};

private _road = selectRandom _nearRoads;
private _pos = getPos _road;
private _taskId = format ["CivMission_Repair_%1", floor random 9999];
[true, _taskId, ["Find and repair the civilian vehicle.", "Repair Vehicle", ""], _pos, "CREATED", 1, true, "repair", true] call BIS_fnc_taskCreate;

// Notification
["STR_FLO_MISSIONCIV_TITLE", "STR_FLO_MISSIONCIV_REPAIR", "info"] remoteExec ["FLO_fnc_sendNotification", 0];

private _vehType = selectRandom CivVehArray;
if (isNil "CivVehArray") then { _vehType = "C_Offroad_01_F"; };

private _veh = createVehicle [_vehType, _pos, [], 0, "NONE"];
_veh setDir (_road getDir ((roadsConnectedTo _road) param [0, _road]));
_veh setDamage 0.7;

// Handle Failure (Vehicle Destroyed)
_veh addEventHandler ["Killed", {
    params ["_unit"];
    private _tId = _unit getVariable ["missionTaskId", ""];
    
    if (_tId != "") then { [_tId, "FAILED", true] call BIS_fnc_taskSetState; };
    
    [-0.35, 'decrease'] call FLO_fnc_adjustReputation;
    
    // Fail -> Next mission
    ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager;
}];

// Store task ID on vehicle for updates
_veh setVariable ["missionTaskId", _taskId, true];

// Add Repair Action
[
    _veh,
    "Repair Civilian Vehicle",
    "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_connect_ca.paa",
    "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_connect_ca.paa",
    "_this distance _target < 7",
    "_caller distance _target < 7",
    {},
    {},
    {
        params ["_target", "_caller", "_actionId", "_arguments"];        
        // Repair
        _target setDamage 0;
        [_target] remoteExec ["FLO_fnc_civMission1_OnComplete", 2];
    },
    {},
    [],
    10,
    0,
    true,
    false
] remoteExec ["BIS_fnc_holdActionAdd", 0, _veh];

// Spawn Ambush (if Low Rep)
private _repScore = FLO_ReputationHandle getOrDefault ["value", 0];
if (_repScore < 7) then {
    private _grp = createGroup [east, true];
    private _spawnPos = [_pos, 100, 200, 3, 0, 20, 0] call BIS_fnc_findSafePos;
    
    for "_i" from 1 to 4 do {
        private _unitType = if (!isNil "GuerMenArray") then { selectRandom GuerMenArray } else { "O_G_Soldier_F" };
        _grp createUnit [_unitType, _spawnPos, [], 0, "NONE"];
    };
    
    [_grp, _pos, 100] call FLO_fnc_taskPatrol;
};

// Define completion function locally for the server to call
FLO_fnc_civMission1_OnComplete = {
    params ["_vehicle"];
    
    // Complete Task
    private _tId = _vehicle getVariable ["missionTaskId", ""];
    if (_tId != "") then { [_tId, "SUCCEEDED", true] call BIS_fnc_taskSetState; };
    
    // Reward
    [0.35, 'increase'] call FLO_fnc_adjustReputation;
    ["ScoreAdded", ["Vehicle Repaired", 0]] remoteExec ["BIS_fnc_showNotification", 0];
    
    // Remove Action
    [_vehicle, 0] remoteExec ["bis_fnc_holdActionRemove", 0];
    
    // Complete Mission Loop
    ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager;
};
