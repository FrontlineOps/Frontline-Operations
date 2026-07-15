/*
 * Function: FLO_fnc_virtualizationValidateWaypointState
 * Description:
 *   Validates canonical route descriptors and persisted route indices without
 *   repeating terrain sampling in ordinary registry validation.
 */

params [
    ["_groupId", "", [""]],
    ["_waypoints", [], [[]]],
    ["_currentWaypointIndex", 0, [0]],
    ["_dismountAtWaypoint", -1, [0]],
    ["_pathToken", -1, [0]],
    ["_pathTargetPos", [], [[]]],
    ["_pathWaypointSettings", [], [[]]]
];

if (_currentWaypointIndex != floor _currentWaypointIndex) then {
    throw format ["Virtual group %1 has a fractional waypoint index %2", _groupId, _currentWaypointIndex];
};
if (_dismountAtWaypoint != floor _dismountAtWaypoint) then {
    throw format ["Virtual group %1 has a fractional dismount index %2", _groupId, _dismountAtWaypoint];
};

private _waypointCount = count _waypoints;
if ((_waypointCount == 0 && {_currentWaypointIndex != 0})
    || {_waypointCount > 0 && {_currentWaypointIndex < 0 || {_currentWaypointIndex >= _waypointCount}}}) then {
    throw format ["Virtual group %1 has invalid waypoint index %2/%3", _groupId, _currentWaypointIndex, _waypointCount];
};
if (_dismountAtWaypoint < -1 || {_dismountAtWaypoint >= _waypointCount}) then {
    throw format ["Virtual group %1 has invalid dismount index %2/%3", _groupId, _dismountAtWaypoint, _waypointCount];
};

private _cycleIndex = -1;
{
    private _waypointIndex = _forEachIndex;
    if (!(_x isEqualType []) || {count _x != 7}) then {
        throw format ["Virtual group %1 waypoint %2 is not a canonical seven-field descriptor", _groupId, _waypointIndex];
    };
    private _waypointPos = _x select 0;
    if (!(_waypointPos isEqualType [])
        || {!(count _waypointPos in [2, 3])}
        || {_waypointPos findIf { !(_x isEqualType 0) } >= 0}) then {
        throw format ["Virtual group %1 waypoint %2 has an invalid position", _groupId, _waypointIndex];
    };
    {
        if !(_x isEqualType "") then {
            throw format ["Virtual group %1 waypoint %2 setting %3 is not text", _groupId, _waypointIndex, _forEachIndex + 1];
        };
    } forEach (_x select [1, 5]);
    if (!((_x select 6) isEqualType 0) || {(_x select 6) < 0}) then {
        throw format ["Virtual group %1 waypoint %2 has invalid completion radius %3", _groupId, _waypointIndex, _x select 6];
    };
    if (toUpper (_x select 1) == "CYCLE") then {
        if (_cycleIndex >= 0) then {
            throw format ["Virtual group %1 has multiple CYCLE waypoints", _groupId];
        };
        _cycleIndex = _waypointIndex;
    };
} forEach _waypoints;

if (_cycleIndex >= 0 && {_waypointCount < 2 || {_cycleIndex != (_waypointCount - 1)}}) then {
    throw format ["Virtual group %1 has malformed CYCLE topology at %2/%3", _groupId, _cycleIndex, _waypointCount];
};

if (_pathToken >= 0 || {_pathTargetPos isNotEqualTo []} || {_pathWaypointSettings isNotEqualTo []}) then {
    throw format ["Virtual group %1 retains obsolete pending path state", _groupId];
};

true
