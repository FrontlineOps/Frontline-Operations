/* Validates canonical commander-order semantics shared by live and saved groups. */
params [
    ["_groupData", createHashMap, [createHashMap]],
    ["_groupId", "", [""]]
];

private _order = _groupData get "commanderOrder";
if !(_order in ["", "MOVE", "ATTACK", "DEFEND", "GARRISON"]) then {
    throw format ["Virtual group %1 has unsupported commander order %2", _groupId, _order];
};
if (_order == "ATTACK") exitWith {
    if ((_groupData get "attackObjective") == "") then {
        throw format ["Virtual ATTACK group %1 has no objective", _groupId];
    };
    if ((_groupData get "waypoints") isEqualTo []) then {
        throw format ["Virtual ATTACK group %1 has no route", _groupId];
    };
    true
};
if (_order != "GARRISON") exitWith { true };

private _objectiveId = _groupData get "garrisonObjective";
private _position = _groupData get "garrisonPosition";
private _mode = _groupData get "orderMode";
private _waypoints = _groupData get "waypoints";
if (_objectiveId == "" || {count _position < 2}) then {
    throw format ["Virtual garrison %1 has incomplete objective/position state", _groupId];
};
if !(_mode in ["GARRISON_BUILDING", "GARRISON_PATROL"]) then {
    throw format ["Virtual garrison %1 has invalid route mode %2", _groupId, _mode];
};
if (_waypoints isEqualTo []) then {
    throw format ["Virtual garrison %1 has no route", _groupId];
};

private _lastWaypointType = toUpper ((_waypoints select -1) select 1);
if (_mode == "GARRISON_BUILDING" && {_lastWaypointType != "HOLD"}) then {
    throw format ["Building garrison %1 route ends in %2 instead of HOLD", _groupId, _lastWaypointType];
};
if (_mode == "GARRISON_PATROL" && {count _waypoints < 4 || {_lastWaypointType != "CYCLE"}}) then {
    throw format ["Patrol garrison %1 has invalid cyclic route", _groupId];
};

true
