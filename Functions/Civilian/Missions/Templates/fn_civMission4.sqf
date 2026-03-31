/*
 * Function: FLO_fnc_civMission4
 * Description:
 *   Civilian Mission 4 - Create Roadblock/Checkpoint
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
[true, _taskId, [_offer get "briefing", _offer get "taskTitle", ""], _pos, "CREATED", 1, true, "defend", true] call BIS_fnc_taskCreate;
["STR_FLO_MISSIONCIV_CHECKPOINT", "info"] remoteExec ["FLO_fnc_sendNotification", 0];

[
    parseText "<t color='#1AA3FF' font='PuristaBold' align='right' shadow='1' size='2.5'>Mission: Create Roadblock</t><br /><t align='right' shadow='1' size='2'>- 1x Observation Post</t><br /><t align='right' shadow='1' size='2'>- 2x Sandbag Bunkers</t>",
    [0, 0.5, 1, 1],
    nil,
    5,
    1.7,
    0
] remoteExec ["BIS_fnc_textTiles", 0];

private _trigger = createTrigger ["EmptyDetector", _pos, false];
_trigger setTriggerArea [100, 100, 0, false, 100];
_trigger setTriggerInterval 5;
_trigger setTriggerActivation ["NONE", "PRESENT", false];
_trigger setTriggerStatements [
    "(count (nearestObjects [thisTrigger, ['Land_Cargo_House_V1_F', 'Land_Cargo_House_V3_F'], 100]) > 0) && (count (nearestObjects [thisTrigger, ['Land_BagBunker_Small_F'], 100]) > 1)",
    "['CHECKPOINT_COMPLETE', [thisTrigger]] call FLO_fnc_civilianMissionResolveAction;",
    ""
];
_trigger setVariable ["missionTaskId", _taskId];
_trigger setVariable ["targetPos", _pos];

createHashMapFromArray [
    ["taskId", _taskId],
    ["position", _pos]
]
