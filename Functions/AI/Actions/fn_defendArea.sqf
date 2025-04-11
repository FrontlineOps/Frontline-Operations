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

if (isNull _group) exitWith { false };
if (_position isEqualTo [0,0,0]) exitWith { false };

private _isVehicleGroup = false;
private _hasArmor = false;
private _hasAir = false;
private _vehicleTypes = [];
private _groupType = "MAN"; // Default type

{
	if (vehicle _x != _x) then {
		private _veh = vehicle _x;
		_isVehicleGroup = true;
		
		if (_veh isKindOf "Tank" || _veh isKindOf "Wheeled_APC") then {
			_hasArmor = true;
			_vehicleTypes pushBackUnique "ARMOR";
			_groupType = "ARMOR";
		};
		
		if (_veh isKindOf "Car") then {
			_vehicleTypes pushBackUnique "CAR";
			if (_groupType != "ARMOR") then { _groupType = "CAR"; };
		};
		
		if (_veh isKindOf "Air") then {
			_hasAir = true;
			_vehicleTypes pushBackUnique "AIR";
			if (_veh isKindOf "Helicopter") then {
				_groupType = "HELI";
			} else {
				_groupType = "PLANE";
			};
			if (_veh isKindOf "UAV") then {
				_groupType = "UAV";
			};
		};
		
		if (_veh isKindOf "Mortar") then {
			_groupType = "MORTAR";
		};
		
		if (_veh isKindOf "StaticWeapon" && {_veh isKindOf "AAA"}) then {
			_groupType = "AAA";
		};
		
		if (_veh isKindOf "Artillery") then {
			_groupType = "ART";
		};
		
		if (_veh isKindOf "WheeledAPC") then {
			_groupType = "MECH";
		};
		
		if (_veh isKindOf "Ship") then {
			_groupType = "SHIP";
		};
	};
} forEach units _group;

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

private _targetType = _position call FLO_fnc_getTargetType;
[_group] call CBA_fnc_clearWaypoints;

// Use type-based approach for waypoint creation
switch (_groupType) do {
	case "MAN": {
		private _dist = (leader _group) distance2d _position;
		private _dir = (leader _group) getDir _position;
		
		// Approach waypoint
		[_group, (leader _group) getRelPos [_dist * 0.85, _dir], random [30, 50, 100], "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN"] call FLO_fnc_addWaypoint;
		
		// Always use taskDefend for all situations
		[_group, _position, random [30, 55, 100], ceil(count (units _group)/2), 0.2, 0.5] call FLO_fnc_taskDefend;
	};
	
	case "UAV";
	case "HELI";
	case "PLANE": {
		// Air units provide overwatch with a search and destroy waypoint
		[_group, _position, random [50, 150, 200], "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "", [120, 240, 360], 50] call FLO_fnc_addWaypoint;
		
		// Add RTB waypoint
		private _landWP = [_group, getPos leader _group, -1, "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN", "this setVariable ['Flo_Group_orders', nil]"] call FLO_fnc_addWaypoint;
		_landWP setWaypointScript "A3\functions_f\waypoints\fn_wpLand.sqf";
	};
	
	case "MORTAR";
	case "AAA";
	case "ART": {
		// Static weapons stay in place
		[_group, [_position, 50, 200, 5, 0, 0, 0, [], [_position getPos [random 200, random 360], []]] call BIS_fnc_findSafePos, -1, "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "[this] call FLO_fnc_reconAreaAction; this setVariable ['Flo_Group_orders', nil]", [120, 240, 360], 50] call FLO_fnc_addWaypoint;
	};
	
	case "MECH";
	case "ARMOR";
	case "CAR";
	case "SHIP": {
		// Ground vehicles take strategic positions
		if (_hasArmor) then {
			// Find defensive positions around the area
			private _defensivePositions = [];
			for "_i" from 0 to 3 do {
				private _dir = _i * 90; // Spread in four directions
				private _defPos = _position getPos [150 + random 50, _dir];
				_defensivePositions pushBack _defPos;
			};
			
			// Primary position
			private _bestPos = selectRandom _defensivePositions;
			[_group, _bestPos, 10, "SENTRY", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "", [60, 90, 120]] call FLO_fnc_addWaypoint;
			
			// Secondary position
			private _secondaryPos = selectRandom (_defensivePositions - [_bestPos]);
			[_group, _secondaryPos, 10, "SENTRY", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "", [60, 90, 120]] call FLO_fnc_addWaypoint;
		} else {
			// Light vehicles patrol the perimeter
			private _patrolRadius = 150;
			
			// Create patrol points
			private _patrolPoints = [];
			for "_i" from 0 to 5 do {
				private _dir = _i * 60;
				private _patrolPos = _position getPos [_patrolRadius, _dir];
				_patrolPoints pushBack _patrolPos;
			};
			
			// Add patrol waypoints
			{
				[_group, _x, 0, "MOVE", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "", [15, 30, 45]] call FLO_fnc_addWaypoint;
			} forEach _patrolPoints;
			
			// Create a cycle back to first point
			[_group, _patrolPoints select 0, 0, "CYCLE", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN"] call FLO_fnc_addWaypoint;
		};
	};
	
	default {
		// Default fallback - simple defense
		[_group, _position, random [50, 150, 200], "SENTRY", "AWARE", "YELLOW", "NORMAL", "STAG COLUMN", "", [120, 240, 360], 50] call FLO_fnc_addWaypoint;
	};
};

true 