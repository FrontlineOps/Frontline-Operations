/*
 * Function: FLO_fnc_civMission3
 * Description: Civilian Mission 3 - Clear Minefield
 *   Creates a minefield on a road near the player.
 *   Spawns a damaged vehicle as context.
 *   Waits for all mines to be cleared/defused/exploded.
 */

if (!isServer) exitWith {};

// Find Location
private _players = allPlayers select {alive _x};
if (count _players == 0) exitWith { ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager; };
private _centerPlayer = selectRandom _players;

private _nearRoads = (getPos _centerPlayer) nearRoads 800 select { _x distance2D _centerPlayer > 200 };
if (count _nearRoads == 0) exitWith { 
    ["CIV_MISSION", 2, "Mission 3 cancelled: No valid roads found"] call FLO_fnc_log;
    ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager; 
};

private _road = selectRandom _nearRoads;
private _pos = getPos _road;
private _taskId = format ["CivMission_Mine_%1", floor random 9999];
[true, _taskId, ["Clear the minefield near the road.", "Clear Minefield", ""], _pos, "CREATED", 1, true, "mine", true] call BIS_fnc_taskCreate;

// Notification
["STR_FLO_MISSIONCIV_TITLE", "STR_FLO_MISSIONCIV_MINE", "info"] remoteExec ["FLO_fnc_sendNotification", 0];

// Spawn Decor Vehicle
private _vehType = selectRandom CivVehArray;
if (isNil "CivVehArray") then { _vehType = "C_Offroad_01_F"; };
private _veh = createVehicle [_vehType, _pos, [], 4, "NONE"];
private _nextRoad = (roadsConnectedTo _road) param [0, _road];
_veh setDir (_road getDir _nextRoad);
_veh setDamage 0.7;

// Spawn Mines
private _mines = [];
for "_i" from 1 to 6 do {
    private _mineType = selectRandom ["APERSMine", "APERSBoundingMine"];
    private _minePos = [_pos, 2, 15, 0, 0, 0, 0] call BIS_fnc_findSafePos;
    private _mine = createMine [_mineType, _minePos, [], 0];
    _mines pushBack _mine;
};

// Create Server Trigger for Clearance
private _trg = createTrigger ["EmptyDetector", _pos, false];
_trg setTriggerArea [20, 20, 0, false, 20];
_trg setTriggerInterval 2;
_trg setTriggerActivation ["ANYPLAYER", "PRESENT", false];
_trg setTriggerActivation ["NONE", "PRESENT", false];
// Condition: No active mines in area
_trg setTriggerStatements [
    "count (allMines select {position _x inArea thisTrigger}) == 0",
    "[thisTrigger] call FLO_fnc_civMission3_OnComplete;",
    ""
];

// Attach data
_trg setVariable ["missionTaskId", _taskId];
_trg setVariable ["decorVehicle", _veh];

// Define completion function
FLO_fnc_civMission3_OnComplete = {
    params ["_trigger"];
    
    private _tId = _trigger getVariable ["missionTaskId", ""];
    
    if (_tId != "") then { [_tId, "SUCCEEDED", true] call BIS_fnc_taskSetState; };
    deleteVehicle _trigger;
    
    // Reward
    [0.35, 'increase'] call FLO_fnc_adjustReputation;
    ["ScoreAdded", ["Minefield Cleared", 0]] remoteExec ["BIS_fnc_showNotification", 0];
    
    ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager;
};
