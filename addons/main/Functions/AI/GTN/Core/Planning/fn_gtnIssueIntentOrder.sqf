/* Canonical routing and durable ownership commit at one unscheduled boundary. */
params ["_commander", "_intent", "_groupId", "_order", "_position"];
private _group = (call FLO_fnc_virtualizationGetGroupMap) get _groupId;
if ((_group get "commanderIntent") != (_intent get "id")) exitWith { false };
private _accepted = false;
isNil {
    switch (_order) do {
        case "MOVE": {
            if (_commander call ["_consumeStrategicOrderBudget", ["MOVE"]]) then {
                _accepted = _commander call ["_orderGroupMove", [_groupId, _position]];
                if (!_accepted) then { _commander call ["_refundStrategicOrderBudget", ["MOVE"]] };
            };
        };
        case "ATTACK": { _accepted = _commander call ["_orderGroupAttack", [_groupId, _position, _intent get "objectiveId", true]] };
        case "DEFEND": { _accepted = _commander call ["_orderGroupDefend", [_groupId, _position, _intent get "objectiveId", true, true]] };
        case "GARRISON": {
            private _cache = _commander get "_objectiveAssignmentCache";
            private _objectiveId = _intent get "objectiveId";
            private _positions = (_cache get "garrisonPositionsByObjective") getOrDefault [_objectiveId, []];
            private _slot = (_cache get "garrisonCounts") getOrDefault [_objectiveId, 0];
            private _route = [_commander, _objectiveId, _positions, _slot, _group get "groupType"] call FLO_fnc_gtnBuildObjectiveGarrisonRoute;
            if (count _route == 0) exitWith {
                ["GTN", 4, format ["Rejected garrison order objective=%1 reason=NO_LAND_POSITION", _objectiveId]] call FLO_fnc_log;
            };
            _accepted = _commander call ["_orderGroupGarrison", [_groupId, _route, _objectiveId, true]];
        };
        default { throw format ["GTN unsupported intent order %1", _order] };
    };
    // A rejected route retains the reservation so the intent owner can cancel it.
    _group set ["commanderIntent", _intent get "id"];
    if (_accepted) then { (_intent get "issued") pushBackUnique _groupId };
};
[_commander get "_worldState", _groupId, _group] call FLO_fnc_gtnObserveOwnGroup;
_accepted
