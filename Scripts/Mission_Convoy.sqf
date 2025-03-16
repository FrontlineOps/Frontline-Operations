if (ConVLocc == 0) then {
	
	
	sleep 10 ;	
			
	_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
	_mrkr = _mrkrs select 0;
	_AGGRSCORE = parseNumber (markerText _mrkr) ;  
			

			_allZoneMarks = allMapMarkers select {markerType _x == "loc_Power" || markerType _x == "o_support" || markerType _x == "o_maint" || markerType _x == "n_support" || markerType _x == "loc_Ruin" || markerType _x == "n_installation" || markerType _x == "o_installation"} ;  
			_AssltDestMrks = allMapMarkers select {markerType _x == "b_installation"  && (markerColor _x == "ColorYellow" or  markerColor _x == "colorBLUFOR")};  

			_DSTall = [] ;
			
				{
					for "_i" from 0 to count _AssltDestMrks -1 do { 
					_DSTach = getMarkerPos ((_AssltDestMrks) select _i) distanceSqr (getMarkerPos _x) ;
					_DSTall append [_DSTach] ;
					}; 
				} forEach _allZoneMarks ;

			_DSTall sort true;
			_DSneeded = _DSTall select 0 ;
			_OBJmrk = [] ; 
			_Destmrk = [] ;
			
				{
					
						for "_i" from 0 to count _AssltDestMrks -1 do { 
					_DSTach = getMarkerPos ((_AssltDestMrks) select _i) distanceSqr (getMarkerPos _x) ;
					if (_DSTach == _DSneeded) then {_Destmrk append [((_AssltDestMrks) select _i)]} ;
					if (_DSTach == _DSneeded) then {_OBJmrk append [_x]} ;
						};
				} forEach _allZoneMarks ;	

			_OBJ =  _OBJmrk select 0;
			_Dest = _Destmrk select 0;
			
			_ConOBJs = _allZoneMarks select {(getMarkerPos _OBJmrk) distanceSqr (getMarkerPos _x) > 3000 && (getMarkerPos _Dest) distanceSqr (getMarkerPos _x) > (getMarkerPos _OBJmrk) distanceSqr (getMarkerPos _x)} ;  
			_ConOBJ = selectRandom _ConOBJs ;
			
			_CNTR = (nearestObjects [(getMarkerPos _Dest), ["Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V1_F", "Land_Cargo_House_V3_F", "House"], 300]) select 0 ;

_markerName = "ConvoyStrt" ;  
_mrkr = createMarker [_markerName,  (getMarkerPos _ConOBJ) getPos [(10 + (random 50)), (0 + (random 360))]] ;	
_mrkr setMarkerType "mil_marker_noShadow" ; 
_mrkr setMarkerColor "colorOPFOR" ;  
_mrkr setMarkerText "Convoy Start" ;  
_mrkr setMarkerSize [1.5, 1.5] ;
_mrkr setMarkerAlpha 0.7 ;  

_markerName = "ConvoyDest" ;  
_mrkr = createMarker [_markerName,  (getMarkerPos _OBJ) getPos [(10 + (random 50)), (0 + (random 360))]] ;	
_mrkr setMarkerType "mil_marker_noShadow" ; 
_mrkr setMarkerColor "colorOPFOR" ;  
_mrkr setMarkerText "Convoy End" ;  
_mrkr setMarkerSize [1.5, 1.5] ;
_mrkr setMarkerAlpha 0.7 ;  

	["showNotification", ["! WARNING !", "Intel Suggests Enemy Support Convoy Preparing to Move!", "warning"]] call FLO_fnc_intelSystem;

	sleep 600 ;
		["showNotification", ["! WARNING !", "Enemy Support Convoy Mobilizing To Reinforce Their Forces!", "warning"]] call FLO_fnc_intelSystem;


	ConVLocc = 1 ;
	publicVariable "ConVLocc";

/////////////////////Enemy Convoy////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_Chance = selectRandom [1, 2, 3]; 

_CNV = selectRandom ((getMarkerPos "ConvoyStrt") nearRoads 2000) ; 

trg1 = 0;
//////Vehicles/////////////////////////////////////////////////////////////////////////////////////////

_nearRoad = selectRandom ( (getpos _CNV) nearRoads 200 ) ; 
V0 = createVehicle [ selectRandom East_Ground_Vehicles_Light, (_nearRoad getRelPos [0, 0]), [], 10, "NONE"]; 
_azimuth = (getMarkerPos "ConvoyStrt") getDir (getMarkerPos "ConvoyDest") ;
V0 setDir _azimuth;
_SCount = [(typeOf V0), true] call BIS_fnc_crewCount;
missionNamespace setVariable ["CGM", [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup, true];
{_x moveInAny V0} foreach units CGM;  
V0 setUnloadInCombat [true, false];	


waitUntil {((getMarkerPos "ConvoyStrt") distance (getPos V0)) > 600} ; 


_nearRoad = selectRandom ( (getpos _CNV) nearRoads 200 ) ; 
V1 = createVehicle [ selectRandom East_Ground_Transport, (_nearRoad getRelPos [0, 0]), [], 10, "NONE"]; 
_azimuth = (getMarkerPos "ConvoyStrt") getDir (getMarkerPos "ConvoyDest") ;
V1 setDir _azimuth;
_SCount = [(typeOf V1), true] call BIS_fnc_crewCount;
_CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
{_x moveInAny V1} foreach units _CG;  
V1 setUnloadInCombat [true, false];	
{[_x] join CGM} forEach units _CG; 


_nearRoad = selectRandom ( (getpos _CNV) nearRoads 200 ) ; 
V2 = createVehicle [ selectRandom East_Ground_Vehicles_Light, (_nearRoad getRelPos [0, 0]), [], 10, "NONE"]; 
_azimuth = (getMarkerPos "ConvoyStrt") getDir (getMarkerPos "ConvoyDest") ;
V2 setDir _azimuth;
_SCount = [(typeOf V2), true] call BIS_fnc_crewCount;
_CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
{_x moveInAny V2} foreach units _CG;  
V2 setUnloadInCombat [true, false];	
{[_x] join CGM} forEach units _CG; 

 
if (_AGGRSCORE > 5) then {
_nearRoad = selectRandom ( (getpos _CNV) nearRoads 200 ) ; 
V3 = createVehicle [ selectRandom East_Ground_Transport, (_nearRoad getRelPos [0, 0]), [], 10, "NONE"]; 
_azimuth = (getMarkerPos "ConvoyStrt") getDir (getMarkerPos "ConvoyDest") ;
V3 setDir _azimuth;
_SCount = [(typeOf V3), true] call BIS_fnc_crewCount;
_CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
{_x moveInAny V3} foreach units _CG;  
V3 setUnloadInCombat [true, false];	
{[_x] join CGM} forEach units _CG; 


_nearRoad = selectRandom ( (getpos _CNV) nearRoads 200 ) ; 
V4 = createVehicle [ selectRandom East_Ground_Vehicles_Light, (_nearRoad getRelPos [0, 0]), [], 10, "NONE"]; 
_azimuth = (getMarkerPos "ConvoyStrt") getDir (getMarkerPos "ConvoyDest") ;
V4 setDir _azimuth;
_SCount = [(typeOf V4), true] call BIS_fnc_crewCount;
_CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
{_x moveInAny V4} foreach units _CG;  
V4 setUnloadInCombat [true, false];	
{[_x] join CGM} forEach units _CG; 

};


if (_AGGRSCORE > 10) then {
_nearRoad = selectRandom ( (getpos _CNV) nearRoads 200 ) ; 
V5 = createVehicle [ selectRandom East_Ground_Transport, (_nearRoad getRelPos [0, 0]), [], 10, "NONE"]; 
_azimuth = (getMarkerPos "ConvoyStrt") getDir (getMarkerPos "ConvoyDest") ;
V5 setDir _azimuth;
_SCount = [(typeOf V5), true] call BIS_fnc_crewCount;
_CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
{_x moveInAny V5} foreach units _CG;  
V5 setUnloadInCombat [true, false];	
{[_x] join CGM} forEach units _CG; 

if ( ARMDIS == 0 ) then {
_nearRoad = selectRandom ( (getpos _CNV) nearRoads 200 ) ; 
V6 = createVehicle [ selectRandom East_Ground_Vehicles_Light, (_nearRoad getRelPos [0, 0]), [], 10, "NONE"]; 
_azimuth = (getMarkerPos "ConvoyStrt") getDir (getMarkerPos "ConvoyDest") ;
V6 setDir _azimuth;
_SCount = [(typeOf V6), true] call BIS_fnc_crewCount;
_CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
{_x moveInAny V6} foreach units _CG;  
V6 setUnloadInCombat [true, false];	
{[_x] join CGM} forEach units _CG; 
	};
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

{_x addEventHandler ["Killed", {
_Veh = nearestObjects [(_this select 0),["LandVehicle"],100] select 0; 
 	ConVLocc = 0.5 ;
	publicVariable 'ConVLocc';
{_x removeAllEventHandlers "Killed";
  [_x] ordergetin false; 
  [_x] allowGetIn false; 
  unassignvehicle _x;  
 doGetOut _x;  
_x allowDammage true;
 } foreach units group ((crew _Veh) select 0); 
 [50] call FLO_fnc_addReward;
deleteMarker 'ConvoyStrt' ;
deleteMarker 'ConvoyDest' ;

				[50, "SUPPORT CONVOY"] call FLO_fnc_notification;


if (alive V0) then {
_mrkr = createMarker [str getpos V0 ,  getpos V0] ;	
_mrkr setMarkerType "mil_marker_noShadow" ; 
_mrkr setMarkerText "DESTROY" ; 
_mrkr setMarkerColor "colorOPFOR" ;  
_mrkr setMarkerSize [0.9, 0.9] ;
_mrkr setMarkerAlpha 0.7 ;  
V0 addEventHandler ["Killed", {
_MMarks = allMapMarkers select { markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
_M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;
deleteMarker _M ; 
	}];
};

if (alive V1) then {
_mrkr = createMarker [str getpos V1 ,  getpos V1] ;	
_mrkr setMarkerType "mil_marker_noShadow" ; 
_mrkr setMarkerText "DESTROY" ; 
_mrkr setMarkerColor "colorOPFOR" ;  
_mrkr setMarkerSize [0.9, 0.9] ;
_mrkr setMarkerAlpha 0.7 ;  
V1 addEventHandler ["Killed", {
_MMarks = allMapMarkers select { markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
_M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;
deleteMarker _M ; 
	}];
};

if (alive V2) then {
_mrkr = createMarker [str getpos V2 ,  getpos V2] ;	
_mrkr setMarkerType "mil_marker_noShadow" ; 
_mrkr setMarkerText "DESTROY" ; 
_mrkr setMarkerColor "colorOPFOR" ;  
_mrkr setMarkerSize [0.9, 0.9] ;
_mrkr setMarkerAlpha 0.7 ;  
V2 addEventHandler ["Killed", {
_MMarks = allMapMarkers select { markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
_M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;
deleteMarker _M ; 
	}];
};

if (alive V3) then {
_mrkr = createMarker [str getpos V3 ,  getpos V3] ;	
_mrkr setMarkerType "mil_marker_noShadow" ; 
_mrkr setMarkerText "DESTROY" ; 
_mrkr setMarkerColor "colorOPFOR" ;  
_mrkr setMarkerSize [0.9, 0.9] ;
_mrkr setMarkerAlpha 0.7 ;  
V3 addEventHandler ["Killed", {
_MMarks = allMapMarkers select { markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
_M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;
deleteMarker _M ; 
	}];
};

if (alive V4) then {
_mrkr = createMarker [str getpos V4 ,  getpos V4] ;	
_mrkr setMarkerType "mil_marker_noShadow" ; 
_mrkr setMarkerText "DESTROY" ; 
_mrkr setMarkerColor "colorOPFOR" ;  
_mrkr setMarkerSize [0.9, 0.9] ;
_mrkr setMarkerAlpha 0.7 ;  
V4 addEventHandler ["Killed", {
_MMarks = allMapMarkers select { markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
_M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;
deleteMarker _M ; 
	}];
};

if (alive V5) then {
_mrkr = createMarker [str getpos V5 ,  getpos V5] ;	
_mrkr setMarkerType "mil_marker_noShadow" ; 
_mrkr setMarkerText "DESTROY" ; 
_mrkr setMarkerColor "colorOPFOR" ;  
_mrkr setMarkerSize [0.9, 0.9] ;
_mrkr setMarkerAlpha 0.7 ;  
V5 addEventHandler ["Killed", {
_MMarks = allMapMarkers select { markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
_M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;
deleteMarker _M ; 
	}];
};

if (alive V6) then {
_mrkr = createMarker [str getpos V6 ,  getpos V6] ;	
_mrkr setMarkerType "mil_marker_noShadow" ; 
_mrkr setMarkerText "DESTROY" ; 
_mrkr setMarkerColor "colorOPFOR" ;  
_mrkr setMarkerSize [0.9, 0.9] ;
_mrkr setMarkerAlpha 0.7 ;  
V6 addEventHandler ["Killed", {
_MMarks = allMapMarkers select { markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
_M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;
deleteMarker _M ; 
	}];
};
	
	
}]; } foreach units CGM;     

//////Intels/////////////////////////////////////////////////////////////////////////////////////////
_TRGT = createTrigger ["EmptyDetector", [0,0,0]];  
_TRGT setTriggerArea [1, 1, 0, false, 1];  
_TRGT setTriggerActivation ["NONE", "PRESENT", false];
_TRGT setTriggerStatements [  
"!alive V0 && !alive V1 && !alive V2 && !alive V3 && !alive V4 && !alive V5 && !alive V6", 
" 
 [100] call FLO_fnc_addReward;

				[100, 'SUPPORT CONVOY'] call FLO_fnc_notification;
 
 	ConVLocc = 0 ;
	publicVariable 'ConVLocc';

 
 ", ""]; 
/////////////////////////////////////////////////////////////////////////////////////////

_INTSTF = [
"FlashDisk",
"FilesSecret",
"SmartPhone",
"DocumentsSecret"
];

_INTENMALL = units CGM;
_INTENMCNT = count _INTENMALL;
_INTENMCNTNEW = round ( _INTENMCNT / 2 );
_INTENMALLNEW = _INTENMALL call BIS_fnc_arrayShuffle;
_INTENMSEL = _INTENMALLNEW select [0, _INTENMCNTNEW];

{_x addItem selectRandom _INTSTF ;} foreach _INTENMSEL;


};