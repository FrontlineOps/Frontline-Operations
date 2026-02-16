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

private _fnc_taskTypeFromKind = {
    params ["_kind"];
    switch (_kind) do {
        case "capture": { "Attack" };
        case "defend": { "Defend" };
        case "destroy": { "Destroy" };
        default { "Attack" };
    }
};

private _fnc_taskTitle = {
    params ["_kind", "_objId", "_objData"];
    private _name = _objData get "name";
    switch (_kind) do {
        case "capture": { format ["Capture %1", _name] };
        case "defend": { format ["Defend %1", _name] };
        case "destroy": { format ["Destroy enemy assets at %1", _name] };
        default { format ["Operate at %1", _name] };
    }
};

private _fnc_taskDesc = {
    params ["_kind", "_objId", "_objData"];
    private _name = _objData get "name";
    switch (_kind) do {
        case "capture": { format ["Commander objective: capture %1 and hold the area.", _name] };
        case "defend": { format ["Commander objective: defend %1 against enemy pressure.", _name] };
        case "destroy": { format ["Commander objective: destroy hostile assets around %1.", _name] };
        default { format ["Commander objective: operate near %1.", _name] };
    }
};

private _fnc_deleteTaskIfPresent = {
    params ["_taskId"];
    if (_taskId isEqualTo "") exitWith {};
    [_taskId] call BIS_fnc_deleteTask;
};

private _fnc_publishTask = {
    params ["_ownerSide", "_slotPrefix", "_kind", "_objId", "_objData"];

    private _taskId = format ["FLO_GTN_%1_%2_%3", _slotPrefix, _kind, _objId];
    private _title = [_kind, _objId, _objData] call _fnc_taskTitle;
    private _desc = [_kind, _objId, _objData] call _fnc_taskDesc;
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

[ _interval, _fnc_sideKey, _fnc_enemySide, _fnc_taskTypeFromKind, _fnc_taskTitle, _fnc_taskDesc, _fnc_deleteTaskIfPresent, _fnc_publishTask ] spawn {
    params [
        "_interval",
        "_fnc_sideKey",
        "_fnc_enemySide",
        "_fnc_taskTypeFromKind",
        "_fnc_taskTitle",
        "_fnc_taskDesc",
        "_fnc_deleteTaskIfPresent",
        "_fnc_publishTask"
    ];

    while {FLO_GTN_PlayerTaskBridgeRunning} do {
        if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) then {
            sleep _interval;
            continue;
        };

        private _activeSide = FLO_ActivePlayerSide;
        if !(_activeSide in [east, west]) then {
            sleep _interval;
            continue;
        };

        private _enemySide = [_activeSide] call _fnc_enemySide;
        private _stateKey = [_activeSide] call _fnc_sideKey;

        private _state = FLO_GTN_PlayerTasks get _stateKey;
        if (isNil "_state") then {
            _state = createHashMapFromArray [
                ["primaryTaskId", ""],
                ["secondaryTaskId", ""],
                ["primaryRef", ""],
                ["secondaryRef", ""]
            ];
            FLO_GTN_PlayerTasks set [_stateKey, _state];
        };

        private _captureCandidates = [];
        private _defendCandidates = [];

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
            };

            if (_owner isEqualTo _activeSide && {_enemyCount > 0 || {_enemyCount > _friendlyCount}}) then {
                _defendCandidates pushBack [_objId, (_enemyCount * 10) + _priority, _objData];
            };
        } forEach (keys FLO_Objectives);

        _captureCandidates = [_captureCandidates, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;
        _defendCandidates = [_defendCandidates, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;

        private _primaryKind = "";
        private _primaryObjId = "";
        private _primaryData = nil;

        if (count _defendCandidates > 0) then {
            (_defendCandidates select 0) params ["_primaryObjId", "_score", "_primaryData"];
            _primaryKind = "defend";
        } else {
            if (count _captureCandidates > 0) then {
                (_captureCandidates select 0) params ["_primaryObjId", "_score", "_primaryData"];
                _primaryKind = "capture";
            };
        };

        private _secondaryKind = "";
        private _secondaryObjId = "";
        private _secondaryData = nil;

        // Secondary is always destroy, and should not duplicate primary objective.
        {
            _x params ["_objId", "_score", "_objData"];
            if (_objId != _primaryObjId) exitWith {
                _secondaryKind = "destroy";
                _secondaryObjId = _objId;
                _secondaryData = _objData;
            };
        } forEach _captureCandidates;

        // Update primary task slot.
        private _newPrimaryRef = if (_primaryObjId != "") then { _primaryKind + "_" + _primaryObjId } else { "" };
        if ((_state get "primaryRef") != _newPrimaryRef) then {
            private _oldPrimaryId = _state get "primaryTaskId";
            [_oldPrimaryId] call _fnc_deleteTaskIfPresent;
            _state set ["primaryTaskId", ""];
            _state set ["primaryRef", ""];

            if (_newPrimaryRef != "" && {!isNil "_primaryData"}) then {
                private _newPrimaryId = [_activeSide, "PRIMARY", _primaryKind, _primaryObjId, _primaryData] call _fnc_publishTask;
                _state set ["primaryTaskId", _newPrimaryId];
                _state set ["primaryRef", _newPrimaryRef];
            };
        };

        // Update secondary task slot.
        private _newSecondaryRef = if (_secondaryObjId != "") then { _secondaryKind + "_" + _secondaryObjId } else { "" };
        if ((_state get "secondaryRef") != _newSecondaryRef) then {
            private _oldSecondaryId = _state get "secondaryTaskId";
            [_oldSecondaryId] call _fnc_deleteTaskIfPresent;
            _state set ["secondaryTaskId", ""];
            _state set ["secondaryRef", ""];

            if (_newSecondaryRef != "" && {!isNil "_secondaryData"}) then {
                private _newSecondaryId = [_activeSide, "SECONDARY", _secondaryKind, _secondaryObjId, _secondaryData] call _fnc_publishTask;
                _state set ["secondaryTaskId", _newSecondaryId];
                _state set ["secondaryRef", _newSecondaryRef];
            };
        };

        FLO_GTN_PlayerTasks set [_stateKey, _state];
        sleep _interval;
    };
};

["GTN_TASKS", 2, format["Player task bridge started (%1s interval)", _interval]] call FLO_fnc_log;

true
