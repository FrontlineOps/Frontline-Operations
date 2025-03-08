/* ----------------------------------------------------------------------------
Function: FLO_fnc_defendArea

Description:
    A function for a group to defend a specified area. Behavior varies based on unit type.
    Infantry will use buildings and static weapons, vehicles will guard the perimeter.

Parameters:
    - Group (Group or Object)
    - Position (XYZ, Object, Location or Group)
    - Defend Type (Optional String)
    - Linked Group (Optional Group)

Example:
    (begin example)
    [_group, _areaToDefend] call FLO_fnc_defendArea
    (end)

Returns:
    BOOL - Success or failure

Author:
    Azraeelian Angel
---------------------------------------------------------------------------- */

params [
	["_group", grpNull, [grpNull]],
	["_position", [0,0,0], [[]], [2,3]],
	["_defendType", "", [""]],
	["_linkedGroup", grpNull, [grpNull]]
];

// Validate parameters
if (isNull _group) exitWith {
	["FLO_fnc_defendArea", 1, "Invalid group parameter"] call FLO_fnc_log;
	false
};

if (_position isEqualTo [0,0,0]) exitWith {
	["FLO_fnc_defendArea", 1, "Invalid position parameter"] call FLO_fnc_log;
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
private _linkedHasArmor = false;
private _linkedVehicleTypes = [];

if (_hasLinkedGroup) then {
	{
		if (vehicle _x != _x) then {
			private _veh = vehicle _x;
			_linkedIsVehicle = true;
			
			if (_veh isKindOf "Tank" || _veh isKindOf "Wheeled_APC") then {
				_linkedHasArmor = true;
				_linkedVehicleTypes pushBackUnique "ARMOR";
			};
			
			if (_veh isKindOf "Car") then {
				_linkedVehicleTypes pushBackUnique "CAR";
			};
			
			if (_veh isKindOf "Air") then {
				_linkedVehicleTypes pushBackUnique "AIR";
			};
		};
	} forEach units _linkedGroup;
};

// Set the group's behavior based on its type and the defend type
_group setBehaviour "AWARE";
_group setCombatMode "YELLOW";

// Get the target type for behavior selection
private _targetType = _position call FLO_fnc_getTargetType;

// Different defend behavior based on group type and coordination status
switch (true) do {
	// Vehicle group supporting infantry
	case (_isVehicleGroup && _hasLinkedGroup && !_linkedIsVehicle): {
		_group setSpeedMode "LIMITED";
		
		// Different positions based on vehicle type
		if (_hasArmor) then {
			// Tanks take defensive positions along likely approach routes
			_group setFormation "LINE";
			
			// Find good defensive positions around the target area
			private _defensivePositions = [];
			for "_i" from 0 to 3 do {
				private _dir = _i * 90; // Spread in four directions
				private _defPos = _position getPos [200, _dir];
				_defensivePositions pushBack _defPos;
			};
			
			// Pick the best position based on terrain
			private _bestPos = selectRandom _defensivePositions;
			
			// Add defend waypoint
			private _defendWP = _group addWaypoint [_bestPos, 0];
			_defendWP setWaypointType "SENTRY";
			_defendWP setWaypointStatements ["true", ""];
			
			// Add a secondary position
			private _secondaryPos = selectRandom (_defensivePositions - [_bestPos]);
			private _secondaryWP = _group addWaypoint [_secondaryPos, 0];
			_secondaryWP setWaypointType "SENTRY";
			_secondaryWP setWaypointStatements ["true", ""];
			
			// Cycle through positions
			private _cycleWP = _group addWaypoint [_bestPos, 0];
			_cycleWP setWaypointType "CYCLE";
			
			["FLO_fnc_defendArea", 3, format["Assigned armored defense to %1 at %2, supporting %3", _group, _position, _linkedGroup]] call FLO_fnc_log;
		} else {
			// Light vehicles patrol the perimeter
			_group setFormation "COLUMN";
			
			// Create a perimeter path around the position
			private _patrolPoints = [];
			for "_i" from 0 to 7 do {
				private _dir = _i * 45; // 8 points around the circle
				private _patrolPos = _position getPos [150, _dir];
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
			
			["FLO_fnc_defendArea", 3, format["Assigned vehicle perimeter patrol to %1 around %2, supporting %3", _group, _position, _linkedGroup]] call FLO_fnc_log;
		};
	};
	
	// Infantry group with vehicle support
	case (!_isVehicleGroup && _hasLinkedGroup && _linkedIsVehicle): {
		// Infantry focuses on building defense and static weapons
		[_group, _position] call FLO_fnc_taskDefend;
		
		["FLO_fnc_defendArea", 3, format["Assigned infantry garrison defense to %1 at %2, with vehicle support from %3", _group, _position, _linkedGroup]] call FLO_fnc_log;
	};
	
	// Standard infantry defense without support
	case (!_isVehicleGroup): {
		// Different defense behavior based on area type
		if (_defendType == "GARRISON" || _targetType == "TOWN") then {
			// Garrison buildings
			[_group, _position] call FLO_fnc_taskDefend;
			
			["FLO_fnc_defendArea", 3, format["Assigned infantry garrison defense to %1 at %2", _group, _position]] call FLO_fnc_log;
		} else {
			// Defensive positions
			private _defendWP = _group addWaypoint [_position, 0];
			_defendWP setWaypointType "SENTRY";
			_defendWP setWaypointStatements ["true", ""];
			
			// Add a secondary position for patrolling
			private _patrolPos = _position getPos [50, random 360];
			private _patrolWP = _group addWaypoint [_patrolPos, 0];
			_patrolWP setWaypointType "SENTRY";
			_patrolWP setWaypointStatements ["true", ""];
			
			// Cycle back to main position
			private _cycleWP = _group addWaypoint [_position, 0];
			_cycleWP setWaypointType "CYCLE";
			
			["FLO_fnc_defendArea", 3, format["Assigned infantry defensive position to %1 at %2", _group, _position]] call FLO_fnc_log;
		};
	};
	
	// Standard vehicle defense without infantry support
	case (_isVehicleGroup): {
		_group setSpeedMode "LIMITED";
		
		// Different behavior based on vehicle type
		if (_hasArmor) then {
			// Tanks take strategic positions
			_group setFormation "LINE";
			
			// Find good overwatch positions
			private _defensivePositions = [];
			for "_i" from 0 to 3 do {
				private _dir = _i * 90; // Spread in four directions
				private _defPos = _position getPos [200, _dir];
				_defensivePositions pushBack _defPos;
			};
			
			// Pick the best position based on terrain
			private _bestPos = selectRandom _defensivePositions;
			
			// Add defend waypoint
			private _defendWP = _group addWaypoint [_bestPos, 0];
			_defendWP setWaypointType "SENTRY";
			_defendWP setWaypointStatements ["true", ""];
			
			// Add a secondary position
			private _secondaryPos = selectRandom (_defensivePositions - [_bestPos]);
			private _secondaryWP = _group addWaypoint [_secondaryPos, 0];
			_secondaryWP setWaypointType "SENTRY";
			_secondaryWP setWaypointStatements ["true", ""];
			
			// Cycle through positions
			private _cycleWP = _group addWaypoint [_bestPos, 0];
			_cycleWP setWaypointType "CYCLE";
			
			["FLO_fnc_defendArea", 3, format["Assigned armored defense to %1 at %2", _group, _position]] call FLO_fnc_log;
		} else {
			// Light vehicles patrol the area
			_group setFormation "COLUMN";
			
			// Create a patrol path around the position
			private _patrolRadius = 200;
			private _patrolPoints = [];
			for "_i" from 0 to 5 do {
				private _dir = _i * 60; // 6 points around the circle
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
			
			["FLO_fnc_defendArea", 3, format["Assigned vehicle patrol to %1 around %2", _group, _position]] call FLO_fnc_log;
		};
	};
};

// Return success
true 