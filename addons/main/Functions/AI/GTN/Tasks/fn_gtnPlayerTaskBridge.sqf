/* Publishes one player capture task from the side's current direct ATTACK orders. */
if (!isServer) exitWith { false };
if (!isNil "FLO_GTN_PlayerTaskBridgeRunning" && {FLO_GTN_PlayerTaskBridgeRunning}) exitWith { true };

FLO_GTN_PlayerTaskBridgeRunning = true;
FLO_GTN_PlayerTasks = createHashMap;

[15] spawn {
    params ["_interval"];
    waitUntil {
        sleep 1;
        FLO_MissionReady && {keys (call FLO_fnc_gtnGetCommandersBySide) isNotEqualTo []}
    };

    while {FLO_GTN_PlayerTaskBridgeRunning} do {
        private _activeSide = FLO_ActivePlayerSide;
        if !(_activeSide in [west, east]) then {
            throw format ["FLO_fnc_gtnPlayerTaskBridge: invalid active player side %1", _activeSide];
        };
        private _sideKey = [_activeSide] call FLO_fnc_gtnTaskSideKey;
        private _state = if (_sideKey in FLO_GTN_PlayerTasks) then {
            FLO_GTN_PlayerTasks get _sideKey
        } else {
            createHashMapFromArray [
                ["primaryTaskId", ""],
                ["assignmentId", ""],
                ["objectiveId", ""]
            ]
        };

        private _attackCounts = createHashMap;
        {
            private _groupData = _y;
            if ((_groupData get "side") isNotEqualTo _activeSide) then { continue };
            if ((_groupData get "commanderOrder") != "ATTACK") then { continue };
            private _objectiveId = _groupData get "attackObjective";
            if (_objectiveId == "") then {
                ["GTN_TASKS", 1, format ["ATTACK group %1 has no objective", _x]] call FLO_fnc_log;
                throw format ["ATTACK group %1 has no objective", _x];
            };
            private _count = if (_objectiveId in _attackCounts) then { _attackCounts get _objectiveId } else { 0 };
            _attackCounts set [_objectiveId, _count + 1];
        } forEach (call FLO_fnc_virtualizationGetGroupMap);

        private _ranked = [];
        {
            if !(_x in FLO_Objectives) then { throw format ["Player task attack target %1 is missing", _x] };
            private _objective = FLO_Objectives get _x;
            if ((_objective get "owner") isEqualTo _activeSide) then { continue };
            _ranked pushBack [-(_attackCounts get _x), -(_objective get "priority"), _x];
        } forEach (keys _attackCounts);
        _ranked sort true;
        private _objectiveId = if (_ranked isEqualTo []) then { "" } else { (_ranked select 0) select 2 };
        private _assignmentId = if (_objectiveId == "") then { "" } else { format ["DIRECT_%1_%2", _sideKey, _objectiveId] };

        private _taskId = _state get "primaryTaskId";
        if (_taskId != "" && {[_taskId] call FLO_fnc_gtnTaskMissing}) then {
            [_state] call FLO_fnc_gtnClearPrimaryTaskState;
            _taskId = "";
        };

        if (_taskId != "" && {(_state get "objectiveId") != _objectiveId}) then {
            private _trackedObjectiveId = _state get "objectiveId";
            if (_trackedObjectiveId in FLO_Objectives && {((FLO_Objectives get _trackedObjectiveId) get "owner") isEqualTo _activeSide}) then {
                [_taskId] call FLO_fnc_gtnMarkTaskSucceeded;
            } else {
                [_taskId] call FLO_fnc_gtnDeleteTaskIfPresent;
            };
            [_state] call FLO_fnc_gtnClearPrimaryTaskState;
            _taskId = "";
        };

        if (_taskId == "" && {_objectiveId != ""}) then {
            private _objective = FLO_Objectives get _objectiveId;
            private _newTaskId = [_activeSide, _assignmentId, "capture", _objectiveId, _objective] call FLO_fnc_gtnPublishPlayerTask;
            _state set ["primaryTaskId", _newTaskId];
            _state set ["assignmentId", _assignmentId];
            _state set ["objectiveId", _objectiveId];
            ["GTN_TASKS", 3, format ["Published direct attack task %1 for %2", _newTaskId, _objectiveId]] call FLO_fnc_log;
        };

        FLO_GTN_PlayerTasks set [_sideKey, _state];
        sleep _interval;
    };
};

["GTN_TASKS", 3, "Direct attack task bridge started (15s interval)"] call FLO_fnc_log;
true
