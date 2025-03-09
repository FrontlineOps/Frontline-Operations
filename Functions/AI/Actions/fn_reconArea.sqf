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

if (isNull _group) exitWith { false };
if (_position isEqualTo [0,0,0]) exitWith { false };

private _isVehicleGroup = false;
private _hasArmor = false;
private _hasAir = false;
private _vehicleTypes = [];
private _groupType = "MAN";

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

// Use type-based approach for waypoint creation
switch (_groupType) do {
	case "MAN": {
		private _dist = (leader _group) distance2d _position;
		private _dir = (leader _group) getDir _position;
		
		// Approach waypoint with stealth
		[_group, (leader _group) getRelPos [_dist * 0.85, _dir], random [30, 50, 100], "MOVE", "AWARE", "GREEN", "LIMITED", "STAG COLUMN", "group this setBehaviour 'STEALTH';"] call FLO_fnc_addWaypoint;
		
		// Multiple recon points
		for "_i" from 0 to 3 do {
			private _reconPos = _position getPos [random [50, 100, 150], random 360];
			[_group, _reconPos, -1, "MOVE", "STEALTH", "GREEN", "LIMITED", "STAG COLUMN", "[this] call FLO_fnc_reconAreaAction", [20, 30, 45]] call FLO_fnc_addWaypoint;
		}; 
		
		// Extract waypoint - reset to aware behavior
		[_group, (leader _group) getRelPos [_dist * 0.1, _dir], -1, "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN", "this setVariable ['Flo_Group_orders', nil];"] call FLO_fnc_addWaypoint;
	};
	
	case "UAV";
	case "HELI";
	case "PLANE": {
		// Multiple SAD waypoints at different positions
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
		// Multiple recon points with safe positions
		[_group, [_position, 50, 200, 5, 0, 0, 0, [], [_position getPos [random 200, random 360], []]] call BIS_fnc_findSafePos, -1, "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "[this] call FLO_fnc_reconAreaAction", [120, 240, 360], 50] call FLO_fnc_addWaypoint;
		
		[_group, [_position, 50, 3000, 5, 0, 0, 0, [], [_position getPos [random 2000, random 360], []]] call BIS_fnc_findSafePos, -1, "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "[this] call FLO_fnc_reconAreaAction", [120, 240, 360], 50] call FLO_fnc_addWaypoint;
		
		[_group, [_position, 50, 3000, 5, 0, 0, 0, [], [_position getPos [random 2000, random 360], []]] call BIS_fnc_findSafePos, -1, "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "[this] call FLO_fnc_reconAreaAction; this setVariable ['Flo_Group_orders', nil]", [120, 240, 360], 50] call FLO_fnc_addWaypoint;
	};
	
	default {
		// Default fallback - basic recon pattern
		[_group, _position, 100, "MOVE", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "[this] call FLO_fnc_reconAreaAction", [30, 60, 90]] call FLO_fnc_addWaypoint;
		
		private _secondObsPoint = _position getPos [200, random 360];
		[_group, _secondObsPoint, -1, "MOVE", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "[this] call FLO_fnc_reconAreaAction; this setVariable ['Flo_Group_orders', nil];", [30, 60, 90]] call FLO_fnc_addWaypoint;
	};
};

true 