/*
 * Function: FLO_fnc_civMission3
 * Description:
 *   Civilian Mission 3 - Clear Minefield
 */

params [["_offer", createHashMap, [createHashMap]]];

private _result = createHashMap;
if (!isServer || {(count (keys _offer)) == 0}) exitWith { _result };

private _objectiveId = _offer get "targetObjectiveId";
if !(_objectiveId in FLO_Objectives) exitWith { _result };

private _objective = FLO_Objectives get _objectiveId;
private _objectivePos = _objective get "position";
private _objectiveRadius = ((_objective get "radius") max 150) min 900;
private _roads = _objectivePos nearRoads _objectiveRadius;
_roads = _roads select { [getPosATL _x, _objective] call FLO_fnc_isPositionInObjective };
if ((count _roads) == 0) exitWith { _result };

private _road = selectRandom _roads;
private _pos = getPosATL _road;
private _taskId = _offer get "missionId";
[true, _taskId, [_offer get "briefing", _offer get "taskTitle", ""], _pos, "CREATED", 1, true, "mine", true] call BIS_fnc_taskCreate;
["STR_FLO_MISSIONCIV_MINE", "info"] remoteExec ["FLO_fnc_sendNotification", 0];

private _vehicleType = if (!isNil "CivVehArray" && {count CivVehArray > 0}) then { selectRandom CivVehArray } else { "C_Offroad_01_F" };
private _vehicle = createVehicle [_vehicleType, _pos, [], 4, "NONE"];
private _nextRoad = (roadsConnectedTo _road) param [0, _road];
_vehicle setDir (_road getDir _nextRoad);
_vehicle setDamage 0.7;

for "_i" from 1 to 6 do {
    private _mineType = selectRandom ["APERSMine", "APERSBoundingMine"];
    private _minePos = [_pos, 2, 15, 0, 0, 0, 0] call BIS_fnc_findSafePos;
    createMine [_mineType, _minePos, [], 0];
};

private _trigger = createTrigger ["EmptyDetector", _pos, false];
_trigger setTriggerArea [20, 20, 0, false, 20];
_trigger setTriggerInterval 2;
_trigger setTriggerActivation ["NONE", "PRESENT", false];
_trigger setTriggerStatements [
    "count (allMines select {position _x inArea thisTrigger}) == 0",
    "['MINEFIELD_COMPLETE', [thisTrigger]] call FLO_fnc_civilianMissionResolveAction;",
    ""
];
_trigger setVariable ["missionTaskId", _taskId];
_trigger setVariable ["decorVehicle", _vehicle];

createHashMapFromArray [
    ["taskId", _taskId],
    ["position", _pos]
]
