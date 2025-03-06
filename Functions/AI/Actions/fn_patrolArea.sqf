/* ----------------------------------------------------------------------------
Function: FLO_fnc_patrolArea

Description:
    A function for a group to patrol a specified area. Behavior varies based on unit type.
    Infantry will do ground patrols, aircraft will do fly-by patrols, and vehicles will
    cover the perimeter with search and destroy missions.

Parameters:
    - Group (Group or Object)
    - Position (XYZ, Object, Location or Group)

Example:
    (begin example)
    [_group, _areaToPatrol] call FLO_fnc_patrolArea
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
		[_group, _currentArea, random [50,250,500], ceil(random [3,5,10]), "MOVE", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN", "[group this] call CBA_fnc_searchNearby", [3, 6, 9]] call FLO_fnc_taskPatrol;
		private _landwp = [_group, getpos leader _group , -1, "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN","[group this] call CBA_fnc_searchNearby;this setVariable [""Flo_Group_orders"",nil];"] call FLO_fnc_addWaypoint;
	};
	
	case "UAV" ;
	case "HELI" ;
	case "PLANE" : {
		[_group, _currentArea , random [50,150,200], "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN","",[0,0,0],50] call FLO_fnc_addWaypoint;
		[_group, _currentArea , random [50,1050,3000], "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN","",[0,0,0],50] call FLO_fnc_addWaypoint;
		[_group, _currentArea , random [50,1050,3000], "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN","",[0,0,0],50] call FLO_fnc_addWaypoint;
		private _landwp = [_group, getpos leader _group , -1, "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN","this setVariable [""Flo_Group_orders"",nil]"] call FLO_fnc_addWaypoint;
		_landWP setwaypointscript "A3\functions_f\waypoints\fn_wpLand.sqf";
	};
	case "MORTAR" ;
	case "AAA" ;
	case "ART" ;
	case "MECH" ;
	case "ARMOR" ;
	case "CAR" ;
	case "SHIP" : {
		[_group, [_currentArea,50,200,5,0,0,0,[],[_currentArea getpos [random 200,random 360],[]]] call BIS_fnc_findSafePos, -1, "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN","[this] call FLO_fnc_reconAreaAction",[120,240,360],50] call FLO_fnc_addWaypoint;
		[_group, [_currentArea,50,3000,5,0,0,0,[],[_currentArea getpos [random 2000,random 360],[]]] call BIS_fnc_findSafePos, -1, "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN","[this] call FLO_fnc_reconAreaAction",[120,240,360],50] call FLO_fnc_addWaypoint;
		[_group, [_currentArea,50,3000,5,0,0,0,[],[_currentArea getpos [random 2000,random 360],[]]] call BIS_fnc_findSafePos, -1, "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN","[this] call FLO_fnc_reconAreaAction; this setVariable [""Flo_Group_orders"",nil]",[120,240,360],50] call FLO_fnc_addWaypoint;};
}; 