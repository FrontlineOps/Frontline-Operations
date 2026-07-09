/*
 * Function: FLO_fnc_gtnPlayerTaskBridge
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes side-owned BIS commander tasks from GTN intent.
 *   Keeps exactly one primary and one secondary task for the active human side.
 *
 * Arguments:
 *   0: Update interval in seconds <NUMBER> - Default 20
 *
 * Return Value:
 *   BOOL - true when bridge loop started
 */

if (!isServer) exitWith { false };

params [["_interval", 20, [0]]];
if (_interval < 5) then { _interval = 5 };

if (!isNil "FLO_GTN_PlayerTaskBridgeRunning" && {FLO_GTN_PlayerTaskBridgeRunning}) exitWith { true };
FLO_GTN_PlayerTaskBridgeRunning = true;

private _primaryMinHoldSeconds = 180;
private _secondaryMinHoldSeconds = 120;
private _primaryReplaceScoreDelta = 18;
private _secondaryReplaceScoreDelta = 14;
private _defendQuietHoldSeconds = 45;

if (isNil "FLO_GTN_PlayerTasks") then {
    FLO_GTN_PlayerTasks = createHashMap;
};

[
    _interval,
    _primaryMinHoldSeconds,
    _secondaryMinHoldSeconds,
    _primaryReplaceScoreDelta,
    _secondaryReplaceScoreDelta,
    _defendQuietHoldSeconds
] spawn {
    params [
        "_interval",
        "_primaryMinHoldSeconds",
        "_secondaryMinHoldSeconds",
        "_primaryReplaceScoreDelta",
        "_secondaryReplaceScoreDelta",
        "_defendQuietHoldSeconds"
    ];

    while {FLO_GTN_PlayerTaskBridgeRunning} do {
        if (isNil "FLO_Objectives" || {FLO_Objectives isEqualTo []}) then {
            sleep _interval;
            continue;
        };

        private _activeSide = [FLO_ActivePlayerSide] call FLO_fnc_gtnTaskNormalizeSide;
        if !(_activeSide in [east, west]) then {
            sleep _interval;
            continue;
        };

        private _enemySide = [_activeSide] call FLO_fnc_gtnTaskEnemySide;
        private _stateKey = [_activeSide] call FLO_fnc_gtnTaskSideKey;
        private _playerPositions = [];
        {
            if (!alive _x) then { continue };
            if ((side group _x) != _activeSide) then { continue };
            _playerPositions pushBack (getPosATL _x);
        } forEach allPlayers;

        if (_playerPositions isEqualTo []) then {
            sleep _interval;
            continue;
        };

        private _cmdr = nil;
        private _worldObjectives = createHashMap;
        if (!isNil "FLO_GTN_ResourceManager") then {
            _cmdr = FLO_GTN_ResourceManager call ["_getCommanderBySide", [_activeSide]];
            if (!isNil "_cmdr") then {
                private _cmdrWorldState = _cmdr get "_worldState";
                _worldObjectives = _cmdrWorldState call ["_getObjectives", []];
            };
        };

        private _state = FLO_GTN_PlayerTasks get _stateKey;
        if (isNil "_state") then {
            _state = createHashMapFromArray [
                ["primaryTaskId", ""],
                ["secondaryTaskId", ""],
                ["primaryRef", ""],
                ["secondaryRef", ""],
                ["primaryKind", ""],
                ["primaryObjId", ""],
                ["primaryScore", 0],
                ["primaryAssignedAt", -1],
                ["primaryCalmStartedAt", -1],
                ["secondaryKind", ""],
                ["secondaryObjId", ""],
                ["secondaryScore", 0],
                ["secondaryAssignedAt", -1],
                ["secondaryTargets", []],
                ["lastNoTaskLog", 0]
            ];
            FLO_GTN_PlayerTasks set [_stateKey, _state];
        };

        // Migration keys for existing state saved before completion tracking was added.
        if (isNil {_state get "primaryKind"}) then { _state set ["primaryKind", ""]; };
        if (isNil {_state get "primaryObjId"}) then { _state set ["primaryObjId", ""]; };
        if (isNil {_state get "primaryScore"}) then { _state set ["primaryScore", 0]; };
        if (isNil {_state get "primaryAssignedAt"}) then { _state set ["primaryAssignedAt", -1]; };
        if (isNil {_state get "primaryCalmStartedAt"}) then { _state set ["primaryCalmStartedAt", -1]; };
        if (isNil {_state get "secondaryKind"}) then { _state set ["secondaryKind", ""]; };
        if (isNil {_state get "secondaryObjId"}) then { _state set ["secondaryObjId", ""]; };
        if (isNil {_state get "secondaryScore"}) then { _state set ["secondaryScore", 0]; };
        if (isNil {_state get "secondaryAssignedAt"}) then { _state set ["secondaryAssignedAt", -1]; };
        if (isNil {_state get "secondaryTargets"}) then { _state set ["secondaryTargets", []]; };
        if (isNil {_state get "lastNoTaskLog"}) then { _state set ["lastNoTaskLog", 0]; };

        private _cycleNow = diag_tickTime;

        // Recover slot kind/objective from legacy refs so completion works on pre-existing tasks.
        [_state, "primaryKind", "primaryObjId", "primaryRef"] call FLO_fnc_gtnRestoreLegacyTaskRefState;
        [_state, "secondaryKind", "secondaryObjId", "secondaryRef"] call FLO_fnc_gtnRestoreLegacyTaskRefState;
        if ((_state get "secondaryKind") isEqualTo "destroy" && {(_state get "secondaryTaskId") != ""} && {(_state get "secondaryTargets") isEqualTo []}) then {
            private _legacyObjId = _state get "secondaryObjId";
            if (_legacyObjId isNotEqualTo "") then {
                private _legacyObjData = FLO_Objectives get _legacyObjId;
                if (!isNil "_legacyObjData") then {
                    private _legacyDestroyInfo = createHashMap;
                    if (!isNil "_cmdr") then {
                        private _cmdrWorldState = _cmdr get "_worldState";
                        _legacyDestroyInfo = [_legacyObjId, _legacyObjData, _enemySide, _cmdrWorldState] call FLO_fnc_gtnTaskCollectDestroyTargets;
                    };
                    if ((keys _legacyDestroyInfo) isNotEqualTo []) then {
                        _state set ["secondaryTargets", _legacyDestroyInfo get "targets"];
                    };
                };
            };
        };

        // Resolve completion for active tasks before selecting replacements.
        private _activePrimaryId = _state get "primaryTaskId";
        private _activePrimaryKind = _state get "primaryKind";
        private _activePrimaryObj = _state get "primaryObjId";
        if (_activePrimaryId != "" && {_activePrimaryKind != ""} && {("" isNotEqualTo _activePrimaryObj)}) then {
            private _objData = FLO_Objectives get _activePrimaryObj;
            if (!isNil "_objData") then {
                private _owner = _objData get "owner";
                _owner = [_owner] call FLO_fnc_gtnTaskNormalizeSide;
                private _enemyCount = if (_activeSide isEqualTo west) then {
                    _objData get "opforCount"
                } else {
                    _objData get "bluforCount"
                };

                private _primaryComplete = false;
                switch (_activePrimaryKind) do {
                    case "capture": {
                        _state set ["primaryCalmStartedAt", -1];
                        _primaryComplete = _owner isEqualTo _activeSide;
                    };
                    case "defend": {
                        if ((_owner isEqualTo _activeSide) && {_enemyCount <= 0}) then {
                            private _primaryCalmStartedAt = _state get "primaryCalmStartedAt";
                            if (_primaryCalmStartedAt < 0) then {
                                _state set ["primaryCalmStartedAt", _cycleNow];
                            };
                            _primaryComplete = (_cycleNow - (_state get "primaryCalmStartedAt")) >= _defendQuietHoldSeconds;
                        } else {
                            _state set ["primaryCalmStartedAt", -1];
                        };
                    };
                    default {
                        _state set ["primaryCalmStartedAt", -1];
                    };
                };

                if (_primaryComplete) then {
                    [_activePrimaryId] call FLO_fnc_gtnMarkTaskSucceeded;
                    [_state] call FLO_fnc_gtnClearPrimaryTaskState;
                };
            };
        };

        private _activeSecondaryId = _state get "secondaryTaskId";
        private _activeSecondaryKind = _state get "secondaryKind";
        private _activeSecondaryObj = _state get "secondaryObjId";
        if (_activeSecondaryId != "" && {_activeSecondaryKind isEqualTo "destroy"} && {("" isNotEqualTo _activeSecondaryObj)}) then {
            private _targets = _state get "secondaryTargets";
            if (_targets isNotEqualTo []) then {
                private _targetsRemaining = [_targets, _enemySide] call FLO_fnc_gtnCountAliveTaskTargets;
                if (_targetsRemaining <= 0) then {
                    [_activeSecondaryId] call FLO_fnc_gtnMarkTaskSucceeded;
                    [_state] call FLO_fnc_gtnClearSecondaryTaskState;
                };
            };
        };

        private _captureCandidates = [];
        private _defendCandidates = [];
        private _destroyCandidates = [];

        {
            private _objId = _x;
            private _objData = FLO_Objectives get _objId;
            private _changed = false;
            if (isNil {_objData get "owner"}) then { _objData set ["owner", east]; _changed = true; };
            if (isNil {_objData get "bluforCount"}) then { _objData set ["bluforCount", 0]; _changed = true; };
            if (isNil {_objData get "opforCount"}) then { _objData set ["opforCount", 0]; _changed = true; };
            if (isNil {_objData get "priority"}) then { _objData set ["priority", 0]; _changed = true; };
            if (_changed) then { FLO_Objectives set [_objId, _objData]; };

            private _owner = _objData get "owner";
            _owner = [_owner] call FLO_fnc_gtnTaskNormalizeSide;
            private _priority = _objData get "priority";
            private _enemyCount = if (_activeSide isEqualTo west) then {
                _objData get "opforCount"
            } else {
                _objData get "bluforCount"
            };
            private _friendlyCount = if (_activeSide isEqualTo west) then {
                _objData get "bluforCount"
            } else {
                _objData get "opforCount"
            };
            private _frontlineEnemy = false;
            if (_owner isEqualTo _enemySide) then {
                {
                    private _linkedObjective = FLO_Objectives get _x;
                    if (isNil "_linkedObjective") then { continue };
                    private _linkedOwner = _linkedObjective get "owner";
                    _linkedOwner = [_linkedOwner] call FLO_fnc_gtnTaskNormalizeSide;
                    if (_linkedOwner isEqualTo _activeSide) exitWith {
                        _frontlineEnemy = true;
                    };
                } forEach (_objData get "linkedObjectives");
            };

            private _objectiveState = createHashMapFromArray [
                ["friendlyCount", _friendlyCount],
                ["enemyCount", _enemyCount],
                ["underAttack", _objData get "underAttack"],
                ["contested", _objData get "contested"],
                ["frontlineEnemy", _frontlineEnemy]
            ];
            if (!isNil "_worldObjectives" && {_objId in _worldObjectives}) then {
                private _worldObjectiveState = _worldObjectives get _objId;
                _objectiveState = _worldObjectiveState;
                _objectiveState set ["frontlineEnemy", _frontlineEnemy];
            };

            if (_owner isEqualTo _enemySide) then {
                private _captureScore = [_objId, _objData, _playerPositions, "capture", _objectiveState, nil] call FLO_fnc_gtnTaskScoreObjectiveForPlayers;
                _captureCandidates pushBack [_objId, _captureScore, _objData, _frontlineEnemy];

                private _destroyInfo = createHashMap;
                if (!isNil "_cmdr") then {
                    private _cmdrWorldState = _cmdr get "_worldState";
                    _destroyInfo = [_objId, _objData, _enemySide, _cmdrWorldState] call FLO_fnc_gtnTaskCollectDestroyTargets;
                };
                if ((keys _destroyInfo) isNotEqualTo []) then {
                    private _destroyScore = ([_objId, _objData, _playerPositions, "destroy", _objectiveState, nil] call FLO_fnc_gtnTaskScoreObjectiveForPlayers) + (_destroyInfo get "typeBonus");
                    private _meta = createHashMapFromArray [
                        ["targetLabel", _destroyInfo get "targetLabel"],
                        ["targetCount", _destroyInfo get "targetCount"],
                        ["taskPos", _destroyInfo get "taskPos"]
                    ];
                    _destroyCandidates pushBack [_objId, _destroyScore, _objData, _meta, _destroyInfo get "targets", _frontlineEnemy];
                };
            };

            if (_owner isEqualTo _activeSide && {_enemyCount > 0 || {_enemyCount > _friendlyCount}}) then {
                private _defendScore = [_objId, _objData, _playerPositions, "defend", _objectiveState, nil] call FLO_fnc_gtnTaskScoreObjectiveForPlayers;
                _defendCandidates pushBack [_objId, _defendScore, _objData];
            };
        } forEach (keys FLO_Objectives);

        private _frontlineCaptureCandidates = _captureCandidates select { _x select 3 };
        if (_frontlineCaptureCandidates isNotEqualTo []) then {
            _captureCandidates = _frontlineCaptureCandidates;
        };

        private _frontlineDestroyCandidates = _destroyCandidates select { _x select 5 };
        if (_frontlineDestroyCandidates isNotEqualTo []) then {
            _destroyCandidates = _frontlineDestroyCandidates;
        };

        private _captureRanked = _captureCandidates apply { [_x select 1, _x] };
        _captureRanked sort false;
        _captureCandidates = _captureRanked apply { _x select 1 };

        private _defendRanked = _defendCandidates apply { [_x select 1, _x] };
        _defendRanked sort false;
        _defendCandidates = _defendRanked apply { _x select 1 };

        private _destroyRanked = _destroyCandidates apply { [_x select 1, _x] };
        _destroyRanked sort false;
        _destroyCandidates = _destroyRanked apply { _x select 1 };

        private _currentPrimaryRef = _state get "primaryRef";
        private _currentPrimaryKind = _state get "primaryKind";
        private _currentPrimaryObjId = _state get "primaryObjId";
        private _currentPrimaryScore = _state get "primaryScore";
        private _currentPrimaryAssignedAt = _state get "primaryAssignedAt";

        private _desiredPrimaryKind = "";
        private _desiredPrimaryObjId = "";
        private _desiredPrimaryData = nil;
        private _desiredPrimaryScore = -1e9;

        private _bestDefend = _defendCandidates param [0, []];
        if (_bestDefend isNotEqualTo []) then {
            _desiredPrimaryKind = "defend";
            _desiredPrimaryObjId = _bestDefend select 0;
            _desiredPrimaryData = _bestDefend select 2;
            _desiredPrimaryScore = _bestDefend select 1;
        };

        private _bestCapture = _captureCandidates param [0, []];
        if (_bestCapture isNotEqualTo [] && {(_desiredPrimaryObjId == "") || {(_bestCapture select 1) > _desiredPrimaryScore}}) then {
            _desiredPrimaryKind = "capture";
            _desiredPrimaryObjId = _bestCapture select 0;
            _desiredPrimaryData = _bestCapture select 2;
            _desiredPrimaryScore = _bestCapture select 1;
        };

        private _currentPrimaryCandidate = [];
        switch (_currentPrimaryKind) do {
            case "defend": {
                _currentPrimaryCandidate = (_defendCandidates select { (_x select 0) == _currentPrimaryObjId }) param [0, []];
            };
            case "capture": {
                _currentPrimaryCandidate = (_captureCandidates select { (_x select 0) == _currentPrimaryObjId }) param [0, []];
            };
        };
        if (_currentPrimaryCandidate isNotEqualTo []) then {
            _currentPrimaryScore = _currentPrimaryCandidate select 1;
        };

        private _newPrimaryKind = _desiredPrimaryKind;
        private _newPrimaryObjId = _desiredPrimaryObjId;
        private _newPrimaryData = _desiredPrimaryData;
        private _newPrimaryScore = _desiredPrimaryScore;
        private _newPrimaryRef = if (_newPrimaryObjId != "") then { _newPrimaryKind + "_" + _newPrimaryObjId } else { "" };
        private _primaryHoldActive = _currentPrimaryRef != "" && {_currentPrimaryAssignedAt >= 0} && {(_cycleNow - _currentPrimaryAssignedAt) < _primaryMinHoldSeconds};
        private _primaryCanHoldCurrent = (_currentPrimaryKind != "capture") || {_currentPrimaryCandidate isNotEqualTo []};

        if (_currentPrimaryRef != "" && {_newPrimaryRef != _currentPrimaryRef}) then {
            if (_primaryCanHoldCurrent && {_primaryHoldActive || {_newPrimaryRef == ""} || {_newPrimaryScore < (_currentPrimaryScore + _primaryReplaceScoreDelta)}}) then {
                _newPrimaryKind = _currentPrimaryKind;
                _newPrimaryObjId = _currentPrimaryObjId;
                _newPrimaryData = FLO_Objectives get _currentPrimaryObjId;
                _newPrimaryScore = _currentPrimaryScore;
                _newPrimaryRef = _currentPrimaryRef;
            };
        };

        private _currentSecondaryRef = _state get "secondaryRef";
        private _currentSecondaryKind = _state get "secondaryKind";
        private _currentSecondaryObjId = _state get "secondaryObjId";
        private _currentSecondaryScore = _state get "secondaryScore";
        private _currentSecondaryAssignedAt = _state get "secondaryAssignedAt";
        private _currentSecondaryTargets = _state get "secondaryTargets";

        private _selectedSecondary = [];

        {
            private _objId = _x select 0;
            if (_objId != _newPrimaryObjId) exitWith {
                _selectedSecondary = _x;
            };
        } forEach _destroyCandidates;

        private _currentSecondaryCandidate = [];
        if (_currentSecondaryKind isEqualTo "destroy") then {
            _currentSecondaryCandidate = (_destroyCandidates select { (_x select 0) == _currentSecondaryObjId }) param [0, []];
        };
        if (_currentSecondaryCandidate isNotEqualTo []) then {
            _currentSecondaryScore = _currentSecondaryCandidate select 1;
            _currentSecondaryTargets = _currentSecondaryCandidate select 4;
        };

        private _newSecondaryKind = "";
        private _newSecondaryObjId = "";
        private _newSecondaryData = nil;
        private _newSecondaryScore = -1e9;
        private _newSecondaryMeta = createHashMapFromArray [["targetLabel", ""], ["targetCount", 0]];
        private _newSecondaryTargets = [];
        if (_selectedSecondary isNotEqualTo []) then {
            _newSecondaryKind = "destroy";
            _newSecondaryObjId = _selectedSecondary select 0;
            _newSecondaryData = _selectedSecondary select 2;
            _newSecondaryScore = _selectedSecondary select 1;
            _newSecondaryMeta = _selectedSecondary select 3;
            _newSecondaryTargets = _selectedSecondary select 4;
        };
        private _newSecondaryRef = if (_newSecondaryObjId != "") then { _newSecondaryKind + "_" + _newSecondaryObjId } else { "" };
        private _secondaryHoldActive = _currentSecondaryRef != "" && {_currentSecondaryAssignedAt >= 0} && {(_cycleNow - _currentSecondaryAssignedAt) < _secondaryMinHoldSeconds};
        private _secondaryCanHoldCurrent = (_currentSecondaryKind != "destroy") || {_currentSecondaryCandidate isNotEqualTo []};

        if (_currentSecondaryRef != "" && {_newSecondaryRef != _currentSecondaryRef}) then {
            if (_secondaryCanHoldCurrent && {_secondaryHoldActive || {_newSecondaryRef == ""} || {_newSecondaryScore < (_currentSecondaryScore + _secondaryReplaceScoreDelta)}}) then {
                _newSecondaryKind = _currentSecondaryKind;
                _newSecondaryObjId = _currentSecondaryObjId;
                _newSecondaryData = FLO_Objectives get _currentSecondaryObjId;
                _newSecondaryScore = _currentSecondaryScore;
                _newSecondaryMeta = createHashMapFromArray [["targetLabel", ""], ["targetCount", count _currentSecondaryTargets]];
                _newSecondaryTargets = _currentSecondaryTargets;
                _newSecondaryRef = _currentSecondaryRef;
            };
        };

        // Update primary task slot.
        private _oldPrimaryId = _state get "primaryTaskId";
        private _primaryNeedsPublish = ((_state get "primaryRef") != _newPrimaryRef) || {[_oldPrimaryId] call FLO_fnc_gtnTaskMissing};
        if (_primaryNeedsPublish) then {
            [_oldPrimaryId] call FLO_fnc_gtnDeleteTaskIfPresent;
            [_state] call FLO_fnc_gtnClearPrimaryTaskState;

            if (_newPrimaryRef != "" && {!isNil "_newPrimaryData"}) then {
                private _newPrimaryId = [_activeSide, "PRIMARY", _newPrimaryKind, _newPrimaryObjId, _newPrimaryData] call FLO_fnc_gtnPublishPlayerTask;
                _state set ["primaryTaskId", _newPrimaryId];
                _state set ["primaryRef", _newPrimaryRef];
                _state set ["primaryKind", _newPrimaryKind];
                _state set ["primaryObjId", _newPrimaryObjId];
                _state set ["primaryScore", _newPrimaryScore];
                _state set ["primaryAssignedAt", _cycleNow];
                _state set ["primaryCalmStartedAt", -1];
                ["GTN_TASKS", 3, format["Assigned primary task %1 (%2, score=%3)", _newPrimaryRef, _newPrimaryId, _newPrimaryScore]] call FLO_fnc_log;
            };
        } else {
            if ((_state get "primaryRef") != "") then {
                _state set ["primaryScore", _newPrimaryScore];
            };
        };

        // Update secondary task slot.
        private _oldSecondaryId = _state get "secondaryTaskId";
        private _secondaryNeedsPublish = ((_state get "secondaryRef") != _newSecondaryRef) || {[_oldSecondaryId] call FLO_fnc_gtnTaskMissing};
        if (_secondaryNeedsPublish) then {
            [_oldSecondaryId] call FLO_fnc_gtnDeleteTaskIfPresent;
            [_state] call FLO_fnc_gtnClearSecondaryTaskState;

            if (_newSecondaryRef != "" && {!isNil "_newSecondaryData"}) then {
                private _markedTargets = _newSecondaryTargets;

                if ((_newSecondaryKind != "destroy") || {_markedTargets isNotEqualTo []}) then {
                    private _newSecondaryId = [_activeSide, "SECONDARY", _newSecondaryKind, _newSecondaryObjId, _newSecondaryData, _newSecondaryMeta] call FLO_fnc_gtnPublishPlayerTask;
                    _state set ["secondaryTaskId", _newSecondaryId];
                    _state set ["secondaryRef", _newSecondaryRef];
                    _state set ["secondaryKind", _newSecondaryKind];
                    _state set ["secondaryObjId", _newSecondaryObjId];
                    _state set ["secondaryScore", _newSecondaryScore];
                    _state set ["secondaryAssignedAt", _cycleNow];
                    _state set ["secondaryTargets", _markedTargets];
                    ["GTN_TASKS", 3, format["Assigned secondary task %1 (%2, score=%3, targets=%4)", _newSecondaryRef, _newSecondaryId, _newSecondaryScore, count _markedTargets]] call FLO_fnc_log;
                };
            };
        } else {
            if ((_state get "secondaryRef") != "") then {
                _state set ["secondaryScore", _newSecondaryScore];
                _state set ["secondaryTargets", _newSecondaryTargets];
            };
        };

        if ((_state get "primaryTaskId") isEqualTo "" && {(_state get "secondaryTaskId") isEqualTo ""}) then {
            private _lastNoTaskLog = _state get "lastNoTaskLog";
            if ((diag_tickTime - _lastNoTaskLog) > 120) then {
                ["GTN_TASKS", 2, format["No task candidates for %1 (capture=%2 defend=%3 destroy=%4)", _stateKey, count _captureCandidates, count _defendCandidates, count _destroyCandidates]] call FLO_fnc_log;
                _state set ["lastNoTaskLog", diag_tickTime];
            };
        };

        FLO_GTN_PlayerTasks set [_stateKey, _state];
        sleep _interval;
    };
};

["GTN_TASKS", 2, format["Player task bridge started (%1s interval)", _interval]] call FLO_fnc_log;

true
