/*
 * Function: FLO_fnc_civilianMissionResolveAction
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves civilian mission world interactions on the server and clears the
 *   active civilian mission state through the mission manager.
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Arguments <ARRAY>
 *
 * Return Value:
 * BOOL - True when the action resolved
 */

params [
    ["_mode", "", [""]],
    ["_args", [], [[]]]
];

if (!isServer) exitWith {
    [_mode, _args] remoteExecCall ["FLO_fnc_civilianMissionResolveAction", 2, false];
    false
};

switch (toUpper _mode) do {
    case "REPAIR_COMPLETE": {
        _args params [["_vehicle", objNull, [objNull]], ["_actionId", -1, [0]]];
        if (isNull _vehicle) exitWith { false };

        _vehicle setDamage 0;
        if (_actionId >= 0) then {
            [_vehicle, _actionId] remoteExec ["BIS_fnc_holdActionRemove", 0, _vehicle];
        };

        private _taskId = _vehicle getVariable ["missionTaskId", ""];
        if (_taskId != "") then {
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
        };

        [0.35, "increase"] call FLO_fnc_adjustReputation;
        ["ScoreAdded", ["Vehicle Repaired", 0]] remoteExec ["BIS_fnc_showNotification", 0];
        ["MISSION_COMPLETE", [true, "repair_vehicle"]] call FLO_fnc_civilianMissionManager;
        true
    };

    case "REPAIR_FAILED": {
        _args params [["_vehicle", objNull, [objNull]]];
        if (isNull _vehicle) exitWith { false };

        private _taskId = _vehicle getVariable ["missionTaskId", ""];
        if (_taskId != "") then {
            [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
        };

        [-0.35, "decrease"] call FLO_fnc_adjustReputation;
        ["MISSION_FAILED", ["repair_vehicle"]] call FLO_fnc_civilianMissionManager;
        true
    };

    case "DELIVERY_COMPLETE": {
        _args params [["_trigger", objNull, [objNull]]];
        if (isNull _trigger) exitWith { false };

        private _taskId = _trigger getVariable ["missionTaskId", ""];
        private _box = _trigger getVariable ["supplyBox", objNull];
        if (_taskId != "") then {
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
        };
        if (!isNull _box) then {
            deleteVehicle _box;
        };
        deleteVehicle _trigger;

        [0.35, "increase"] call FLO_fnc_adjustReputation;
        ["ScoreAdded", ["Resources Delivered", 0]] remoteExec ["BIS_fnc_showNotification", 0];
        ["MISSION_COMPLETE", [true, "deliver_supplies"]] call FLO_fnc_civilianMissionManager;
        true
    };

    case "MINEFIELD_COMPLETE": {
        _args params [["_trigger", objNull, [objNull]]];
        if (isNull _trigger) exitWith { false };

        private _taskId = _trigger getVariable ["missionTaskId", ""];
        private _decorVehicle = _trigger getVariable ["decorVehicle", objNull];
        if (_taskId != "") then {
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
        };
        if (!isNull _decorVehicle) then {
            deleteVehicle _decorVehicle;
        };
        deleteVehicle _trigger;

        [0.35, "increase"] call FLO_fnc_adjustReputation;
        ["ScoreAdded", ["Minefield Cleared", 0]] remoteExec ["BIS_fnc_showNotification", 0];
        ["MISSION_COMPLETE", [true, "clear_minefield"]] call FLO_fnc_civilianMissionManager;
        true
    };

    case "CHECKPOINT_COMPLETE": {
        _args params [["_trigger", objNull, [objNull]]];
        if (isNull _trigger) exitWith { false };

        private _taskId = _trigger getVariable ["missionTaskId", ""];
        private _pos = _trigger getVariable ["targetPos", getPosATL _trigger];
        if (_taskId != "") then {
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
        };
        deleteVehicle _trigger;

        [0.35, "increase"] call FLO_fnc_adjustReputation;
        ["ScoreAdded", ["Checkpoint Established", 0]] remoteExec ["BIS_fnc_showNotification", 0];

        if ((FLO_ReputationHandle get "value") < 7) then {
            for "_i" from 1 to 2 do {
                private _spawnPos = [_pos, 300, 400, 3, 0, 20, 0] call BIS_fnc_findSafePos;
                private _grp = createGroup [east, true];

                for "_j" from 1 to 4 do {
                    private _unitType = if (!isNil "GuerMenArray" && {GuerMenArray isNotEqualTo []}) then { selectRandom GuerMenArray } else { "O_G_Soldier_F" };
                    [_grp, _unitType, _spawnPos, [], 0, "NONE", "civilian checkpoint response"] call FLO_fnc_createGroupUnit;
                };

                _grp addWaypoint [_pos, 0] setWaypointType "SAD";
                { _x setUnitPos "MIDDLE"; } forEach units _grp;
            };
        };

        ["MISSION_COMPLETE", [true, "establish_checkpoint"]] call FLO_fnc_civilianMissionManager;
        true
    };
};

false
