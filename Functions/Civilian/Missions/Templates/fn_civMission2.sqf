/*
 * Function: FLO_fnc_civMission2
 * Description:
 *   Civilian Mission 2 - Deliver Resources
 */

params [["_offer", createHashMap, [createHashMap]]];

private _result = createHashMap;
if (!isServer || {(count (keys _offer)) == 0}) exitWith { _result };

private _objectiveId = _offer get "targetObjectiveId";
if !(_objectiveId in FLO_Objectives) exitWith { _result };

private _objective = FLO_Objectives get _objectiveId;
private _objectivePos = _objective get "position";
private _objectiveRadius = ((_objective get "radius") max 150) min 1200;
private _deliveryBuildings = nearestTerrainObjects [_objectivePos, ["HOUSE", "CHURCH", "CHAPEL"], _objectiveRadius];
if ((count _deliveryBuildings) == 0) exitWith { _result };

private _deliveryLocation = selectRandom _deliveryBuildings;
private _deliveryPos = getPosATL _deliveryLocation;
private _caller = _offer get "caller";
private _startAnchor = if (!isNull _caller) then { getPosATL _caller } else { _objectivePos };
private _startPos = [_startAnchor, 5, 20, 2, 0, 0.5, 0] call BIS_fnc_findSafePos;
private _supplyBox = createVehicle ["IG_supplyCrate_F", _startPos, [], 0, "NONE"];
_supplyBox allowDamage false;

private _taskId = _offer get "missionId";
[true, _taskId, [_offer get "briefing", _offer get "taskTitle", ""], _deliveryPos, "CREATED", 1, true, "container", true] call BIS_fnc_taskCreate;
["STR_FLO_MISSIONCIV_DELIVER", "info"] remoteExec ["FLO_fnc_sendNotification", 0];

if ((FLO_ReputationHandle get "value") < 7) then {
    private _grp1 = createGroup [east, true];
    private _ambushPos = [_deliveryPos, 50, 150, 3, 0, 20, 0] call BIS_fnc_findSafePos;
    for "_i" from 1 to 4 do {
        private _unitType = if (!isNil "GuerMenArray" && {count GuerMenArray > 0}) then { selectRandom GuerMenArray } else { "O_G_Soldier_F" };
        _grp1 createUnit [_unitType, _ambushPos, [], 0, "NONE"];
    };
    [_grp1, _deliveryPos, 200] call FLO_fnc_taskPatrol;

    private _grp2 = createGroup [east, true];
    private _ambushPos2 = [_deliveryPos, 50, 150, 3, 0, 20, 0] call BIS_fnc_findSafePos;
    for "_i" from 1 to 4 do {
        private _unitType = if (!isNil "GuerMenArray" && {count GuerMenArray > 0}) then { selectRandom GuerMenArray } else { "O_G_Soldier_F" };
        _grp2 createUnit [_unitType, _ambushPos2, [], 0, "NONE"];
    };
    [_grp2, _deliveryPos, 100] call FLO_fnc_taskPatrol;
};

private _trigger = createTrigger ["EmptyDetector", _deliveryPos, false];
_trigger setTriggerArea [20, 20, 0, false, 20];
_trigger setTriggerInterval 2;
_trigger setTriggerActivation ["NONE", "PRESENT", false];
_trigger setVariable ["FLO_DeliveryBox", _supplyBox];
_trigger setTriggerStatements [
    "(thisTrigger getVariable ['FLO_DeliveryBox', objNull]) inArea thisTrigger",
    "['DELIVERY_COMPLETE', [thisTrigger]] call FLO_fnc_civilianMissionResolveAction;",
    ""
];
_trigger setVariable ["missionTaskId", _taskId];
_trigger setVariable ["supplyBox", _supplyBox];

createHashMapFromArray [
    ["taskId", _taskId],
    ["position", _deliveryPos]
]
