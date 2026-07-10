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
        private _campaignOperationId = _groupData get "campaignOperationId";
        private _director = _gtnCommander get "_campaignDirector";
        if (isNil "_director") then {
            throw "FLO_fnc_gtnRestoreStrategicGroupRoute: commander has no campaign director";
        };

        private _campaign = _director call ["_getState", []];
        private _operations = _campaign get "operations";
        private _validOperationRoute = false;
        if (_campaignOperationId in _operations) then {
            private _operation = _operations get _campaignOperationId;
            _validOperationRoute = (_operation get "phase") == "ASSAULT"
                && {(_operation get "attackerSideKey") == (_gtnCommander get "_sideKey")}
                && {(_operation get "objectiveId") == _objectiveId}
                && {_objectiveId != ""}
                && {_objectiveId in FLO_Objectives}
                && {((FLO_Objectives get _objectiveId) get "owner") == (_gtnCommander get "_enemySide")};
        };

        if (!_validOperationRoute) exitWith {
            [_groupId, [], false, true, "GTN_OPERATION_EXPIRED"] call FLO_fnc_updateVirtualGroupWaypoints;
            _gtnCommander call ["_releaseGroups", [[_groupId], ""]];
            true
        };

        private _targetPos = _groupData get "orderTargetPos";
        if (count _targetPos < 2 && {_objectiveId != ""}) then {
            _targetPos = (FLO_Objectives get _objectiveId) get "position";
        };
        if ((count _targetPos) < 2) exitWith { false };
        _gtnCommander call ["_orderGroupAttack", [_groupId, _targetPos, _objectiveId, false, _campaignOperationId]]
    };

    case "DEFEND": {
        private _objectiveId = _groupData get "defendObjective";
        private _targetPos = _groupData get "orderTargetPos";
        if ((count _targetPos) < 2) exitWith { false };
        _gtnCommander call ["_orderGroupDefend", [_groupId, _targetPos, _objectiveId]]
    };

    case "GARRISON": {
        private _objectiveId = _groupData get "garrisonObjective";
        private _targetPos = _groupData get "garrisonPosition";
        if (count _targetPos < 2) then {
            _targetPos = _groupData get "orderTargetPos";
        };
        if ((count _targetPos) < 2) exitWith { false };
        _gtnCommander call ["_orderGroupGarrison", [_groupId, _targetPos, _objectiveId]]
    };

    case "MOVE": {
        private _targetPos = _groupData get "orderTargetPos";
        if ((count _targetPos) < 2) exitWith { false };
        _gtnCommander call ["_orderGroupMove", [_groupId, _targetPos, _groupData get "orderMode"]]
    };

    default {
        true
    };
}
