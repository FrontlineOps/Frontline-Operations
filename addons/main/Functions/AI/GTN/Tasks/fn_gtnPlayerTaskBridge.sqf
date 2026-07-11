/*
 * Function: FLO_fnc_gtnPlayerTaskBridge
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Publishes exactly one BIS task from the Campaign Director's observable
 *   operation state. It never selects an objective independently.
 *
 * Return Value:
 *   True once the bridge worker has started <BOOL>
 */

if (!isServer) exitWith { false };
if (!isNil "FLO_GTN_PlayerTaskBridgeRunning" && {FLO_GTN_PlayerTaskBridgeRunning}) exitWith { true };

FLO_GTN_PlayerTaskBridgeRunning = true;
FLO_GTN_PlayerTasks = createHashMap;

[15] spawn {
    params ["_interval"];

    waitUntil {
        sleep 1;
        FLO_MissionReady
        && {!isNil "FLO_CampaignDirector"}
    };

    while {FLO_GTN_PlayerTaskBridgeRunning} do {
        private _activeSide = [FLO_ActivePlayerSide] call FLO_fnc_gtnTaskNormalizeSide;
        if !(_activeSide in [west, east]) then {
            throw format ["FLO_fnc_gtnPlayerTaskBridge: invalid active player side %1", FLO_ActivePlayerSide];
        };

        private _sideKey = [_activeSide] call FLO_fnc_gtnTaskSideKey;
        private _state = if (_sideKey in FLO_GTN_PlayerTasks) then {
            FLO_GTN_PlayerTasks get _sideKey
        } else {
            createHashMapFromArray [
                ["primaryTaskId", ""],
                ["operationId", ""],
                ["objectiveId", ""],
                ["role", ""]
            ]
        };

        private _campaign = FLO_CampaignDirector call ["_getState", []];
        private _operationId = _campaign get "operationId";
        private _objectiveId = _campaign get "objectiveId";
        private _phase = _campaign get "phase";
        private _result = _campaign get "result";
        private _role = "";
        if ((_campaign get "attackerSideKey") == _sideKey) then { _role = "ATTACKER"; };
        if ((_campaign get "defenderSideKey") == _sideKey) then { _role = "DEFENDER"; };

        private _taskId = _state get "primaryTaskId";
        if (_taskId != "" && {[_taskId] call FLO_fnc_gtnTaskMissing}) then {
            [_state] call FLO_fnc_gtnClearPrimaryTaskState;
            _taskId = "";
        };

        if (_taskId != "") then {
            private _trackedOperationId = _state get "operationId";
            private _trackedRole = _state get "role";
            private _trackedObjectiveId = _state get "objectiveId";

            if (_trackedOperationId != _operationId || {_trackedObjectiveId != _objectiveId}) then {
                [_taskId] call FLO_fnc_gtnDeleteTaskIfPresent;
                [_state] call FLO_fnc_gtnClearPrimaryTaskState;
                _taskId = "";
            } else {
                if (_phase in ["SECURE", "CONSOLIDATE"]) then {
                    if (_trackedRole == "ATTACKER") then {
                        [_taskId] call FLO_fnc_gtnMarkTaskSucceeded;
                    } else {
                        [_taskId] call FLO_fnc_gtnMarkTaskFailed;
                    };
                    [_state] call FLO_fnc_gtnClearPrimaryTaskState;
                    _taskId = "";
                };

                if (_taskId != "" && {_phase == "RECOVERY"}) then {
                    if (_result == "ATTACKER_FAILED") then {
                        if (_trackedRole == "ATTACKER") then {
                            [_taskId] call FLO_fnc_gtnMarkTaskFailed;
                        } else {
                            [_taskId] call FLO_fnc_gtnMarkTaskSucceeded;
                        };
                    } else {
                        if (_result == "ATTACKER_SUCCESS") then {
                            if (_trackedRole == "ATTACKER") then {
                                [_taskId] call FLO_fnc_gtnMarkTaskSucceeded;
                            } else {
                                [_taskId] call FLO_fnc_gtnMarkTaskFailed;
                            };
                        } else {
                            [_taskId] call FLO_fnc_gtnDeleteTaskIfPresent;
                        };
                    };
                    [_state] call FLO_fnc_gtnClearPrimaryTaskState;
                    _taskId = "";
                };

                if (_taskId != "" && {_phase != "ASSAULT"}) then {
                    [_taskId] call FLO_fnc_gtnDeleteTaskIfPresent;
                    [_state] call FLO_fnc_gtnClearPrimaryTaskState;
                    _taskId = "";
                };
            };
        };

        if (
            _taskId == ""
            && {_phase == "ASSAULT"}
            && {_operationId != ""}
            && {_objectiveId != ""}
            && {_role in ["ATTACKER", "DEFENDER"]}
        ) then {
            private _objective = FLO_Objectives get _objectiveId;
            private _kind = ["defend", "capture"] select (_role == "ATTACKER");
            private _newTaskId = [_activeSide, _operationId, _kind, _objectiveId, _objective] call FLO_fnc_gtnPublishPlayerTask;

            _state set ["primaryTaskId", _newTaskId];
            _state set ["operationId", _operationId];
            _state set ["objectiveId", _objectiveId];
            _state set ["role", _role];
            ["GTN_TASKS", 2, format ["Published %1 task %2 for operation %3", _role, _newTaskId, _operationId]] call FLO_fnc_log;
        };

        FLO_GTN_PlayerTasks set [_sideKey, _state];
        sleep _interval;
    };
};

["GTN_TASKS", 2, "Operation task bridge started (15s interval)"] call FLO_fnc_log;
true
