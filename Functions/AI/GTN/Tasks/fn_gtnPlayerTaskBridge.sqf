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

if (isNil "FLO_GTN_PlayerTasks") then {
    FLO_GTN_PlayerTasks = createHashMap;
};

private _fnc_sideKey = {
    params ["_side"];
    if (_side isEqualTo east) exitWith { "EAST" };
    if (_side isEqualTo west) exitWith { "WEST" };
    ""
};

private _fnc_enemySide = {
    params ["_side"];
    if (_side isEqualTo east) exitWith { west };
    if (_side isEqualTo west) exitWith { east };
    sideUnknown
};

private _fnc_normalizeSide = {
    params ["_value"];
    if (_value isEqualType "") then {
        private _k = toUpper _value;
        if (_k isEqualTo "WEST") exitWith { west };
        if (_k isEqualTo "EAST") exitWith { east };
    };
    _value
};

private _fnc_taskTypeFromKind = {
    params ["_kind"];
    switch (_kind) do {
        case "capture": { "Attack" };
        case "defend": { "Defend" };
        case "destroy": { "Destroy" };
        default { "Attack" };
    }
};

private _fnc_targetLabelFromIntel = {
    params ["_intel"];
    if (_intel get "hasArmor") exitWith { "armor" };
    if ((_intel get "hasAA") && {_intel get "hasStatic"}) exitWith { "static AA" };
    if (_intel get "hasAA") exitWith { "air-defense" };
    if (_intel get "hasStatic") exitWith { "static weapons" };
    "assets"
};

private _fnc_taskTitle = {
    params ["_kind", "_objId", "_objData", ["_meta", createHashMapFromArray [["targetLabel", ""], ["targetCount", 0]]]];
    private _name = _objData get "name";
    private _targetLabel = _meta get "targetLabel";
    private _targetCount = _meta get "targetCount";
    switch (_kind) do {
        case "capture": { format ["Capture %1", _name] };
        case "defend": { format ["Defend %1", _name] };
        case "destroy": {
            if (_targetLabel != "") then {
                if (_targetCount > 0) then {
                    format ["Destroy %1 enemy %2 at %3", _targetCount, _targetLabel, _name]
                } else {
                    format ["Destroy enemy %1 at %2", _targetLabel, _name]
                }
            } else {
                format ["Destroy enemy assets at %1", _name]
            }
        };
        default { format ["Operate at %1", _name] };
    }
};

private _fnc_taskDesc = {
    params ["_kind", "_objId", "_objData", ["_meta", createHashMapFromArray [["targetLabel", ""], ["targetCount", 0]]]];
    private _name = _objData get "name";
    private _targetLabel = _meta get "targetLabel";
    private _targetCount = _meta get "targetCount";
    switch (_kind) do {
        case "capture": { format ["Commander objective: capture %1 and hold the area.", _name] };
        case "defend": { format ["Commander objective: defend %1 against enemy pressure.", _name] };
        case "destroy": {
            if (_targetLabel != "") then {
                if (_targetCount > 0) then {
                    format ["Commander intel reports %1 enemy %2 near %3. Destroy marked targets.", _targetCount, _targetLabel, _name]
                } else {
                    format ["Commander intel reports enemy %1 near %2. Destroy that target.", _targetLabel, _name]
                }
            } else {
                format ["Commander objective: destroy hostile assets around %1.", _name]
            }
        };
        default { format ["Commander objective: operate near %1.", _name] };
    }
};

private _fnc_deleteTaskIfPresent = {
    params ["_taskId"];
    if (_taskId isEqualTo "") exitWith {};
    [_taskId] call BIS_fnc_deleteTask;
};

private _fnc_taskMissing = {
    params ["_taskId"];
    if (_taskId isEqualTo "") exitWith { true };
    !([_taskId] call BIS_fnc_taskExists)
};

private _fnc_clearPrimaryTaskState = {
    params ["_state"];
    _state set ["primaryTaskId", ""];
    _state set ["primaryRef", ""];
    _state set ["primaryKind", ""];
    _state set ["primaryObjId", ""];
};

private _fnc_clearSecondaryTaskState = {
    params ["_state"];
    _state set ["secondaryTaskId", ""];
    _state set ["secondaryRef", ""];
    _state set ["secondaryKind", ""];
    _state set ["secondaryObjId", ""];
    _state set ["secondaryTargets", []];
};

private _fnc_restoreLegacyRefState = {
    params ["_state", "_kindKey", "_objKey", "_refKey"];
    if ((_state get _kindKey) isEqualTo "" && {(_state get _refKey) != ""}) then {
        private _ref = _state get _refKey;
        private _sep = _ref find "_";
        if (_sep > 0) then {
            _state set [_kindKey, _ref select [0, _sep]];
            _state set [_objKey, _ref select [_sep + 1, (count _ref) - _sep - 1]];
        };
    };
};

private _fnc_publishTask = {
    params ["_ownerSide", "_slotPrefix", "_kind", "_objId", "_objData", ["_meta", createHashMapFromArray [["targetLabel", ""], ["targetCount", 0]]]];

    private _taskId = format ["FLO_GTN_%1_%2_%3", _slotPrefix, _kind, _objId];
    private _title = [_kind, _objId, _objData, _meta] call _fnc_taskTitle;
    private _desc = [_kind, _objId, _objData, _meta] call _fnc_taskDesc;
    private _taskType = [_kind] call _fnc_taskTypeFromKind;
    private _pos = _objData get "position";

    [
        _ownerSide,
        _taskId,
        [_desc, _title, ""],
        _pos,
        "ASSIGNED",
        0,
        true,
        _taskType,
        false
    ] call BIS_fnc_taskCreate;

    _taskId
};

private _fnc_markTaskSucceeded = {
    params ["_taskId", ["_cleanupDelay", 45]];
    if (_taskId isEqualTo "") exitWith {};
    [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
    [_taskId, _cleanupDelay] spawn {
        params ["_tid", "_delay"];
        sleep _delay;
        [_tid] call BIS_fnc_deleteTask;
    };
};

private _fnc_collectDestroyTargets = {
    params ["_objData", "_enemySide"];
    private _pos = _objData get "position";
    private _targets = [];
    {
        if (!alive _x) then { continue };
        if ((side _x) != _enemySide) then { continue };

        private _valuable = (_x isKindOf "Tank") || (_x isKindOf "Wheeled_APC_F") || (_x isKindOf "Tracked_APC_F") || (_x isKindOf "StaticWeapon");

        if (_valuable) then {
            _targets pushBackUnique _x;
        };
    } forEach (_pos nearEntities [["LandVehicle", "StaticWeapon"], 900]);
    _targets
};

private _fnc_countAliveTargets = {
    params ["_targets", "_enemySide"];
    {
        !isNull _x && {alive _x} && {(side _x) isEqualTo _enemySide}
    } count _targets
};

[ _interval, _fnc_sideKey, _fnc_enemySide, _fnc_normalizeSide, _fnc_taskTypeFromKind, _fnc_targetLabelFromIntel, _fnc_taskTitle, _fnc_taskDesc, _fnc_deleteTaskIfPresent, _fnc_taskMissing, _fnc_clearPrimaryTaskState, _fnc_clearSecondaryTaskState, _fnc_restoreLegacyRefState, _fnc_publishTask, _fnc_markTaskSucceeded, _fnc_collectDestroyTargets, _fnc_countAliveTargets ] spawn {
    params [
        "_interval",
        "_fnc_sideKey",
        "_fnc_enemySide",
        "_fnc_normalizeSide",
        "_fnc_taskTypeFromKind",
        "_fnc_targetLabelFromIntel",
        "_fnc_taskTitle",
        "_fnc_taskDesc",
        "_fnc_deleteTaskIfPresent",
        "_fnc_taskMissing",
        "_fnc_clearPrimaryTaskState",
        "_fnc_clearSecondaryTaskState",
        "_fnc_restoreLegacyRefState",
        "_fnc_publishTask",
        "_fnc_markTaskSucceeded",
        "_fnc_collectDestroyTargets",
        "_fnc_countAliveTargets"
    ];

    while {FLO_GTN_PlayerTaskBridgeRunning} do {
        if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) then {
            sleep _interval;
            continue;
        };

        private _activeSide = [FLO_ActivePlayerSide] call _fnc_normalizeSide;
        if !(_activeSide in [east, west]) then {
            sleep _interval;
            continue;
        };

        private _enemySide = [_activeSide] call _fnc_enemySide;
        private _stateKey = [_activeSide] call _fnc_sideKey;
        private _worldState = nil;
        if (!isNil "FLO_GTN_ResourceManager") then {
            private _cmdr = FLO_GTN_ResourceManager call ["_getCommanderBySide", [_activeSide]];
            if (!isNil "_cmdr") then {
                _worldState = _cmdr get "_worldState";
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
                ["secondaryKind", ""],
                ["secondaryObjId", ""],
                ["secondaryTargets", []],
                ["lastNoTaskLog", 0]
            ];
            FLO_GTN_PlayerTasks set [_stateKey, _state];
        };

        // Migration keys for existing state saved before completion tracking was added.
        if (isNil {_state get "primaryKind"}) then { _state set ["primaryKind", ""]; };
        if (isNil {_state get "primaryObjId"}) then { _state set ["primaryObjId", ""]; };
        if (isNil {_state get "secondaryKind"}) then { _state set ["secondaryKind", ""]; };
        if (isNil {_state get "secondaryObjId"}) then { _state set ["secondaryObjId", ""]; };
        if (isNil {_state get "secondaryTargets"}) then { _state set ["secondaryTargets", []]; };
        if (isNil {_state get "lastNoTaskLog"}) then { _state set ["lastNoTaskLog", 0]; };

        // Recover slot kind/objective from legacy refs so completion works on pre-existing tasks.
        [_state, "primaryKind", "primaryObjId", "primaryRef"] call _fnc_restoreLegacyRefState;
        [_state, "secondaryKind", "secondaryObjId", "secondaryRef"] call _fnc_restoreLegacyRefState;
        if ((_state get "secondaryKind") isEqualTo "destroy" && {(_state get "secondaryTaskId") != ""} && {(count (_state get "secondaryTargets")) == 0}) then {
            private _legacyObjId = _state get "secondaryObjId";
            if !(_legacyObjId isEqualTo "") then {
                private _legacyObjData = FLO_Objectives get _legacyObjId;
                if (!isNil "_legacyObjData") then {
                    private _legacyTargets = [_legacyObjData, _enemySide] call _fnc_collectDestroyTargets;
                    _state set ["secondaryTargets", _legacyTargets];
                };
            };
        };

        // Resolve completion for active tasks before selecting replacements.
        private _activePrimaryId = _state get "primaryTaskId";
        private _activePrimaryKind = _state get "primaryKind";
        private _activePrimaryObj = _state get "primaryObjId";
        if (_activePrimaryId != "" && {_activePrimaryKind != ""} && {!("" isEqualTo _activePrimaryObj)}) then {
            private _objData = FLO_Objectives get _activePrimaryObj;
            if (!isNil "_objData") then {
                private _owner = _objData get "owner";
                _owner = [_owner] call _fnc_normalizeSide;
                private _enemyCount = if (_activeSide isEqualTo west) then {
                    _objData get "opforCount"
                } else {
                    _objData get "bluforCount"
                };

                private _primaryComplete = false;
                switch (_activePrimaryKind) do {
                    case "capture": {
                        _primaryComplete = _owner isEqualTo _activeSide;
                    };
                    case "defend": {
                        _primaryComplete = (_owner isEqualTo _activeSide) && {_enemyCount <= 0};
                    };
                };

                if (_primaryComplete) then {
                    [_activePrimaryId] call _fnc_markTaskSucceeded;
                    [_state] call _fnc_clearPrimaryTaskState;
                };
            };
        };

        private _activeSecondaryId = _state get "secondaryTaskId";
        private _activeSecondaryKind = _state get "secondaryKind";
        private _activeSecondaryObj = _state get "secondaryObjId";
        if (_activeSecondaryId != "" && {_activeSecondaryKind isEqualTo "destroy"} && {!("" isEqualTo _activeSecondaryObj)}) then {
            private _targets = _state get "secondaryTargets";
            if ((count _targets) > 0) then {
                private _targetsRemaining = [_targets, _enemySide] call _fnc_countAliveTargets;
                if (_targetsRemaining <= 0) then {
                    [_activeSecondaryId] call _fnc_markTaskSucceeded;
                    [_state] call _fnc_clearSecondaryTaskState;
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
            _owner = [_owner] call _fnc_normalizeSide;
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

            if (_owner isEqualTo _enemySide) then {
                _captureCandidates pushBack [_objId, _priority, _objData];

                if (!isNil "_worldState") then {
                    private _intel = _worldState call ["_getObjectiveIntel", [_objId]];
                    private _intelQuality = _intel get "intelQuality";
                    private _intelFresh = _worldState call ["_isIntelFresh", [_objId, 900]];
                    if (_intelFresh && {_intelQuality >= 0.5}) then {
                        private _power = _intel get "totalCombatPower";
                        private _hasArmor = _intel get "hasArmor";
                        private _hasAA = _intel get "hasAA";
                        private _hasStatic = _intel get "hasStatic";
                        if (_hasArmor || _hasAA || _hasStatic || {_power >= 250}) then {
                            private _score = _priority + (_power / 25) + (_intelQuality * 20);
                            if (_hasArmor) then { _score = _score + 35 };
                            if (_hasAA) then { _score = _score + 30 };
                            if (_hasStatic) then { _score = _score + 20 };

                            private _targetLabel = [_intel] call _fnc_targetLabelFromIntel;
                            private _meta = createHashMapFromArray [
                                ["targetLabel", _targetLabel],
                                ["targetCount", 0]
                            ];
                            _destroyCandidates pushBack [_objId, _score, _objData, _meta];
                        };
                    };
                };
            };

            if (_owner isEqualTo _activeSide && {_enemyCount > 0 || {_enemyCount > _friendlyCount}}) then {
                _defendCandidates pushBack [_objId, (_enemyCount * 10) + _priority, _objData];
            };
        } forEach (keys FLO_Objectives);

        _captureCandidates = [_captureCandidates, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;
        _defendCandidates = [_defendCandidates, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;
        _destroyCandidates = [_destroyCandidates, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;

        private _primaryKind = "";
        private _primaryObjId = "";
        private _primaryData = nil;

        if (count _defendCandidates > 0) then {
            private _bestDefend = _defendCandidates select 0;
            _primaryObjId = _bestDefend select 0;
            _primaryData = _bestDefend select 2;
            _primaryKind = "defend";
        } else {
            if (count _captureCandidates > 0) then {
                private _bestCapture = _captureCandidates select 0;
                _primaryObjId = _bestCapture select 0;
                _primaryData = _bestCapture select 2;
                _primaryKind = "capture";
            };
        };

        private _secondaryKind = "";
        private _secondaryObjId = "";
        private _secondaryData = nil;
        private _secondaryMeta = createHashMapFromArray [["targetLabel", ""], ["targetCount", 0]];

        // Secondary prefers known high-value assets from commander intel.
        {
            private _objId = _x select 0;
            private _objData = _x select 2;
            private _meta = _x select 3;
            if (_objId != _primaryObjId) exitWith {
                _secondaryKind = "destroy";
                _secondaryObjId = _objId;
                _secondaryData = _objData;
                _secondaryMeta = _meta;
            };
        } forEach _destroyCandidates;

        // Fallback: generic destroy objective if we have no confirmed high-value intel.
        {
            if (_secondaryObjId != "") exitWith {};
            private _objId = _x select 0;
            private _objData = _x select 2;
            if (_objId != _primaryObjId) exitWith {
                _secondaryKind = "destroy";
                _secondaryObjId = _objId;
                _secondaryData = _objData;
            };
        } forEach _captureCandidates;

        // Update primary task slot.
        private _newPrimaryRef = if (_primaryObjId != "") then { _primaryKind + "_" + _primaryObjId } else { "" };
        private _oldPrimaryId = _state get "primaryTaskId";
        private _primaryNeedsPublish = ((_state get "primaryRef") != _newPrimaryRef) || {[_oldPrimaryId] call _fnc_taskMissing};
        if (_primaryNeedsPublish) then {
            [_oldPrimaryId] call _fnc_deleteTaskIfPresent;
            [_state] call _fnc_clearPrimaryTaskState;

            if (_newPrimaryRef != "" && {!isNil "_primaryData"}) then {
                private _newPrimaryId = [_activeSide, "PRIMARY", _primaryKind, _primaryObjId, _primaryData] call _fnc_publishTask;
                _state set ["primaryTaskId", _newPrimaryId];
                _state set ["primaryRef", _newPrimaryRef];
                _state set ["primaryKind", _primaryKind];
                _state set ["primaryObjId", _primaryObjId];
                ["GTN_TASKS", 3, format["Assigned primary task %1 (%2)", _newPrimaryRef, _newPrimaryId]] call FLO_fnc_log;
            };
        };

        // Update secondary task slot.
        private _newSecondaryRef = if (_secondaryObjId != "") then { _secondaryKind + "_" + _secondaryObjId } else { "" };
        private _oldSecondaryId = _state get "secondaryTaskId";
        private _secondaryNeedsPublish = ((_state get "secondaryRef") != _newSecondaryRef) || {[_oldSecondaryId] call _fnc_taskMissing};
        if (_secondaryNeedsPublish) then {
            [_oldSecondaryId] call _fnc_deleteTaskIfPresent;
            [_state] call _fnc_clearSecondaryTaskState;

            if (_newSecondaryRef != "" && {!isNil "_secondaryData"}) then {
                private _markedTargets = if (_secondaryKind isEqualTo "destroy") then {
                    [_secondaryData, _enemySide] call _fnc_collectDestroyTargets
                } else {
                    []
                };

                if ((_secondaryKind != "destroy") || {(count _markedTargets) > 0}) then {
                    _secondaryMeta set ["targetCount", count _markedTargets];
                    private _newSecondaryId = [_activeSide, "SECONDARY", _secondaryKind, _secondaryObjId, _secondaryData, _secondaryMeta] call _fnc_publishTask;
                    _state set ["secondaryTaskId", _newSecondaryId];
                    _state set ["secondaryRef", _newSecondaryRef];
                    _state set ["secondaryKind", _secondaryKind];
                    _state set ["secondaryObjId", _secondaryObjId];
                    _state set ["secondaryTargets", _markedTargets];
                    ["GTN_TASKS", 3, format["Assigned secondary task %1 (%2, targets=%3)", _newSecondaryRef, _newSecondaryId, count _markedTargets]] call FLO_fnc_log;
                };
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
