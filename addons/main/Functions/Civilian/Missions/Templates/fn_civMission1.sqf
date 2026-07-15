/*
 * Function: FLO_fnc_civMission1
 * Description:
 *   Civilian Mission 1 - Repair Vehicle
 */

params [["_offer", createHashMap, [createHashMap]]];

private _result = createHashMap;
if (!isServer || {(keys _offer) isEqualTo []}) exitWith { _result };

private _objectiveId = _offer get "targetObjectiveId";
if !(_objectiveId in FLO_Objectives) exitWith { _result };

private _objective = FLO_Objectives get _objectiveId;
private _objectivePos = _objective get "position";
private _objectiveRadius = ((_objective get "radius") max 150) min 900;
private _caller = _offer get "caller";
private _roads = _objectivePos nearRoads _objectiveRadius;
_roads = _roads select { [getPosATL _x, _objective] call FLO_fnc_isPositionInObjective };
if (!isNull _caller) then {
    _roads = _roads select { (getPosATL _caller distance2D getPosATL _x) > 120 };
};
if (_roads isEqualTo []) exitWith { _result };

private _road = selectRandom _roads;
private _pos = getPosATL _road;
private _taskId = _offer get "missionId";
[true, _taskId, [_offer get "briefing", _offer get "taskTitle", ""], _pos, "CREATED", 1, true, "repair", true] call BIS_fnc_taskCreate;
["STR_FLO_MISSIONCIV_REPAIR", "info"] remoteExec ["FLO_fnc_sendNotification", 0];

private _civilianVehicles = (FLO_FactionCatalog get "CIVILIAN") get "vehicles";
private _vehicleType = if (_civilianVehicles isNotEqualTo []) then { selectRandom _civilianVehicles } else { "C_Offroad_01_F" };
private _vehicle = createVehicle [_vehicleType, _pos, [], 0, "NONE"];
_vehicle setDir (_road getDir ((roadsConnectedTo _road) param [0, _road]));
_vehicle setDamage 0.7;
_vehicle setVariable ["missionTaskId", _taskId, true];

_vehicle addEventHandler ["Killed", {
    params ["_unit"];
    ["REPAIR_FAILED", [_unit]] call FLO_fnc_civilianMissionResolveAction;
}];

[
    _vehicle,
    "Repair Civilian Vehicle",
    "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_connect_ca.paa",
    "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_connect_ca.paa",
    "_this distance _target < 7",
    "_caller distance _target < 7",
    {},
    {},
    {
        params ["_target", "_caller", "_actionId"];
        ["REPAIR_COMPLETE", [_target, _actionId]] remoteExecCall ["FLO_fnc_civilianMissionResolveAction", 2, false];
    },
    {},
    [],
    10,
    0,
    true,
    false
] remoteExec ["BIS_fnc_holdActionAdd", 0, _vehicle];

if ((FLO_ReputationHandle get "value") < 7) then {
    private _hostileForce = call FLO_fnc_civilianGetHostileForcePool;
    _hostileForce params ["_hostileSide", "_hostileUnits"];
    private _grp = createGroup [_hostileSide, true];
    private _spawnPos = [_pos, 100, 200, 3, 0, 20, 0] call BIS_fnc_findSafePos;

    for "_i" from 1 to 4 do {
        _grp createUnit [selectRandom _hostileUnits, _spawnPos, [], 0, "NONE"];
    };

    if !([_grp, _pos, 100] call FLO_fnc_taskPatrol) then {
        { deleteVehicle _x; } forEach units _grp;
        deleteGroup _grp;
    };
};

createHashMapFromArray [
    ["taskId", _taskId],
    ["position", _pos]
]
