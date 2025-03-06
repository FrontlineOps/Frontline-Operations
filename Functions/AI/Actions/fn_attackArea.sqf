/* ----------------------------------------------------------------------------
Function: FLO_fnc_attackArea

Description:
    A function for a group to attack a specified area. Behavior varies based on unit type.

Parameters:
    - Group (Group or Object)
    - Position (XYZ, Object, Location or Group)

Example:
    (begin example)
    [_group, _targetPosition] call FLO_fnc_attackArea
    (end)

Returns:
    None

Author:
    Azraeelian Angel
---------------------------------------------------------------------------- */

params ["_group","_currentArea"];

private _type = [vehicle (leader _group)] call FLO_fnc_getTargetType;

switch (_type) do {
	case "MAN" : {
		private _dist = (leader _group) distance2d _currentArea;
		private _dir = (leader _group) getdir _currentArea;
		[_group, (leader _group) getrelpos [_dist*0.85,_dir], random [30,50,100], "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN"] call FLO_fnc_addWaypoint;
		[_group,_currentArea,random [30,45,100],false] call FLO_fnc_taskAttack;
	};
	
	case "UAV" ;
	case "HELI" ;
	case "PLANE" : {
		[_group, _currentArea , random [50,150,200], "SAD", "AWARE", "WHITE", "NORMAL", "STAG COLUMN","",[120,240,360],50] call FLO_fnc_addWaypoint;
		private _landwp = [_group, getpos leader _group , -1, "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN"] call FLO_fnc_addWaypoint;
		_landWP setwaypointscript "A3\functions_f\waypoints\fn_wpLand.sqf";
	};
	case "MORTAR" ;
	case "AAA" ;
	case "ART" ;
	case "MECH" ;
	case "ARMOR" ;
	case "CAR" ;
	case "SHIP" : {[_group, _currentArea , random [50,150,200], "SAD", "AWARE", "WHITE", "NORMAL", "STAG COLUMN","",[120,240,360],50] call FLO_fnc_addWaypoint;};
}; 