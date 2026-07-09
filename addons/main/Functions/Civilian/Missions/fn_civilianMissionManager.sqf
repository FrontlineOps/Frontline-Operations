/*
 * Function: FLO_fnc_civilianMissionManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-authoritative civilian mission state manager.
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Arguments <ARRAY>
 *
 * Return Value:
 * HASHMAP | BOOL
 */

params [
    ["_mode", "", [""]],
    ["_args", [], [[]]]
];

private _modeKey = toUpper _mode;
if (!isServer && {_modeKey in ["INIT", "REQUEST_MISSION", "MISSION_COMPLETE", "MISSION_FAILED"]}) exitWith {
    [_mode, _args] remoteExecCall ["FLO_fnc_civilianMissionManager", 2, false];
    createHashMap
};

if (isNil "FLO_CivilianManager") exitWith { createHashMap };

private _missionState = FLO_CivilianManager get "_missionState";
private _resetPairs = [
    ["active", false],
    ["id", ""],
    ["type", ""],
    ["objectiveId", ""],
    ["briefing", ""],
    ["requestedByUid", ""],
    ["requestedByName", ""],
    ["startedAt", -1],
    ["taskId", ""],
    ["position", []],
    ["offer", createHashMap]
];

switch (_modeKey) do {
    case "INIT": {
        {
            _missionState set [_x select 0, _x select 1];
        } forEach _resetPairs;
        FLO_CivilianMission_Active = false;
        true
    };

    case "GET_STATE": {
        _missionState
    };

    case "REQUEST_MISSION": {
        _args params [["_civilian", objNull, [objNull]], ["_caller", objNull, [objNull]]];
        if ((_missionState get "active")) exitWith {
            createHashMapFromArray [
                ["status", "BUSY"],
                ["line", "Someone else already asked for help. Deal with that first."]
            ]
        };

        private _groups = FLO_virtualGroups get "_groups";
        private _groupId = _civilian getVariable ["FLO_VirtualGroupId", ""];
        private _groupData = if (_groupId != "" && {_groupId in _groups}) then { _groups get _groupId } else { createHashMap };

        private _offer = [_civilian, _caller, _groupData] call FLO_fnc_civilianBuildMissionOffer;
        if ((keys _offer) isEqualTo []) exitWith {
            createHashMapFromArray [
                ["status", "REFUSED"],
                ["line", selectRandom [
                    "Not now. People are keeping their heads down.",
                    "I cannot ask that of you here.",
                    "This is not the right place to start something like that."
                ]]
            ]
        };

        private _functionName = format ["FLO_fnc_%1", _offer get "templateFunction"];
        if (isNil _functionName) exitWith {
            createHashMapFromArray [
                ["status", "FAILED"],
                ["line", "I do not know who can help with that right now."]
            ]
        };

        private _template = missionNamespace getVariable _functionName;
        private _result = [_offer] call _template;
        if ((keys _result) isEqualTo []) exitWith {
            createHashMapFromArray [
                ["status", "FAILED"],
                ["line", "The problem moved before we could act on it."]
            ]
        };

        _missionState set ["active", true];
        _missionState set ["id", _offer get "missionId"];
        _missionState set ["type", _offer get "missionType"];
        _missionState set ["objectiveId", _offer get "targetObjectiveId"];
        _missionState set ["briefing", _offer get "briefing"];
        _missionState set ["requestedByUid", getPlayerUID _caller];
        _missionState set ["requestedByName", name _caller];
        _missionState set ["startedAt", diag_tickTime];
        _missionState set ["taskId", _result get "taskId"];
        _missionState set ["position", _result get "position"];
        _missionState set ["offer", _offer];
        FLO_CivilianMission_Active = true;

        ["CIV_MISSION", 2, format [
            "Started civilian mission %1 for objective %2",
            _offer get "missionType",
            _offer get "targetObjectiveId"
        ]] call FLO_fnc_log;

        createHashMapFromArray [
            ["status", "STARTED"],
            ["line", _offer get "requestLine"],
            ["taskId", _result get "taskId"]
        ]
    };

    case "MISSION_COMPLETE";
    case "MISSION_FAILED": {
        private _wasActive = _missionState get "active";
        {
            _missionState set [_x select 0, _x select 1];
        } forEach _resetPairs;
        FLO_CivilianMission_Active = false;

        if (_wasActive) then {
            ["CIV_MISSION", 2, format ["Civilian mission resolved with state %1", _modeKey]] call FLO_fnc_log;
        };

        true
    };
};

createHashMap
