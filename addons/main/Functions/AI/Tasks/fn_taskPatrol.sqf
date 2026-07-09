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
    ["_speed", "LIMITED", [""]]
];

if (isNull _group) exitWith { false };
if (_pos isEqualTo []) then { _pos = getPos (leader _group); };

// Clear existing waypoints
[_group] call CBA_fnc_clearWaypoints;

// Set group behavior
_group setBehaviour _behavior;
_group setSpeedMode _speed;
_group setCombatMode "YELLOW";
_group setFormation selectRandom ["STAG COLUMN", "WEDGE", "VEE", "DIAMOND"];

// Store patrol config for virtualization
_group setVariable ["FLO_patrolConfig", [_pos, _radius, _waypointCount, _behavior, _speed], true];

private _firstWpIdx = 0;

// Generate waypoints spread around center
for "_i" from 0 to (_waypointCount - 1) do {
    // Random position within radius
    private _angle = (_i * (360 / _waypointCount)) + (random 60 - 30);
    private _dist = _radius * (0.5 + random 0.5);
    private _wpPos = _pos getPos [_dist, _angle];
    
    // Ensure on land
    if (surfaceIsWater _wpPos) then { _wpPos = _pos; };
    
    private _wp = _group addWaypoint [_wpPos, 10];
    _wp setWaypointType "MOVE";
    _wp setWaypointBehaviour _behavior;
    _wp setWaypointSpeed _speed;
    _wp setWaypointTimeout [8, 12, 20];
    _wp setWaypointCompletionRadius 15;
    
    if (_i == 0) then {
        _firstWpIdx = _wp select 1;
    };
};

// Set the LAST waypoint to loop back to the first via setCurrentWaypoint
private _lastWp = [_group, (count waypoints _group) - 1];
_lastWp setWaypointStatements [
    "true",
    format ["(group this) setCurrentWaypoint [(group this), %1];", _firstWpIdx]
];

["VIRTUALIZATION", 3, format["TaskPatrol assigned to %1: center %2, radius %3, %4 waypoints", _group, _pos, _radius, _waypointCount]] call FLO_fnc_log;

true

