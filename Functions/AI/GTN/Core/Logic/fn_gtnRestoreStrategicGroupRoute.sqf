/*
 * Function: FLO_fnc_gtnRestoreStrategicGroupRoute
 * Author: Frontline Operations Development Group
 * Description:
 *   Restores a group's normal strategic GTN route after a temporary tactical
 *   engagement overlay ends.
 *
 * Arguments:
 * 0: GTN commander <HASHMAP>
 * 1: Group ID <STRING>
 * 2: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when a strategic route was restored or no restore was needed
 */

params ["_gtnCommander", "_groupId", "_groupData"];

[_groupData] call FLO_fnc_virtualizationClearEngagementState;

private _order = _groupData get "commanderOrder";
switch (_order) do {
    case "ATTACK": {
        private _objectiveId = _groupData get "attackObjective";
        private _targetPos = _groupData get "orderTargetPos";
        if (count _targetPos < 2 && {_objectiveId != ""}) then {
            _targetPos = (FLO_Objectives get _objectiveId) get "position";
        };
        if !(count _targetPos >= 2) exitWith { false };
        _gtnCommander call ["_orderGroupAttack", [_groupId, _targetPos, _objectiveId]]
    };

    case "DEFEND": {
        private _objectiveId = _groupData get "defendObjective";
        private _targetPos = _groupData get "orderTargetPos";
        if !(count _targetPos >= 2) exitWith { false };
        _gtnCommander call ["_orderGroupDefend", [_groupId, _targetPos, _objectiveId]]
    };

    case "GARRISON": {
        private _objectiveId = _groupData get "garrisonObjective";
        private _targetPos = _groupData get "garrisonPosition";
        if (count _targetPos < 2) then {
            _targetPos = _groupData get "orderTargetPos";
        };
        if !(count _targetPos >= 2) exitWith { false };
        _gtnCommander call ["_orderGroupGarrison", [_groupId, _targetPos, _objectiveId]]
    };

    case "MOVE": {
        private _targetPos = _groupData get "orderTargetPos";
        if !(count _targetPos >= 2) exitWith { false };
        _gtnCommander call ["_orderGroupMove", [_groupId, _targetPos, _groupData get "orderMode"]]
    };

    default {
        true
    };
}
