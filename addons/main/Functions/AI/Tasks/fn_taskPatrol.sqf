/*
 * Function: FLO_fnc_taskPatrol
 * Author: Adapted from LAMBS Danger (nkenny) for FLO virtualization
 * Description:
 *   Creates a looping patrol pattern WITHOUT using CYCLE waypoints.
 *   Uses waypoint statements to reset currentWaypoint back to first.
 *   Compatible with virtualization - stores config in group variables.
 *
 * Arguments:
 * 0: Group <GROUP>
 * 1: Center position <ARRAY>
 * 2: Patrol radius <NUMBER> (default: 200)
 * 3: Waypoint count <NUMBER> (default: 4)
 * 4: Behavior <STRING> (default: "AWARE")
 * 5: Speed <STRING> (default: "LIMITED")
 * 6: Movement domain <STRING> (default: "LAND")
 *
 * Return Value:
 * Success <BOOL>
 *
 * Example:
 * [_group, getPos player, 300, 5] call FLO_fnc_taskPatrol;
 */

params [
    ["_group", grpNull, [grpNull]],
    ["_pos", [], [[]]],
    ["_radius", 200, [0]],
    ["_waypointCount", 4, [0]],
    ["_behavior", "AWARE", [""]],
    ["_speed", "LIMITED", [""]],
    ["_movementDomain", "LAND", [""]]
];

if (isNull _group) then { throw "FLO_fnc_taskPatrol: group is null"; };
private _leader = leader _group;
if (isNull _leader) then { throw "FLO_fnc_taskPatrol: group has no leader"; };
if (_pos isEqualTo []) then { _pos = getPosATL _leader; };
if (!(count _pos in [2, 3]) || {_pos findIf {!(_x isEqualType 0)} >= 0}) then {
    throw format ["FLO_fnc_taskPatrol: invalid center position %1", _pos];
};
if (_radius < 0) then {
    throw format ["FLO_fnc_taskPatrol: invalid patrol radius %1", _radius];
};
if (_waypointCount < 1 || {_waypointCount != floor _waypointCount}) then {
    throw format ["FLO_fnc_taskPatrol: invalid waypoint count %1", _waypointCount];
};
if !(_movementDomain in ["LAND", "AIR", "WATER"]) then {
    throw format ["FLO_fnc_taskPatrol: invalid movement domain %1", _movementDomain];
};

private _formation = selectRandom ["STAG COLUMN", "WEDGE", "VEE", "DIAMOND"];
private _semanticWaypoints = [];

// Generate waypoints spread around center
for "_i" from 0 to (_waypointCount - 1) do {
    // Random position within radius
    private _angle = (_i * (360 / _waypointCount)) + (random 60 - 30);
    private _dist = _radius * (0.5 + random 0.5);
    private _wpPos = _pos getPos [_dist, _angle];
    
    if (_movementDomain == "LAND" && {surfaceIsWater _wpPos}) then { _wpPos = _pos; };
    _semanticWaypoints pushBack [_wpPos, "MOVE", _behavior, _speed, _formation, "YELLOW", 15];
};

if !([
    _group,
    _semanticWaypoints,
    _movementDomain,
    "TASK_PATROL",
    true,
    true,
    [8, 12, 20]
] call FLO_fnc_taskApplyRoute) exitWith { false };

_group setBehaviour _behavior;
_group setSpeedMode _speed;
_group setCombatMode "YELLOW";
_group setFormation _formation;
_group setVariable ["FLO_patrolConfig", [_pos, _radius, _waypointCount, _behavior, _speed], true];

["VIRTUALIZATION", 5, format["TaskPatrol assigned to %1: center %2, radius %3, %4 waypoints", _group, _pos, _radius, _waypointCount]] call FLO_fnc_log;

true

