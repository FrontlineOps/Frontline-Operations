/* ----------------------------------------------------------------------------
Function: FLO_fnc_reconArea

Description:
    A function for a group to perform reconnaissance in a specified area. 
    Behavior varies based on unit type. Infantry will use stealth tactics,
    aircraft will do high-altitude surveillance, and vehicles will perform
    perimeter checks.

Parameters:
    - Group (Group or Object)
    - Position (XYZ, Object, Location or Group)
    - Recon Type (String, Optional)
    - Linked Group (Group, Optional)

Example:
    (begin example)
    [_group, _areaToRecon] call FLO_fnc_reconArea
    (end)

Returns:
    BOOL - Success or failure

Author:
    Azraeelian Angel
---------------------------------------------------------------------------- */

params [
	["_group", grpNull, [grpNull]],
	["_position", [0,0,0], [[]], [2,3]],
	["_reconType", "", [""]],
	["_linkedGroup", grpNull, [grpNull]]
];

// Validate parameters
if (isNull _group) exitWith {
	["FLO_fnc_reconArea", 1, "Invalid group parameter"] call FLO_fnc_log;
	false
};

if (_position isEqualTo [0,0,0]) exitWith {
	["FLO_fnc_reconArea", 1, "Invalid position parameter"] call FLO_fnc_log;
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

// Set the group's behavior based on type and recon type
if (_reconType == "STEALTH" || !_isVehicleGroup) then {
	_group setBehaviour "STEALTH";
	_group setCombatMode "GREEN";
	_group setSpeedMode "LIMITED";
} else {
	_group setBehaviour "AWARE";
	_group setCombatMode "YELLOW";
	_group setSpeedMode "LIMITED";
};

// Get the target type for behavior selection
private _targetType = _position call FLO_fnc_getTargetType;

// Determine recon radius based on type and area
private _reconRadius = 300; // Default

// Add the FLO_fnc_reconAreaAction to all waypoints
private _reconActionStatement = "[this] call FLO_fnc_reconAreaAction";

// Different recon behavior based on group type and coordination status
switch (true) do {
	// Vehicle group supporting infantry
	case (_isVehicleGroup && _hasLinkedGroup && !_linkedIsVehicle): {
		if (_hasAir) then {
			// Air vehicles provide high altitude recon
			_group setFormation "FILE";
			
			// Create observation points around the area
			private _observationPoints = [];
			for "_i" from 0 to 3 do {
				private _dir = _i * 90; // 4 points around the circle
				private _obsPos = _position getPos [500, _dir];
				_observationPoints pushBack _obsPos;
			};
			
			// Add waypoints with report action
			{
				private _wp = _group addWaypoint [_x, 0];
				_wp setWaypointType "MOVE";
				_wp setWaypointStatements ["true", _reconActionStatement];
				_wp setWaypointTimeout [45, 60, 90]; // Longer observation time
			} forEach _observationPoints;
			
			// Cycle the observation
			private _cycleWP = _group addWaypoint [_observationPoints select 0, 0];
			_cycleWP setWaypointType "CYCLE";
			
			["FLO_fnc_reconArea", 3, format["Assigned air reconnaissance to %1 around %2, supporting %3", _group, _position, _linkedGroup]] call FLO_fnc_log;
		} else {
			// Ground vehicles take observation positions
			_group setFormation "WEDGE";
			
			// Find good observation points at the edge of the area
			private _obsDistance = 300 + (random 200);
			private _direction = random 360;
			private _observationPoint = _position getPos [_obsDistance, _direction];
			
			// Add observation waypoint
			private _obsWP = _group addWaypoint [_observationPoint, 0];
			_obsWP setWaypointType "SENTRY";
			_obsWP setWaypointStatements ["true", _reconActionStatement];
			_obsWP setWaypointTimeout [60, 120, 180]; // Long observation time
			
			// Add a second observation point
			private _secondDirection = (_direction + 120 + random 60) % 360;
			private _secondObsPoint = _position getPos [_obsDistance, _secondDirection];
			private _secondWP = _group addWaypoint [_secondObsPoint, 0];
			_secondWP setWaypointType "SENTRY";
			_secondWP setWaypointStatements ["true", _reconActionStatement];
			_secondWP setWaypointTimeout [60, 120, 180];
			
			// Cycle through observation points
			private _cycleWP = _group addWaypoint [_observationPoint, 0];
			_cycleWP setWaypointType "CYCLE";
			
			["FLO_fnc_reconArea", 3, format["Assigned vehicle observation to %1 at %2, supporting %3", _group, _position, _linkedGroup]] call FLO_fnc_log;
		};
	};
	
	// Infantry group with vehicle support
	case (!_isVehicleGroup && _hasLinkedGroup && _linkedIsVehicle): {
		// Infantry performs close recon while vehicles cover
		_group setFormation "FILE";
		
		// Create approach waypoint
		private _approachPos = _position getPos [200, random 360];
		private _approachWP = _group addWaypoint [_approachPos, 0];
		_approachWP setWaypointType "MOVE";
		_approachWP setWaypointStatements ["true", "group this setBehaviour 'STEALTH';"];
		
		// Create recon waypoints
		for "_i" from 0 to 2 do {
			private _reconPos = _position getPos [100 + (random 100), (random 360)];
			private _reconWP = _group addWaypoint [_reconPos, 0];
			_reconWP setWaypointType "MOVE";
			_reconWP setWaypointStatements ["true", _reconActionStatement];
			_reconWP setWaypointTimeout [30, 45, 60];
		};
		
		// Add extract waypoint
		private _extractPos = _position getPos [300, random 360];
		private _extractWP = _group addWaypoint [_extractPos, 0];
		_extractWP setWaypointType "MOVE";
		_extractWP setWaypointStatements ["true", "group this setBehaviour 'AWARE';"];
		
		// Return to start and cycle
		private _cycleWP = _group addWaypoint [_approachPos, 0];
		_cycleWP setWaypointType "CYCLE";
		
		["FLO_fnc_reconArea", 3, format["Assigned infantry close recon to %1 at %2, with vehicle support", _group, _position]] call FLO_fnc_log;
	};
	
	// Standard infantry recon without support
	case (!_isVehicleGroup): {
		// Infantry performs stealthy recon
		_group setFormation "FILE";
		
		// Create approach waypoint
		private _approachPos = _position getPos [200, random 360];
		private _approachWP = _group addWaypoint [_approachPos, 0];
		_approachWP setWaypointType "MOVE";
		_approachWP setWaypointStatements ["true", "group this setBehaviour 'STEALTH';"];
		
		// Create multiple recon points in the area
		for "_i" from 0 to 3 do {
			private _reconPos = _position getPos [50 + (random 150), (random 360)];
			private _reconWP = _group addWaypoint [_reconPos, 0];
			_reconWP setWaypointType "MOVE";
			_reconWP setWaypointStatements ["true", _reconActionStatement];
			_reconWP setWaypointTimeout [20, 30, 45];
		};
		
		// Add extract waypoint
		private _extractPos = _position getPos [300, random 360];
		private _extractWP = _group addWaypoint [_extractPos, 0];
		_extractWP setWaypointType "MOVE";
		_extractWP setWaypointStatements ["true", "group this setBehaviour 'AWARE';"];
		
		// Return to start and cycle
		private _cycleWP = _group addWaypoint [_approachPos, 0];
		_cycleWP setWaypointType "CYCLE";
		
		["FLO_fnc_reconArea", 3, format["Assigned infantry recon to %1 at %2", _group, _position]] call FLO_fnc_log;
	};
	
	// Standard vehicle recon without infantry support
	case (_isVehicleGroup): {
		if (_hasAir) then {
			// Air vehicles provide high altitude recon
			_group setFormation "FILE";
			
			// Create observation points around the area
			private _observationPoints = [];
			for "_i" from 0 to 5 do {
				private _dir = _i * 60; // 6 points around the circle
				private _obsPos = _position getPos [600, _dir];
				_observationPoints pushBack _obsPos;
			};
			
			// Add waypoints
			{
				private _wp = _group addWaypoint [_x, 0];
				_wp setWaypointType "MOVE";
				_wp setWaypointStatements ["true", _reconActionStatement];
				_wp setWaypointTimeout [30, 45, 60];
			} forEach _observationPoints;
			
			// Cycle the observation
			private _cycleWP = _group addWaypoint [_observationPoints select 0, 0];
			_cycleWP setWaypointType "CYCLE";
			
			["FLO_fnc_reconArea", 3, format["Assigned air reconnaissance to %1 around %2", _group, _position]] call FLO_fnc_log;
		} else {
			// Ground vehicles
			_group setFormation "WEDGE";
			
			// Create approach waypoint
			private _approachPos = _position getPos [350, random 360];
			private _approachWP = _group addWaypoint [_approachPos, 0];
			_approachWP setWaypointType "MOVE";
			_approachWP setWaypointStatements ["true", ""];
			
			// Create observation points at different edges of the area
			for "_i" from 0 to 2 do {
				private _dir = (random 360);
				private _obsPos = _position getPos [250 + (random 100), _dir];
				private _obsWP = _group addWaypoint [_obsPos, 0];
				_obsWP setWaypointType "SENTRY";
				_obsWP setWaypointStatements ["true", _reconActionStatement];
				_obsWP setWaypointTimeout [40, 60, 90];
			};
			
			// Return to start and cycle
			private _cycleWP = _group addWaypoint [_approachPos, 0];
			_cycleWP setWaypointType "CYCLE";
			
			["FLO_fnc_reconArea", 3, format["Assigned vehicle recon to %1 at %2", _group, _position]] call FLO_fnc_log;
		};
	};
};

// Return success
true 