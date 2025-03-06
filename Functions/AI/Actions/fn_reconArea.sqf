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

Example:
    (begin example)
    [_group, _areaToRecon] call FLO_fnc_reconArea
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
		[_group, _currentArea, random [50,150,200], ceil(random [4,5,7]), "MOVE", "STEALTH", "WHITE", "NORMAL", "STAG COLUMN", "[this] call FLO_fnc_reconAreaAction", [300, 600, 900]] call FLO_fnc_taskPatrol;
		[_group, (leader _group) getrelpos [_dist*0.1,_dir], random [50,150,200], "MOVE", "AWARE", "WHITE", "NORMAL", "STAG COLUMN","this setVariable [""Flo_Group_orders"",nil]"] call FLO_fnc_addWaypoint;
		};
	
	case "UAV" ;
	case "HELI" ;
	case "PLANE" : {
		[_group, _currentArea , random [50,150,200], "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN","[this] call FLO_fnc_reconAreaAction",[0,0,0],50] call FLO_fnc_addWaypoint;
		[_group, _currentArea , random [50,1050,3000], "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN","[this] call FLO_fnc_reconAreaAction",[0,0,0],50] call FLO_fnc_addWaypoint;
		[_group, _currentArea , random [50,1050,3000], "SAD", "AWARE", "YELLOW", "LIMITED", "STAG COLUMN","[this] call FLO_fnc_reconAreaAction",[0,0,0],50] call FLO_fnc_addWaypoint;
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