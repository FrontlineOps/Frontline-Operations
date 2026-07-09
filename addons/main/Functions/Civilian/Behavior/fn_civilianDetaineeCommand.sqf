/*
 * Function: FLO_fnc_civilianDetaineeCommand
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-authoritative command handler for detained civilians.
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Arguments <ARRAY>
 *
 * Return Value:
 * BOOL - True when the command resolved
 */

params [
    ["_mode", "", [""]],
    ["_args", [], [[]]]
];

if (!isServer) exitWith {
    [_mode, _args] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
    false
};

private _records = FLO_CivilianManager get "_detentionRecords";
private _cooldown = FLO_CivilianConfig get "DETENTION_INTERROGATION_COOLDOWN_SECONDS";
private _penalty = FLO_CivilianConfig get "DETENTION_INTERROGATION_REPUTATION_PENALTY";
private _releaseBonus = FLO_CivilianConfig get "DETENTION_RELEASE_REPUTATION_BONUS";

switch (toUpper _mode) do {
    case "DETAIN": {
        _args params [["_unit", objNull, [objNull]], ["_caller", objNull, [objNull]]];
        if (isNull _unit || {isNull _caller} || {!alive _unit} || {!alive _caller} || {captive _unit}) exitWith { false };

        detach _unit;
        _unit setVariable ["FLO_isProtester", false, true];
        _unit setVariable ["FLO_ProtestExpiresAt", diag_tickTime - 1, false];
        _unit setVariable ["FLO_ProtestTarget", objNull, false];
        _unit disableAI "PATH";
        _unit disableAI "MOVE";
        _unit setCaptive true;
        _unit setDir ((_unit getDir _caller) + 180);
        _unit switchMove "AmovPercMstpSsurWnonDnon";
        removeAllWeapons _unit;
        removeBackpack _unit;

        private _objectiveId = _unit getVariable ["FLO_CivilianObjective", ""];
        if (_objectiveId == "") then {
            _objectiveId = [getPosATL _unit] call FLO_fnc_civilianResolveObjective;
        };
        private _record = createHashMapFromArray [
            ["objectiveId", _objectiveId],
            ["detainedBySide", side group _caller],
            ["detainedAt", diag_tickTime],
            ["lastInterrogatedAt", -1],
            ["escorting", false]
        ];

        _records set [netId _unit, _record];
        _unit setVariable ["FLO_CivilianDetained", true, true];
        _unit setVariable ["FLO_CivilianInterrogatedAt", -1, true];
        if (!isNil "FLO_virtualGroups") then {
            private _groupId = _unit getVariable ["FLO_VirtualGroupId", ""];
            private _groups = FLO_virtualGroups get "_groups";
            if (_groupId != "" && {_groupId in _groups}) then {
                private _groupData = _groups get _groupId;
                if ((_groupData get "civilianRoutineState") == "protest") then {
                    _groupData set ["civilianRoutineState", "return"];
                    _groupData set ["civilianRoutineUntil", diag_tickTime - 1];
                };
                (_groups get _groupId) set ["alwaysActive", true];
            };
        };
        [_unit] call FLO_fnc_civilianDetainActions;
        true
    };

    case "ESCORT": {
        _args params [["_unit", objNull, [objNull]], ["_caller", objNull, [objNull]]];
        if (isNull _unit || {isNull _caller} || {!alive _unit} || {!captive _unit}) exitWith { false };
        if !((netId _unit) in _records) exitWith { false };

        detach _unit;
        _unit attachTo [_caller, [0, 0.85, 0]];
        private _record = _records get (netId _unit);
        _record set ["escorting", true];
        true
    };

    case "HALT": {
        _args params [["_unit", objNull, [objNull]]];
        if (isNull _unit || {!alive _unit} || {!captive _unit}) exitWith { false };
        if !((netId _unit) in _records) exitWith { false };

        detach _unit;
        _unit disableAI "PATH";
        _unit disableAI "MOVE";
        doStop _unit;
        private _record = _records get (netId _unit);
        _record set ["escorting", false];
        true
    };

    case "LOAD": {
        _args params [["_unit", objNull, [objNull]], ["_caller", objNull, [objNull]]];
        if (isNull _unit || {isNull _caller} || {!alive _unit} || {!captive _unit}) exitWith { false };
        if !((netId _unit) in _records) exitWith { false };

        private _vehicles = nearestObjects [_caller, ["Air", "Ship", "LandVehicle"], 15];
        if (_vehicles isEqualTo []) exitWith { false };

        detach _unit;
        _unit moveInCargo (_vehicles select 0);
        private _vehicle = _vehicles select 0;
        if !(_vehicle getVariable ["FLO_DetaineeUnloadActionAdded", false]) then {
            [_vehicle, "DETAINEE_UNLOAD", [[
                "<img size=2 color='#7CC2FF' image='\z\flo\addons\main\Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Unload Detainees",
                {
                    params ["_target", "_caller"];
                    ["UNLOAD_ALL", [_target, _caller]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
                },
                nil, 0, true, true, "", "({side _x == civilian && captive _x && alive _x} count crew _target) > 0", 5, false, "", ""
            ]]] remoteExec ["FLO_fnc_configureObjectActionsLocal", 0, _vehicle];
            _vehicle setVariable ["FLO_DetaineeUnloadActionAdded", true, true];
        };

        private _record = _records get (netId _unit);
        _record set ["escorting", false];
        true
    };

    case "UNLOAD_ALL": {
        _args params [["_vehicle", objNull, [objNull]], ["_caller", objNull, [objNull]]];
        if (isNull _vehicle || {isNull _caller}) exitWith { false };

        {
            if (side _x != civilian || {!captive _x} || {!alive _x}) then { continue };
            unassignVehicle _x;
            moveOut _x;
            _x disableAI "PATH";
            _x disableAI "MOVE";
            _x switchMove "AmovPercMstpSsurWnonDnon";
        } forEach crew _vehicle;
        true
    };

    case "INTERROGATE": {
        _args params [["_unit", objNull, [objNull]], ["_caller", objNull, [objNull]]];
        if (isNull _unit || {isNull _caller} || {!alive _unit} || {!alive _caller} || {!captive _unit}) exitWith { false };

        private _recordKey = netId _unit;
        if !(_recordKey in _records) exitWith { false };
        private _record = _records get _recordKey;
        private _lastInterrogatedAt = _record get "lastInterrogatedAt";
        if (_lastInterrogatedAt >= 0 && {(diag_tickTime - _lastInterrogatedAt) < _cooldown}) exitWith {
            ["Civilian", "You already pressed for everything this one knows."] remoteExec ["BIS_fnc_showSubtitle", owner _caller, false];
            false
        };

        private _groups = FLO_virtualGroups get "_groups";
        private _groupId = _unit getVariable ["FLO_VirtualGroupId", ""];
        private _groupData = if (_groupId != "" && {_groupId in _groups}) then { _groups get _groupId } else { createHashMap };
        private _objectiveId = if ((keys _groupData) isNotEqualTo []) then { _groupData get "civilianObjective" } else { _record get "objectiveId" };
        private _role = if ((keys _groupData) isNotEqualTo []) then { _groupData get "civilianRole" } else { _unit getVariable ["FLO_CivilianRole", "resident"] };
        private _callerSide = side group _caller;
        if !(_callerSide in [east, west]) then {
            _callerSide = FLO_ActivePlayerSide;
        };
        if !(_callerSide in [east, west]) exitWith { false };

        private _context = FLO_CivilianManager call ["getObjectiveContext", [_objectiveId, _role, _callerSide]];
        private _memory = [
            FLO_CivilianManager get "_objectiveMemories",
            _objectiveId,
            _role,
            diag_tickTime
        ] call FLO_fnc_civilianSelectObjectiveMemory;

        private _package = if ((keys _memory) isNotEqualTo []) then {
            [_memory, _callerSide, _role] call FLO_fnc_civilianBuildIntelPackageFromMemory
        } else {
            [getPosATL _unit, _objectiveId, _callerSide, _role, 1.1] call FLO_fnc_civilianBuildIntelPackage
        };

        _record set ["lastInterrogatedAt", diag_tickTime];
        _unit setVariable ["FLO_CivilianInterrogatedAt", diag_tickTime, true];

        private _cooperateChance = switch (_context get "disposition") do {
            case "FRIENDLY": { 0.85 };
            case "NEUTRAL": { 0.65 };
            case "WARY": { 0.45 };
            default { 0.25 };
        };

        if ((random 1) > _cooperateChance || {(keys _package) isEqualTo []}) exitWith {
            if ((_context get "disposition") in ["FRIENDLY", "NEUTRAL"]) then {
                [_penalty, "decrease"] call FLO_fnc_adjustReputation;
            };
            ["Civilian", selectRandom [
                "I told you nothing.",
                "You are getting nothing useful from me.",
                "I have nothing else to give you."
            ]] remoteExec ["BIS_fnc_showSubtitle", owner _caller, false];
            false
        };

        if ((_context get "disposition") in ["FRIENDLY", "NEUTRAL"]) then {
            [_penalty, "decrease"] call FLO_fnc_adjustReputation;
        };

        [_package] call FLO_fnc_gtnAlertCivilianReport;
        ["Civilian", [_package] call FLO_fnc_civilianBuildIntelSubtitle] remoteExec ["BIS_fnc_showSubtitle", owner _caller, false];
        true
    };

    case "RELEASE": {
        _args params [["_unit", objNull, [objNull]], ["_caller", objNull, [objNull]]];
        if (isNull _unit || {!alive _unit} || {!captive _unit}) exitWith { false };

        detach _unit;
        unassignVehicle _unit;
        moveOut _unit;
        _unit enableAI "PATH";
        _unit enableAI "MOVE";
        _unit setCaptive false;
        _unit switchMove "";
        _unit setVariable ["FLO_CivilianDetained", false, true];

        private _recordKey = netId _unit;
        private _objectiveId = if (_recordKey in _records) then { (_records get _recordKey) get "objectiveId" } else { "" };
        if (_recordKey in _records) then {
            _records deleteAt _recordKey;
        };

        if (_objectiveId != "") then {
            private _callerSide = side group _caller;
            if !(_callerSide in [east, west]) then {
                _callerSide = FLO_ActivePlayerSide;
            };
            if (_callerSide in [east, west]) then {
                private _context = FLO_CivilianManager call ["getObjectiveContext", [_objectiveId, _unit getVariable ["FLO_CivilianRole", "resident"], _callerSide]];
                if ((_context get "disposition") in ["FRIENDLY", "NEUTRAL"]) then {
                    [_releaseBonus, "increase"] call FLO_fnc_adjustReputation;
                };
            };
        };

        if (!isNil "FLO_virtualGroups") then {
            private _groupId = _unit getVariable ["FLO_VirtualGroupId", ""];
            private _groups = FLO_virtualGroups get "_groups";
            if (_groupId != "" && {_groupId in _groups}) then {
                (_groups get _groupId) set ["alwaysActive", false];
            };
        };

        [[_unit]] call FLO_fnc_civilianActions;
        true
    };
};

false
