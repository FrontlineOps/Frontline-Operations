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

if (_hasLinkedGroup) then {
	{
		if (vehicle _x != _x) then {
			_linkedIsVehicle = true;
		};
	} forEach units _linkedGroup;
};

private _targetType = _position call FLO_fnc_getTargetType;
[_group] call CBA_fnc_clearWaypoints;

// Determine patrol parameters
private _patrolRadius = 200;
if (_patrolType == "WIDE") then {
	_patrolRadius = 400;
} else {
	if (_patrolType == "TIGHT") then {
		_patrolRadius = 100;
	};
};

// Use type-based approach for waypoint creation
switch (_groupType) do {
	case "MAN": {
		private _dist = (leader _group) distance2d _position;
		private _dir = (leader _group) getDir _position;
		
		// Approach waypoint
		[_group, (leader _group) getRelPos [_dist * 0.85, _dir], random [30, 50, 100], "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN"] call FLO_fnc_addWaypoint;
		
		// Main patrol task with search nearby
		[_group, _position, random [50, 250, 500], ceil(random [3, 5, 10]), "MOVE", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "[group this] call CBA_fnc_searchNearby", [3, 6, 9]] call FLO_fnc_taskPatrol;
		
		// Final return waypoint with order clearance
		private _landWP = [_group, getPos leader _group, -1, "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN", "[group this] call CBA_fnc_searchNearby; this setVariable ['Flo_Group_orders', nil];"] call FLO_fnc_addWaypoint;
	};
	
	case "UAV";
	case "HELI";
	case "PLANE": {
		// Multiple SAD waypoints at increasing distances
		[_group, _position, random [50, 150, 200], "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "", [0, 0, 0], 50] call FLO_fnc_addWaypoint;
		[_group, _position, random [50, 1050, 3000], "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "", [0, 0, 0], 50] call FLO_fnc_addWaypoint;
		[_group, _position, random [50, 1050, 3000], "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "", [0, 0, 0], 50] call FLO_fnc_addWaypoint;
		
		// Return to base and land
		private _landWP = [_group, getPos leader _group, -1, "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN", "this setVariable ['Flo_Group_orders', nil]"] call FLO_fnc_addWaypoint;
		_landWP setWaypointScript "A3\functions_f\waypoints\fn_wpLand.sqf";
	};
	
	case "MORTAR";
	case "AAA";
	case "ART";
	case "MECH";
	case "ARMOR";
	case "CAR";
	case "SHIP": {
		// Multiple SAD waypoints with safe positions
		[_group, [_position, 50, 200, 5, 0, 0, 0, [], [_position getPos [random 200, random 360], []]] call BIS_fnc_findSafePos, -1, "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "[this] call FLO_fnc_reconAreaAction", [120, 240, 360], 50] call FLO_fnc_addWaypoint;
		
		[_group, [_position, 50, 3000, 5, 0, 0, 0, [], [_position getPos [random 2000, random 360], []]] call BIS_fnc_findSafePos, -1, "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "[this] call FLO_fnc_reconAreaAction", [120, 240, 360], 50] call FLO_fnc_addWaypoint;
		
		[_group, [_position, 50, 3000, 5, 0, 0, 0, [], [_position getPos [random 2000, random 360], []]] call BIS_fnc_findSafePos, -1, "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "[this] call FLO_fnc_reconAreaAction; this setVariable ['Flo_Group_orders', nil]", [120, 240, 360], 50] call FLO_fnc_addWaypoint;
	};
	
	default {
		// Default fallback - simple patrol
		[_group, _position, random [100, 200, 300], ceil(random [3, 5, 7]), "MOVE", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "", [2, 4, 6]] call FLO_fnc_taskPatrol;
	};
};

true 