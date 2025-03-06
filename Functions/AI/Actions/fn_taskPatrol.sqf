/* ----------------------------------------------------------------------------
Function: FLO_fnc_taskPatrol

Description:
    A function for a group to randomly patrol a parsed radius and location.
    Creates multiple waypoints in random directions with varying distances to create
    a patrol pattern.

Parameters:
    - Group (Group or Object)

Optional:
    - Position (XYZ, Object, Location or Group)
    - Radius (Scalar)
    - Waypoint Count (Scalar)
    - Waypoint Type (String)
    - Behaviour (String)
    - Combat Mode (String)
    - Speed Mode (String)
    - Formation (String)
    - Code To Execute at Each Waypoint (String)
    - TimeOut at each Waypoint (Array [Min, Med, Max])

Example:
    (begin example)
    [this, getMarkerPos "objective1", 50] call FLO_fnc_taskPatrol
    [this, this, 300, 7, "MOVE", "AWARE", "YELLOW", "FULL", "STAG COLUMN", "this call CBA_fnc_searchNearby", [3, 6, 9]] call FLO_fnc_taskPatrol;
    (end)

Returns:
    None

Author:
    Rommel, modified by Azraeelian Angel
---------------------------------------------------------------------------- */

params [
    ["_group", grpNull, [grpNull, objNull]],
    ["_position", [], [[], objNull, grpNull, locationNull], [2, 3]],
    ["_radius", 100, [0]],
    ["_count", 3, [0]],
    ["_wpType", "MOVE", [""]],
    ["_behaviour", "SAFE", [""]],
    ["_combatMode", "RED", [""]],
    ["_speed", "LIMITED", [""]],
    ["_formation", "STAG COLUMN", [""]],
    ["_code", "", [""]],
    ["_timeout", [0,0,0], [[]], 3]
];

// Enable AI pathing
{
    _x enableAI "PATH";
} forEach units _group;

// Can pass parameters straight through to addWaypoint
_this =+ _this;
_this set [2,-1];
if (count _this > 3) then {
    _this deleteAt 3;
};

// Create waypoints at different locations around the center position
for "_i" from 1 to _count do {
    // Find a safe position within the radius
    _this set [1, [_position,_radius/2,_radius,5,0,0,0,[],[_position getpos [_radius/2,random 360],[]]] call BIS_fnc_findSafePos];
    
    // Set waypoint parameters
    _this set [3, _wpType];
    _this set [4, _behaviour];
    _this set [5, _combatMode];
    _this set [6, _speed];
    _this set [7, _formation];
    _this set [8, _code];
    _this set [9, _timeout];
    
    _this call FLO_fnc_addWaypoint;
};

// Close the patrol loop
_this set [1, _position];
_this set [2, _radius];
_this call FLO_fnc_addWaypoint; 