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
		
		// Attack waypoint - direct assault 
		[_group, _position, 100, false] call FLO_fnc_taskAttack;
	};
	
	case "UAV";
	case "HELI";
	case "PLANE": {
		// Air units attack directly with search and destroy waypoints
		[_group, _position, random [50, 150, 200], "SAD", "AWARE", "RED", "NORMAL", "STAG COLUMN", "", [0, 0, 0], 50] call FLO_fnc_addWaypoint;
		[_group, _position, random [150, 300, 500], "SAD", "COMBAT", "RED", "NORMAL", "STAG COLUMN", "", [0, 0, 0], 50] call FLO_fnc_addWaypoint;
		
		// Return to base
		private _landWP = [_group, getPos leader _group, -1, "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN", "this setVariable ['Flo_Group_orders', nil]"] call FLO_fnc_addWaypoint;
		_landWP setWaypointScript "A3\functions_f\waypoints\fn_wpLand.sqf";
	};
	
	case "MORTAR";
	case "AAA";
	case "ART": {
		// Static weapon systems take position and engage
		[_group, [_position, 300, 800, 5, 0, 0, 0, [], [_position getPos [random 500, random 360], []]] call BIS_fnc_findSafePos, -1, "SENTRY", "AWARE", "RED", "LIMITED", "STAG COLUMN", "this setVariable ['Flo_Group_orders', nil]", [0, 0, 0], 50] call FLO_fnc_addWaypoint;
	};
	
	case "MECH";
	case "ARMOR": {
		// Armored vehicles use direct assault
		private _dist = (leader _group) distance2d _position;
		private _dir = (leader _group) getDir _position;
		
		// Approach waypoint
		[_group, (leader _group) getRelPos [_dist * 0.5, _dir], -1, "MOVE", "AWARE", "RED", "NORMAL", "WEDGE"] call FLO_fnc_addWaypoint;
		
		// Attack waypoint
		[_group, _position, 150, false] call FLO_fnc_taskAttack;
	};
	
	case "CAR";
	case "SHIP": {
		// Light vehicles flank and attack
		private _attackPos = _position getPos [200, random 360];
		
		// Move to flank position
		[_group, _attackPos, -1, "MOVE", "AWARE", "RED", "NORMAL", "LINE"] call FLO_fnc_addWaypoint;
		
		// Attack from flank
		[_group, _position, 50, false] call FLO_fnc_taskAttack;
	};
	
	default {
		// Default fallback - direct attack
		[_group, _position, 100, true] call FLO_fnc_taskAttack;
	};
};

true 