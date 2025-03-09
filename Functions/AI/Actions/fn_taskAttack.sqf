/* ----------------------------------------------------------------------------
Function: FLO_fnc_taskAttack

Description:
    A function for a group to attack a parsed location.
    Uses the search and destroy (SAD) waypoint type to actively seek and engage enemies.

Parameters:
    - Group (Group or Object)
    - Position (XYZ, Object, Location or Group)

Optional:
    - Search Radius (Scalar)
    - Remove Assigned Waypoints (Bool)

Example:
    (begin example)
    [_group, getPos (player findNearestEnemy player), 100] call FLO_fnc_taskAttack
    (end)

Returns:
    None

Author:
    Rommel, modified by Azraeelian Angel
---------------------------------------------------------------------------- */

params ["_group", "_position", ["_radius", -1], ["_override", false]];

// Allow TaskAttack to override other set waypoints
if (_override) then {
    [_group] call CBA_fnc_clearWaypoints;
    {
        _x enableAI "PATH";
    } forEach units _group;
};

[_group, [_position,0,10,10,0,0,0,[],[_position getpos [_radius/2,random 360],[]]] call BIS_fnc_findSafePos, _radius, "SAD", "COMBAT", "RED", "FULL", "LINE"] call FLO_fnc_addWaypoint; 