/*
 * Function: FLO_fnc_civMission4
 * Description: Civilian Mission 4 - Create Roadblock/Checkpoint
 *   Tasks player to build a checkpoint at a specific location.
 *   Requires: 1x Observation Post (Cargo House) + 2x Sandbag Bunkers.
 */

if (!isServer) exitWith {};

// Find Location
private _players = allPlayers select {alive _x};
if (count _players == 0) exitWith { ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager; };
private _centerPlayer = selectRandom _players;

private _nearRoads = (getPos _centerPlayer) nearRoads 800 select { _x distance2D _centerPlayer > 100 };
if (count _nearRoads == 0) exitWith { 
    ["CIV_MISSION", 2, "Mission 4 cancelled: No valid roads found"] call FLO_fnc_log;
    ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager; 
};

private _road = selectRandom _nearRoads;
private _pos = getPos _road;
private _taskId = format ["CivMission_Check_%1", floor random 9999];
[true, _taskId, ["Build a checkpoint including 1x Observation Post and 2x Sandbag Bunkers.", "Create Checkpoint", ""], _pos, "CREATED", 1, true, "defend", true] call BIS_fnc_taskCreate;

// Notification skipping custom
["STR_FLO_MISSIONCIV_CHECKPOINT", "info"] remoteExec ["FLO_fnc_sendNotification", 0];

// Display requirements
[
    parseText "<t color='#1AA3FF' font='PuristaBold' align='right' shadow='1' size='2.5'>Mission: Create Roadblock</t><br /><t align='right' shadow='1' size='2'>- 1x Observation Post</t><br /><t align='right' shadow='1' size='2'>- 2x Sandbag Bunkers</t>",
    [0, 0.5, 1, 1],
    nil,
    5,
    1.7,
    0
] remoteExec ["BIS_fnc_textTiles", 0];

// Create Server Trigger for Construction Logic
private _trg = createTrigger ["EmptyDetector", _pos, false];
_trg setTriggerArea [100, 100, 0, false, 100];
_trg setTriggerInterval 5;
_trg setTriggerActivation ["ANYPLAYER", "PRESENT", false]; 
_trg setTriggerActivation ["NONE", "PRESENT", false];
_trg setTriggerStatements [
    "(count (nearestObjects [thisTrigger, ['Land_Cargo_House_V1_F', 'Land_Cargo_House_V3_F'], 100]) > 0) && (count (nearestObjects [thisTrigger, ['Land_BagBunker_Small_F'], 100]) > 1)",
    "[thisTrigger] call FLO_fnc_civMission4_OnComplete;",
    ""
];

// Attach data
_trg setVariable ["missionTaskId", _taskId];
_trg setVariable ["targetPos", _pos];

// Define completion function
FLO_fnc_civMission4_OnComplete = {
    params ["_trigger"];
    
    private _tId = _trigger getVariable ["missionTaskId", ""];
    private _pos = _trigger getVariable ["targetPos", getPos _trigger];
    
    if (_tId != "") then { [_tId, "SUCCEEDED", true] call BIS_fnc_taskSetState; };
    deleteVehicle _trigger;
    
    // Reward
    [0.35, 'increase'] call FLO_fnc_adjustReputation;
    ["ScoreAdded", ["Checkpoint Established", 0]] remoteExec ["BIS_fnc_showNotification", 0];
    private _repScore = FLO_ReputationHandle getOrDefault ["value", 0];
    if (_repScore < 7) then {
        for "_i" from 1 to 2 do {
            private _spawnPos = [_pos, 300, 400, 3, 0, 20, 0] call BIS_fnc_findSafePos;
            private _grp = createGroup [east, true];
            
            for "_j" from 1 to 4 do {
                private _unitType = if (!isNil "GuerMenArray") then { selectRandom GuerMenArray } else { "O_G_Soldier_F" };
                _grp createUnit [_unitType, _spawnPos, [], 0, "NONE"];
            };
            
            // Attack move
            _grp addWaypoint [_pos, 0] setWaypointType "SAD";
            { _x setUnitPos "MIDDLE"; } forEach units _grp;
        };
        ["CIV_MISSION", 3, "Checkpoint mission triggered counter-attack"] call FLO_fnc_log;
    };
    
    ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager;
};
