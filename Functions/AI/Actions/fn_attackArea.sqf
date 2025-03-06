/* ----------------------------------------------------------------------------
Function: FLO_fnc_attackArea

Description:
    A function for a group to attack a specified area. Behavior varies based on unit type.

Parameters:
    - Group (Group or Object)
    - Position (XYZ, Object, Location or Group)
    - Attack Type (Optional, String)
    - Linked Group (Optional, Group)

Example:
    (begin example)
    [_group, _targetPosition] call FLO_fnc_attackArea
    (end)

Returns:
    BOOL - Success or failure

Author:
    Azraeelian Angel
---------------------------------------------------------------------------- */

params [
	["_group", grpNull, [grpNull]],
	["_position", [0,0,0], [[]], [2,3]],
	["_attackType", "", [""]],
	["_linkedGroup", grpNull, [grpNull]]
];

// Validate parameters
if (isNull _group) exitWith {
	["FLO_fnc_attackArea", 1, "Invalid group parameter"] call FLO_fnc_log;
	false
};

if (_position isEqualTo [0,0,0]) exitWith {
	["FLO_fnc_attackArea", 1, "Invalid position parameter"] call FLO_fnc_log;
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

// Set the group's behavior based on its type and the attack type
_group setBehaviour "AWARE";
_group setCombatMode "RED";

// Get the target type for behavior selection
private _targetType = _position call FLO_fnc_getTargetType;

// Different attack behavior based on group type and coordination status
switch (true) do {
	// Vehicle group supporting infantry
	case (_isVehicleGroup && _hasLinkedGroup && !_linkedIsVehicle): {
		_group setSpeedMode "LIMITED";
		
		// Tanks lead, other vehicles provide support
		if (_hasArmor) then {
			// Tanks attack directly
			_group setFormation "WEDGE";
			
			// Add attack waypoint
			private _attackWP = _group addWaypoint [_position, 0];
			_attackWP setWaypointType "SAD";
			_attackWP setWaypointStatements ["true", ""];
			
			// Add second waypoint to search area
			private _searchWP = _group addWaypoint [_position, 100];
			_searchWP setWaypointType "SAD";
			_searchWP setWaypointStatements ["true", ""];
			
			["FLO_fnc_attackArea", 3, format["Assigned armored attack to %1 at %2, supporting %3", _group, _position, _linkedGroup]] call FLO_fnc_log;
		} else {
			// Other vehicles provide fire support from distance
			_group setFormation "LINE";
			
			// Find a good position for fire support
			private _dir = (leader _linkedGroup) getDir _position;
			private _supportPos = _position getPos [150, _dir - 180]; // Position behind infantry
			
			// Add fire support waypoint
			private _supportWP = _group addWaypoint [_supportPos, 0];
			_supportWP setWaypointType "MOVE";
			_supportWP setWaypointStatements ["true", ""];
			
			// Add attack waypoint after infantry has engaged
			private _attackWP = _group addWaypoint [_position, 50];
			_attackWP setWaypointType "SAD";
			_attackWP setWaypointStatements ["true", ""];
			
			["FLO_fnc_attackArea", 3, format["Assigned vehicle fire support to %1 at %2, supporting %3", _group, _position, _linkedGroup]] call FLO_fnc_log;
		};
	};
	
	// Infantry group with vehicle support
	case (!_isVehicleGroup && _hasLinkedGroup && _linkedIsVehicle): {
		_group setSpeedMode "NORMAL";
		_group setFormation "WEDGE";
		
		// Let vehicles engage first if they have armor
		if (_linkedHasArmor) then {
			// Delay infantry attack to let armor engage first
			private _holdWP = _group addWaypoint [getPos (leader _group), 0];
			_holdWP setWaypointType "HOLD";
			_holdWP setWaypointStatements ["true", ""];
			_holdWP setWaypointTimeout [30, 45, 60]; // Hold for 30-60 seconds
			
			// Then advance to attack
			private _advanceWP = _group addWaypoint [_position, 0];
			_advanceWP setWaypointType "SAD";
			_advanceWP setWaypointStatements ["true", ""];
			
			// Add search waypoint
			private _searchWP = _group addWaypoint [_position, 100];
			_searchWP setWaypointType "SAD";
			_searchWP setWaypointStatements ["true", ""];
			
			["FLO_fnc_attackArea", 3, format["Assigned infantry assault to %1 at %2, with armor support from %3", _group, _position, _linkedGroup]] call FLO_fnc_log;
		} else {
			// With lighter vehicles, infantry leads the attack
			private _advanceWP = _group addWaypoint [_position, 0];
			_advanceWP setWaypointType "SAD";
			_advanceWP setWaypointStatements ["true", ""];
			
			// Add search waypoint
			private _searchWP = _group addWaypoint [_position, 100];
			_searchWP setWaypointType "SAD";
			_searchWP setWaypointStatements ["true", ""];
			
			["FLO_fnc_attackArea", 3, format["Assigned infantry attack to %1 at %2, with vehicle support from %3", _group, _position, _linkedGroup]] call FLO_fnc_log;
		};
	};
	
	// Standard infantry attack without support
	case (!_isVehicleGroup): {
		_group setSpeedMode "NORMAL";
		_group setFormation "WEDGE";
		
		// Basic attack waypoint
		private _attackWP = _group addWaypoint [_position, 0];
		_attackWP setWaypointType "SAD";
		_attackWP setWaypointStatements ["true", ""];
		
		// Add search waypoint
		private _searchWP = _group addWaypoint [_position, 100];
		_searchWP setWaypointType "SAD";
		_searchWP setWaypointStatements ["true", ""];
		
		["FLO_fnc_attackArea", 3, format["Assigned basic infantry attack to %1 at %2", _group, _position]] call FLO_fnc_log;
	};
	
	// Standard vehicle attack without infantry support
	case (_isVehicleGroup): {
		_group setSpeedMode "NORMAL";
		
		// Different behavior based on vehicle type
		if (_hasArmor) then {
			_group setFormation "WEDGE";
			
			// Armored assault
			private _attackWP = _group addWaypoint [_position, 0];
			_attackWP setWaypointType "SAD";
			_attackWP setWaypointStatements ["true", ""];
			
			// Add second waypoint to search area
			private _searchWP = _group addWaypoint [_position, 150];
			_searchWP setWaypointType "SAD";
			_searchWP setWaypointStatements ["true", ""];
			
			["FLO_fnc_attackArea", 3, format["Assigned armored attack to %1 at %2", _group, _position]] call FLO_fnc_log;
		} else {
			_group setFormation "LINE";
			
			// Light vehicles attack from range
			private _attackPos = _position getPos [200, random 360];
			private _attackWP = _group addWaypoint [_attackPos, 0];
			_attackWP setWaypointType "MOVE";
			_attackWP setWaypointStatements ["true", ""];
			
			// Then move in for assault
			private _assaultWP = _group addWaypoint [_position, 0];
			_assaultWP setWaypointType "SAD";
			_assaultWP setWaypointStatements ["true", ""];
			
			["FLO_fnc_attackArea", 3, format["Assigned vehicle attack to %1 at %2", _group, _position]] call FLO_fnc_log;
		};
	};
};

// Return success
true 