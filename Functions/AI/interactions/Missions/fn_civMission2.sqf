/*
 * Function: FLO_fnc_civMission2
 * Description: Civilian Mission 2 - Deliver Resources
 *   Spawns a supply crate near a player.
 *   Designates a delivery location (random building).
 *   Creates global marker and server-side trigger for detection.
 */

if (!isServer) exitWith {};

// Find Start & End Locations
private _players = allPlayers select {alive _x};
if (count _players == 0) exitWith { ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager; };
private _centerPlayer = selectRandom _players;

// Delivery Building (within 5km)
private _deliveryBuildings = nearestTerrainObjects [_centerPlayer, ["HOUSE", "CHURCH", "CHAPEL"], 5000];
if (count _deliveryBuildings == 0) exitWith { 
    ["CIV_MISSION", 2, "Mission 2 cancelled: No delivery buildings found"] call FLO_fnc_log;
    ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager; 
};
private _deliveryLocation = selectRandom _deliveryBuildings;
private _deliveryPos = getPos _deliveryLocation;

// Create Supply Crate
private _startPos = [getPos _centerPlayer, 5, 20, 2, 0, 0.5, 0] call BIS_fnc_findSafePos;
private _supplyBox = createVehicle ["IG_supplyCrate_F", _startPos, [], 0, "NONE"];
_supplyBox allowDamage false;
private _taskId = format ["CivMission_Deliver_%1", floor random 9999];
[true, _taskId, ["Deliver the supplies to the designated location.", "Deliver Resources", ""], _deliveryPos, "CREATED", 1, true, "container", true] call BIS_fnc_taskCreate;

// Notification skipping custom
["STR_FLO_MISSIONCIV_TITLE", "STR_FLO_MISSIONCIV_DELIVER", "info"] remoteExec ["FLO_fnc_sendNotification", 0];

// Spawn Ambush (if Low Rep) - At delivery location
private _repScore = FLO_ReputationHandle getOrDefault ["value", 0];
if (_repScore < 7) then {
    private _grp1 = createGroup [east, true];
    private _ambushPos = [_deliveryPos, 50, 150, 3, 0, 20, 0] call BIS_fnc_findSafePos;
    for "_i" from 1 to 4 do {
        private _unitType = if (!isNil "GuerMenArray") then { selectRandom GuerMenArray } else { "O_G_Soldier_F" };
        _grp1 createUnit [_unitType, _ambushPos, [], 0, "NONE"];
    };
    [_grp1, _deliveryPos, 200] call FLO_fnc_taskPatrol;
    
    private _grp2 = createGroup [east, true];
    private _ambushPos2 = [_deliveryPos, 50, 150, 3, 0, 20, 0] call BIS_fnc_findSafePos;
    for "_i" from 1 to 4 do {
        private _unitType = if (!isNil "GuerMenArray") then { selectRandom GuerMenArray } else { "O_G_Soldier_F" };
        _grp2 createUnit [_unitType, _ambushPos2, [], 0, "NONE"];
    };
    [_grp2, _deliveryPos, 100] call FLO_fnc_taskPatrol;
};

// Create Server Trigger for Delivery Logic
private _trg = createTrigger ["EmptyDetector", _deliveryPos, false];
_trg setTriggerArea [20, 20, 0, false, 20];
_trg setTriggerInterval 2;
_trg setTriggerActivation ["NONE", "PRESENT", false];
// Condition: Check if specific box is in area
_trg setVariable ["FLO_DeliveryBox", _supplyBox];
_trg setTriggerStatements [
    "(thisTrigger getVariable ['FLO_DeliveryBox', objNull]) inArea thisTrigger",
    "[thisTrigger] call FLO_fnc_civMission2_OnComplete;",
    ""
];

// Attach data to trigger for cleanup
_trg setVariable ["missionTaskId", _taskId];
_trg setVariable ["supplyBox", _supplyBox];

// Define completion function
FLO_fnc_civMission2_OnComplete = {
    params ["_trigger"];
    
    private _tId = _trigger getVariable ["missionTaskId", ""];
    private _box = _trigger getVariable ["supplyBox", objNull];
    
    // Complete Task
    if (_tId != "") then { [_tId, "SUCCEEDED", true] call BIS_fnc_taskSetState; };
    
    // Cleanup
    if (!isNull _box) then { deleteVehicle _box; };
    deleteVehicle _trigger;
    
    // Reward
    [0.35, 'increase'] call FLO_fnc_adjustReputation;
    ["ScoreAdded", ["Resources Delivered", 0]] remoteExec ["BIS_fnc_showNotification", 0];
    
    // Complete
    ["MISSION_COMPLETE", []] call FLO_fnc_civilianMissionManager;
};
