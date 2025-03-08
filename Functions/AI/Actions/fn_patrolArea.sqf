/* ----------------------------------------------------------------------------
Function: FLO_fnc_patrolArea

Description:
    A function for a group to patrol a specified area. Behavior varies based on unit type.
    Infantry will do ground patrols, aircraft will do fly-by patrols, and vehicles will
    cover the perimeter with search and destroy missions.

Parameters:
    - Group (Group or Object)
    - Position (XYZ, Object, Location or Group)
    - Patrol Type (Optional, String)
    - Linked Group (Optional, Group)

Example:
    (begin example)
    [_group, _areaToPatrol] call FLO_fnc_patrolArea
    (end)

Returns:
    BOOL - Success or failure

Author:
    Azraeelian Angel
---------------------------------------------------------------------------- */

params [
	["_group", grpNull, [grpNull]],
	["_position", [0,0,0], [[]], [2,3]],
	["_patrolType", "", [""]],
	["_linkedGroup", grpNull, [grpNull]]
];

// Validate parameters
if (isNull _group) exitWith {
	["FLO_fnc_patrolArea", 1, "Invalid group parameter"] call FLO_fnc_log;
	false
};

if (_position isEqualTo [0,0,0]) exitWith {
	["FLO_fnc_patrolArea", 1, "Invalid position parameter"] call FLO_fnc_log;
	false
};

// Check the type of group for vehicles vs infantry
private _isVehicleGroup = false;
private _hasArmor = false;
private _hasAir = false;
private _vehicleTypes = [];

{
	if (vehicle _x != _x) then {
		private _veh = vehicle _x;
		_isVehicleGroup = true;
		
		if (_veh isKindOf "Tank" || _veh isKindOf "Wheeled_APC") then {
			_hasArmor = true;
			_vehicleTypes pushBackUnique "ARMOR";
		};
		
		if (_veh isKindOf "Car") then {
			_vehicleTypes pushBackUnique "CAR";
		};
		
		if (_veh isKindOf "Air") then {
			_hasAir = true;
			_vehicleTypes pushBackUnique "AIR";
		};
	};
} forEach units _group;

// Determine if we have a linked group, and its type
private _hasLinkedGroup = !isNull _linkedGroup;
private _linkedIsVehicle = false;

if (_hasLinkedGroup) then {
	{
		if (vehicle _x != _x) then {
			_linkedIsVehicle = true;
		};
	} forEach units _linkedGroup;
};

// Set the group's behavior based on its type
_group setBehaviour "SAFE";
_group setCombatMode "YELLOW";

// Get the target type for behavior selection
private _targetType = _position call FLO_fnc_getTargetType;

// Determine patrol radius based on type and area
private _patrolRadius = 200; // Default
if (_patrolType == "WIDE") then {
	_patrolRadius = 400;
} else {
	if (_patrolType == "TIGHT") then {
		_patrolRadius = 100;
	};
};

// Adjust radius for vehicles
if (_isVehicleGroup && !_hasAir) then {
	_patrolRadius = _patrolRadius * 1.5;
};

// Different patrol behavior based on group type and coordination status
switch (true) do {
	// Vehicle group supporting infantry
	case (_isVehicleGroup && _hasLinkedGroup && !_linkedIsVehicle): {
		_group setSpeedMode "LIMITED";
		
		if (_hasArmor) then {
			// Armored vehicles patrol outer perimeter
			_group setFormation "COLUMN";
			
			// Create a wider patrol path around the infantry
			private _widePatrolRadius = _patrolRadius * 1.5;
			private _patrolPoints = [];
			for "_i" from 0 to 5 do {
				private _dir = _i * 60; // 6 points around the circle
				private _patrolPos = _position getPos [_widePatrolRadius, _dir];
				_patrolPoints pushBack _patrolPos;
			};
			
			// Add patrol waypoints
			{
				private _wp = _group addWaypoint [_x, 0];
				_wp setWaypointType "MOVE";
				_wp setWaypointStatements ["true", ""];
				_wp setWaypointTimeout [30, 45, 60]; // Random pause at each point
			} forEach _patrolPoints;
			
			// Cycle the patrol
			private _cycleWP = _group addWaypoint [_patrolPoints select 0, 0];
			_cycleWP setWaypointType "CYCLE";
			
			["FLO_fnc_patrolArea", 3, format["Assigned armored perimeter patrol to %1 around %2, supporting %3", _group, _position, _linkedGroup]] call FLO_fnc_log;
		} else {
			// Light vehicles patrol ahead of infantry
			_group setFormation "WEDGE";
			
			// Get infantry movement direction
			private _infantryDir = getDir (leader _linkedGroup);
			
			// Create patrol points ahead of infantry movement
			private _patrolPoints = [];
			for "_i" from -2 to 2 do {
				private _dir = _infantryDir + (_i * 30); // Arc in front of infantry
				private _patrolPos = _position getPos [_patrolRadius, _dir];
				_patrolPoints pushBack _patrolPos;
			};
			
			// Add patrol waypoints
			{
				private _wp = _group addWaypoint [_x, 0];
				_wp setWaypointType "MOVE";
				_wp setWaypointStatements ["true", ""];
				_wp setWaypointTimeout [15, 30, 45]; // Random pause at each point
			} forEach _patrolPoints;
			
			// Cycle the patrol
			private _cycleWP = _group addWaypoint [_patrolPoints select 0, 0];
			_cycleWP setWaypointType "CYCLE";
			
			["FLO_fnc_patrolArea", 3, format["Assigned vehicle forward patrol to %1 ahead of %2", _group, _linkedGroup]] call FLO_fnc_log;
		};
	};
	
	// Infantry group with vehicle support
	case (!_isVehicleGroup && _hasLinkedGroup && _linkedIsVehicle): {
		// Infantry patrols inside the perimeter
		_group setSpeedMode "LIMITED";
		_group setFormation "WEDGE";
		
		// Slightly tighter patrol radius for infantry when supported by vehicles
		private _infantryPatrolRadius = _patrolRadius * 0.7;
		
		// Use task patrol function for infantry
		[_group, _position, _infantryPatrolRadius, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "NO CHANGE", 3, 6] call FLO_fnc_taskPatrol;
		
		["FLO_fnc_patrolArea", 3, format["Assigned infantry patrol to %1 at %2, with vehicle support", _group, _position]] call FLO_fnc_log;
	};
	
	// Standard infantry patrol without support
	case (!_isVehicleGroup): {
		// Use task patrol for regular infantry
		[_group, _position, _patrolRadius, 7, "MOVE", "SAFE", "YELLOW", "LIMITED", "NO CHANGE", 2, 4] call FLO_fnc_taskPatrol;
		
		["FLO_fnc_patrolArea", 3, format["Assigned infantry patrol to %1 at %2", _group, _position]] call FLO_fnc_log;
	};
	
	// Standard vehicle patrol without infantry support
	case (_isVehicleGroup): {
		if (_hasAir) then {
			// Air vehicles get a much wider patrol area
			private _airPatrolRadius = _patrolRadius * 3;
			
			// Create several waypoints in a circular pattern
			private _patrolPoints = [];
			for "_i" from 0 to 7 do {
				private _dir = _i * 45; // 8 points around the circle
				private _patrolPos = _position getPos [_airPatrolRadius, _dir];
				_patrolPoints pushBack _patrolPos;
			};
			
			// Add patrol waypoints
			{
				private _wp = _group addWaypoint [_x, 0];
				_wp setWaypointType "MOVE";
				_wp setWaypointStatements ["true", ""];
			} forEach _patrolPoints;
			
			// Cycle the patrol
			private _cycleWP = _group addWaypoint [_patrolPoints select 0, 0];
			_cycleWP setWaypointType "CYCLE";
			
			["FLO_fnc_patrolArea", 3, format["Assigned air patrol to %1 around %2", _group, _position]] call FLO_fnc_log;
		} else {
			// Ground vehicles
			if (_hasArmor) then {
				// Armor gets fewer waypoints but longer pauses
				[_group, _position, _patrolRadius, 5, "MOVE", "SAFE", "YELLOW", "LIMITED", "NO CHANGE", 3, 6] call FLO_fnc_taskPatrol;
				
				["FLO_fnc_patrolArea", 3, format["Assigned armored patrol to %1 at %2", _group, _position]] call FLO_fnc_log;
			} else {
				// Light vehicles get more waypoints
				[_group, _position, _patrolRadius, 8, "MOVE", "SAFE", "YELLOW", "NORMAL", "NO CHANGE", 2, 4] call FLO_fnc_taskPatrol;
				
				["FLO_fnc_patrolArea", 3, format["Assigned vehicle patrol to %1 at %2", _group, _position]] call FLO_fnc_log;
			};
		};
	};
};

// Return success
true 