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
    - TimeOut at each Waypoint (Array [Min, Med, Max] or Scalar(s))

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

// Handle different parameter formats
private "_timeout";
private "_timeoutMin";
private "_timeoutMax";

// Check if we have a full timeout array or individual timeouts
if (count _this > 10) then {
    if (_this select 10 isEqualType []) then {
        // We have an array for timeout
        _timeout = _this select 10;
    } else {
        // We have individual numbers
        _timeoutMin = _this select 10;
        
        // Check if we have a max timeout value
        if (count _this > 11) then {
            _timeoutMax = _this select 11;
        } else {
            _timeoutMax = _timeoutMin * 2;
        };
        
        // Create timeout array
        _timeout = [_timeoutMin, (_timeoutMin + _timeoutMax) / 2, _timeoutMax];
    };
} else {
    // Default timeout
    _timeout = [0, 0, 0];
};

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
    ["_code", "", ["", 0]]
];

// Convert _code to string if it's a number
if (_code isEqualType 0) then {
    _code = str _code;
};

// Ensure timeout is properly formatted
if (_timeout isEqualType 0) then {
    _timeout = [floor(_timeout * 0.5), _timeout, ceil(_timeout * 1.5)];
} else {
    if (count _timeout < 3) then {
        if (count _timeout == 1) then {
            private _val = _timeout select 0;
            _timeout = [floor(_val * 0.5), _val, ceil(_val * 1.5)];
        };
        if (count _timeout == 2) then {
            private _min = _timeout select 0;
            private _max = _timeout select 1;
            private _mid = (_min + _max) / 2;
            _timeout = [_min, _mid, _max];
        };
    };
};

// Enable AI pathing
{
    _x enableAI "PATH";
} forEach units _group;

// Can pass parameters straight through to addWaypoint
_this =+ _this;
_this set [2, -1];

// Adjust parameters for addWaypoint
if (count _this > 3) then {
    _this deleteAt 3;
};

// Create waypoints at different locations around the center position
for "_i" from 1 to _count do {
    // Find a safe position within the radius
    _this set [1, [_position, _radius/2, _radius, 5, 0, 0, 0, [], [_position getPos [_radius/2, random 360], []]] call BIS_fnc_findSafePos];
    
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