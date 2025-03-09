 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
  _BunkMarks = allMapMarkers select {markerType _x == "loc_Bunker" && markerAlpha _x == 0.003};  
{deleteMarker _x ;} forEach _BunkMarks ;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _headlessClients = entities "HeadlessClient_F";
private _humanPlayers = allPlayers - _headlessClients;

if (count _humanPlayers > 0) then {

       _mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
       _mrkr = _mrkrs select 0;
       _AGGRSCORE = parseNumber (markerText _mrkr) ;  
       
	   _AssltDestMrks = allMapMarkers select {markerType _x == "b_installation" && markerText _x == "FOB"};
	   _AssltDest = selectRandom _AssltDestMrks ; 
	   
		_allZoneMarks = allMapMarkers select {markerType _x == "loc_Power" || markerType _x == "o_support" || markerType _x == "n_support" || markerType _x == "loc_Ruin" || markerType _x == "n_installation" || markerType _x == "o_installation"} ;  
       _AssStartMrk = [_allZoneMarks,  getMarkerPos _AssltDest] call BIS_fnc_nearestPosition ;


_Distance = (getMarkerPos _AssStartMrk) distance2D (getMarkerPos _AssltDest) ;
_nearRoadDes = (getMarkerPos _AssltDest)  nearRoads _Distance ;
_nearRoadStr = (getMarkerPos _AssStartMrk) nearRoads _Distance ;

_OutRoads = _nearRoadDes - _nearRoadStr ; 
_InRoads = _nearRoadDes - _OutRoads;

_HalfDistance = round ( _Distance / 2 ); 
_nearDesRoads = (getMarkerPos _AssltDest) nearRoads _HalfDistance ;
_FinalRoads = _InRoads - _nearDesRoads ;

			_CNTR = (nearestObjects [(getMarkerPos _AssltDest), ["Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V1_F", "Land_Cargo_House_V3_F", "House"], 300]) select 0 ;

ENMASSMAINmarkerName = "AssltDest" + (str ((getPos TheCommander) getPos [(10 + (random 150)), (0 + (random 360))]));   
 publicVariable "ENMASSMAINmarkerName"; 

createMarker [ENMASSMAINmarkerName, (getPos _CNTR)] ;
ENMASSMAINmarkerName setMarkerType "mil_marker_noShadow" ; 
ENMASSMAINmarkerName setMarkerColor "colorOPFOR" ;  
ENMASSMAINmarkerName setMarkerSize [2, 2] ;
ENMASSMAINmarkerName setMarkerAlpha 0.5 ;  

["showNotification", ["! WARNING !", "Intel Suggests There is a Large Enemy Combined Group Preparing to Attack!", "warning"]] call FLO_fnc_intelSystem;


sleep 1.5 ;



sleep 600 ;



["showNotification", ["! WARNING !", "Reports Confirm Enemy Forces are Mobilizing, Prepare for Combat!", "warning"]] call FLO_fnc_intelSystem;
_attackingAtGrid = mapGridPosition getMarkerPos ENMASSMAINmarkerName;
[[west,"HQ"], "Friendly Location Under Enemy attack at grid " + _attackingAtGrid] remoteExec ["sideChat", 0];


playMusic "LeadTrack05_F_Tank";

_azimuth = (getMarkerPos "AssltDest") getDir (getMarkerPos _AssStartMrk);
_nearRoad2 =(getMarkerPos "AssltDest") nearRoads 2500 ; 
_nearRoad1 = (getMarkerPos "AssltDest") nearRoads 1000 ; 

_nearRoadleft = _nearRoad2 - _nearRoad1;

PRL = [(getMarkerPos "AssltDest") getPos [(500 + (random 1000)), (_azimuth + (random 20))] , East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
WP_1 = PRL addWaypoint [getMarkerPos "AssltDest", 0]; 
WP_1 SetWaypointType "MOVE"; 


if ( INFDIS == 0 ) then {
PRL = [(getMarkerPos "AssltDest") getPos [(500 + (random 1000)), (_azimuth - (random 20))] , East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
WP_1 = PRL addWaypoint [getMarkerPos "AssltDest", 0]; 
WP_1 SetWaypointType "MOVE"; 
};


[_CNTR] execVM "Scripts\VehiInsert_CSAT.sqf";
[_CNTR] execVM "Scripts\HeliInsert_CSAT.sqf";


_nearstRoad = selectRandom _nearRoadleft ;
_nearRoad = selectRandom (_nearstRoad nearRoads 1500 ) ; 
 _VEH = createVehicle [selectRandom East_Ground_Vehicles_Heavy, (getPosATL _nearRoad), [], 2, "NONE"];
_Group = createVehicleCrew _VEH; 
_VC = createGroup East;
{[_x] join _VC} forEach units _Group;

_W_1 = _VC addWaypoint [(getMarkerPos "AssltDest"), 0];
_W_1 SetWaypointType "MOVE";
_W_1 setWaypointBehaviour "AWARE";
_W_1 setWaypointSpeed "FULL";


_nearstRoad = selectRandom _nearRoadleft ;
_nearRoad = selectRandom (_nearstRoad nearRoads 1500 ) ; 
 _VEH = createVehicle [selectRandom East_Ground_Vehicles_Heavy, (getPosATL _nearRoad), [], 2, "NONE"];
_Group = createVehicleCrew _VEH; 
_VC = createGroup East;
{[_x] join _VC} forEach units _Group;

_W_1 = _VC addWaypoint [(getMarkerPos "AssltDest"), 0];
_W_1 SetWaypointType "MOVE";
_W_1 setWaypointBehaviour "AWARE";
_W_1 setWaypointSpeed "FULL";



_nearstRoad = selectRandom _nearRoadleft ;
_nearRoad = selectRandom (_nearstRoad nearRoads 1500 ) ; 
_V = createVehicle [selectRandom East_Air_Heli, (getPosATL _nearRoad), [], 500, "FLY"]; 
_Group = createVehicleCrew _V; 
_VC = createGroup East;
{[_x] join _VC} forEach units _Group;
_W_1 = _VC addWaypoint [(getMarkerPos "AssltDest"), 0];
_W_1 SetWaypointType "MOVE";
_W_1 setWaypointBehaviour "AWARE";

_V flyInHeight 100; 
_V disableAI "LIGHTS"; 
_V setPilotLight true;
_V setCollisionLight true; 







if (_AGGRSCORE > 5) then {
_nearstRoad = selectRandom _nearRoadleft; 

PRL = [(getMarkerPos "AssltDest") getPos [(500 + (random 1000)), (_azimuth + (random 20))] , East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
WP_1 = PRL addWaypoint [getMarkerPos "AssltDest", 0]; 
WP_1 SetWaypointType "MOVE"; 



	
[_CNTR] execVM "Scripts\VehiInsert_CSAT.sqf";
[_CNTR] execVM "Scripts\HeliInsert_CSAT.sqf";


_nearstRoad = selectRandom _nearRoadleft ;
_nearRoad = selectRandom (_nearstRoad nearRoads 1500 ) ; 
 _VEH = createVehicle [selectRandom East_Ground_Vehicles_Heavy, (getPosATL _nearRoad), [], 2, "NONE"];
_Group = createVehicleCrew _VEH; 
_VC = createGroup East;
{[_x] join _VC} forEach units _Group;

_W_1 = _VC addWaypoint [(getMarkerPos "AssltDest"), 0];
_W_1 SetWaypointType "MOVE";
_W_1 setWaypointBehaviour "AWARE";
_W_1 setWaypointSpeed "FULL";



_nearstRoad = selectRandom _nearRoadleft ;
_nearRoad = selectRandom (_nearstRoad nearRoads 1500 ) ; 
_V = createVehicle [selectRandom East_Air_Heli, (getPosATL _nearRoad), [], 500, "FLY"]; 
_Group = createVehicleCrew _V; 
_VC = createGroup East;
{[_x] join _VC} forEach units _Group;
_W_1 = _VC addWaypoint [(getMarkerPos "AssltDest"), 0];
_W_1 SetWaypointType "MOVE";
_W_1 setWaypointBehaviour "AWARE";

_V flyInHeight 100; 
_V disableAI "LIGHTS"; 
_V setPilotLight true;
_V setCollisionLight true; 

};


if (_AGGRSCORE > 10) then {
PRL = [(getMarkerPos "AssltDest") getPos [(500 + (random 1000)), (_azimuth + (random 20))] , East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
WP_1 = PRL addWaypoint [getMarkerPos "AssltDest", 0]; 
WP_1 SetWaypointType "MOVE"; 





[_CNTR] execVM "Scripts\VehiInsert_CSAT.sqf";
[_CNTR] execVM "Scripts\HeliInsert_CSAT.sqf";

_nearstRoad = selectRandom _nearRoadleft ;
_nearRoad = selectRandom (_nearstRoad nearRoads 1500 ) ; 
 _VEH = createVehicle [selectRandom East_Ground_Vehicles_Heavy, (getPosATL _nearRoad), [], 2, "NONE"];
_Group = createVehicleCrew _VEH; 
_VC = createGroup East;
{[_x] join _VC} forEach units _Group;

_W_1 = _VC addWaypoint [(getMarkerPos "AssltDest"), 0];
_W_1 SetWaypointType "MOVE";
_W_1 setWaypointBehaviour "AWARE";
_W_1 setWaypointSpeed "FULL";



_nearstRoad = selectRandom _nearRoadleft ;
_nearRoad = selectRandom (_nearstRoad nearRoads 1500 ) ; 
_V = createVehicle [selectRandom East_Air_Heli, (getPosATL _nearRoad), [], 500, "FLY"]; 
_Group = createVehicleCrew _V; 
_VC = createGroup East;
{[_x] join _VC} forEach units _Group;
_W_1 = _VC addWaypoint [(getMarkerPos "AssltDest"), 0];
_W_1 SetWaypointType "MOVE";
_W_1 setWaypointBehaviour "AWARE";

_V flyInHeight 100; 
_V disableAI "LIGHTS"; 
_V setPilotLight true;
_V setCollisionLight true; 



_nearstRoad = selectRandom _nearRoadleft ;
_nearRoad = selectRandom (_nearstRoad nearRoads 100 ) ; 
_V = createVehicle [selectRandom East_Air_Heli, (getPosATL _nearRoad), [], 500, "FLY"]; 
_Group = createVehicleCrew _V; 
_VC = createGroup East;
{[_x] join _VC} forEach units _Group;
_W_1 = _VC addWaypoint [(getMarkerPos "AssltDest"), 0];
_W_1 SetWaypointType "MOVE";
_W_1 setWaypointBehaviour "AWARE";

_V flyInHeight 100; 
_V disableAI "LIGHTS"; 
_V setPilotLight true;
_V setCollisionLight true; 



    };

sleep 300 ;

deleteMarker "AssltDest"; 

};












