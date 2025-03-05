
_Centerposition = [worldSize / 2, worldsize / 2, 0];

_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 40000]; 
_objectCountFull = count _objectLoc;
_objectCount = round ( _objectCountFull / 1.5 );
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{if (count (nearestObjects [(getPos _x), ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"], 1500]) > 0) then {
_Tower =  selectRandom nearestObjects [(getPos _x), ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"], 1500]  ;
_markerName = "TowerMark" + (str (getPos _x));  
_mrkr = createMarker [_markerName,getPos _Tower];   
_mrkr setMarkerType "loc_Transmitter";
_mrkr setMarkerColor "colorOPFOR";
_mrkr setMarkerSize [1, 1]; 
_mrkr setMarkerAlpha 1; 

};}forEach _allobjectsNew; 


{if (count (nearestObjects [(getPos _x), ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"], 1500]) == 0) then {
_Mount = selectRandom nearestLocations [getPos _x, ["Mount"], 1500];   
_markerName = "TowerMark" + (str (locationPosition _Mount));  
_mrkr = createMarker [_markerName,locationPosition _Mount];   
_mrkr setMarkerType "loc_Transmitter";
_mrkr setMarkerColor "colorOPFOR";
_mrkr setMarkerSize [1, 1]; 
_mrkr setMarkerAlpha 1;  

_P1 =  ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"]; 	
_TWR = createVehicle [ selectRandom _P1, (locationPosition _Mount), [], 5, "NONE"];
_TWR setVectorUp [0,0,1];

};}forEach _allobjectsNew; 



//////////////////////////////////////////////////////////////////////////////////////////////
_missionTag = missionName;
_missionTag = [_missionTag] call BIS_fnc_filterString;

private _MarkerTimeName = _missionTag + "_Time";
private _MarkerDataName = _missionTag + "_markers";
private _VehicleDataName = _missionTag + "_Vehicles";
private _ObjectDataName = _missionTag + "_Objects";

sleep 2;

profileNamespace setVariable [_MarkerTimeName, nil];
profileNamespace setVariable [_MarkerDataName, nil];
profileNamespace setVariable [_VehicleDataName, nil];
profileNamespace setVariable [_ObjectDataName, nil];

//////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 40000]; 
_objectCountFull = count _objectLoc;
_objectCount = round ( _objectCountFull / 1 );
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{if (count (nearestObjects [(getPos _x), ["Sign_Pointer_Blue_F"], 1500]) > 0) then {
_Factory =  selectRandom nearestObjects [(getPos _x), ["Sign_Pointer_Blue_F"], 1500]  ;
_markerName = "FactMark" + (str (getPos _x));  
_mrkr = createMarker [_markerName,getPos _Factory];   
_mrkr setMarkerType "o_support";
_mrkr setMarkerColor "colorOPFOR";
_mrkr setMarkerSize [1.2, 1.2]; 
_mrkr setMarkerAlpha 0.001;

};}forEach _allobjectsNew; 


{if (count (nearestObjects [(getPos _x), ["Sign_Pointer_Blue_F"], 1500]) == 0) then {
_Mount = selectRandom nearestLocations [getPos _x, ["Mount"], 1500];   
_markerName = "TowerMark" + (str (locationPosition _Mount));  
_mrkr = createMarker [_markerName,locationPosition _Mount];   
_mrkr setMarkerType "o_support";
_mrkr setMarkerColor "colorOPFOR";
_mrkr setMarkerSize [1.2, 1.2]; 
_mrkr setMarkerAlpha 0.001;

};}forEach _allobjectsNew; 


//////////////////////////////////////////////////////////////////////////////////////////////
_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 40000]; 
_objectCountFull = count _objectLoc;
_objectCount = round ( _objectCountFull / 1 );
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{if (count (nearestObjects [(getPos _x), ["Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V2_F", "Land_Cargo_Tower_V1_F", "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V1_F"], 1500]) > 0) then {
_Outp =  selectRandom nearestObjects [(getPos _x), ["Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V2_F", "Land_Cargo_Tower_V1_F", "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V1_F"], 1500]  ;
_markerName = "OutpMark" + (str (getPos _x));  
_mrkr = createMarker [_markerName,getPos _Outp];   
_mrkr setMarkerType "o_support";
_mrkr setMarkerColor "colorOPFOR";   
_mrkr setMarkerSize [1.2, 1.2]; 
_mrkr setMarkerAlpha 0.001;  

};}forEach _allobjectsNew; 


{if (count (nearestObjects [(getPos _x), ["Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V2_F", "Land_Cargo_Tower_V1_F", "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V1_F"], 1500]) == 0) then {
_Mount = selectRandom nearestLocations [getPos _x, ["Mount"], 1500];   
_markerName = "OutpMark" + (str (locationPosition _Mount));  
_mrkr = createMarker [_markerName,locationPosition _Mount];   
_mrkr setMarkerType "o_support";
_mrkr setMarkerColor "colorOPFOR";   
_mrkr setMarkerSize [1.2, 1.2]; 
_mrkr setMarkerAlpha 0.001;  

};}forEach _allobjectsNew; 

//////////////////////////////////////////////////////////////////////////////////////////////
sleep 5;

_OutpMarks = allMapMarkers select {markerType _x == "o_support"};
_OutpMarkCountFull = count _OutpMarks;
_OutpMarkCount = round ( _OutpMarkCountFull / 6 );
if (_OutpMarkCount == 0) then {_OutpMarkCount = 1;};
_allobjectsShuffled = _OutpMarks call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _OutpMarkCount];

{ 
_x setMarkerType "n_support";  
_x setMarkerSize [1.4, 1.4];   
_x setMarkerColor "colorOPFOR"; 
_x setMarkerAlpha 1 ; 
   
} forEach _allobjectsNew;  


//////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [_Centerposition, ["Land_InvisibleBarrier_F"], 40000]; 
 _objectCount = count _objectLoc;
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{ 
 
_mrkr = createMarker [str(_x),getPos _x]; 
_mrkr setMarkerType "n_support";  
_mrkr setMarkerSize [1.4, 1.4];   
_mrkr setMarkerColor "colorOPFOR"; 
_mrkr setMarkerAlpha 1 ;  
   
} forEach _allobjectsNew;  



//////////////////////////////////////////////////////////////////////////////////////////////


_objectLoc = nearestobjects [_Centerposition, ["LocationCityCapital_F"], 40000]; 
 _objectCount = count _objectLoc;
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];
{

_mrkr = createMarker [str(_x),getPos _x];
_mrkr setMarkerType "n_installation"; 
_mrkr setMarkerSize [1.4, 1.4];   
_mrkr setMarkerColor "colorOPFOR";  
_mrkr setMarkerAlpha 1 ;
 
} forEach _allobjectsNew; 



//////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [_Centerposition, ["LocationCity_F"], 40000]; 
 _objectCount = count _objectLoc;
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{
_mrkr = createMarker [str(_x),getPos _x];
_mrkr setMarkerType "o_installation"; 
_mrkr setMarkerSize [1.2, 1.2]; 
_mrkr setMarkerColor "colorOPFOR";
_mrkr setMarkerAlpha 0.001;  

} forEach _allobjectsNew; 


//////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 40000]; 
_objectCountFull = count _objectLoc;
_objectCount = round ( _objectCountFull / 2 );
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{if (count (nearestObjects [(getPos _x), ["Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F", "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F", "Land_vn_barracks_01_camo_f", "Land_Barracks_01_camo_F"], 1500]) > 0) then {
_Factory =  selectRandom nearestObjects [(getPos _x), ["Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F", "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F", "Land_vn_barracks_01_camo_f", "Land_Barracks_01_camo_F"], 1500]  ;
_markerName = "BarrackMark" + (str (getPos _x));  
_mrkr = createMarker [_markerName,getPos _Factory ];   
_mrkr setMarkerType "loc_Ruin";  
_mrkr setMarkerColor "colorOPFOR";  
_mrkr setMarkerSize [1.2, 1.2]; 
_mrkr setMarkerAlpha 0.001;  

};}forEach _allobjectsNew; 


{if (count (nearestObjects [(getPos _x), ["Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F", "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F", "Land_vn_barracks_01_camo_f", "Land_Barracks_01_camo_F"], 1500]) == 0) then {
_Mount = selectRandom nearestLocations [getPos _x, ["Mount"], 1500];   
_markerName = "BarrackMark" + (str (locationPosition _Mount));  
_mrkr = createMarker [_markerName,locationPosition _Mount];   
_mrkr setMarkerType "loc_Ruin";  
_mrkr setMarkerColor "colorOPFOR";  
_mrkr setMarkerSize [1.2, 1.2]; 
_mrkr setMarkerAlpha 0.001;  

};}forEach _allobjectsNew; 


//////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 40000]; 
_objectCountFull = count _objectLoc;
_objectCount = round ( _objectCountFull / 2 );
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{if (count (nearestObjects [(getPos _x), ["Land_Radar_F"], 1500]) > 0) then {
_Factory =  selectRandom nearestObjects [(getPos _x), ["Land_Radar_F"], 1500]  ;
_markerName = "RadarSMark" + (str (getPos _x));  
_mrkr = createMarker [_markerName,getPos _Factory ];   
_mrkr setMarkerType "loc_Power";  
_mrkr setMarkerColor "colorOPFOR";  
_mrkr setMarkerSize [1, 1]; 
_mrkr setMarkerAlpha 0.001;    

};}forEach _allobjectsNew; 


{if (count (nearestObjects [(getPos _x), ["Land_Radar_F"], 1500]) == 0) then {
_Mount = selectRandom nearestLocations [getPos _x, ["Mount"], 1500];   
_markerName = "RadarSMark" + (str (locationPosition _Mount));  
_mrkr = createMarker [_markerName,locationPosition _Mount];   
_mrkr setMarkerType "loc_Power";  
_mrkr setMarkerColor "colorOPFOR";  
_mrkr setMarkerSize [1, 1]; 
_mrkr setMarkerAlpha 0.001;  

};}forEach _allobjectsNew; 




//////////////////////////////////////////////////////////////////////////////////////////////


_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 40000]; 
_objectCountFull = count _objectLoc;
_objectCount = round ( _objectCountFull / 1 );
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{ 
_Mount = selectRandom nearestLocations [(getPos _x), ["Mount"], 2000];
_markerName = "InvesMark" + (str (getPos _x));   
_mrkr = createMarker [_markerName, locationPosition _Mount];   
_mrkr setMarkerType "o_recon";  
_mrkr setMarkerColor "colorOPFOR";  
_mrkr setMarkerSize [0.8, 0.8]; 
_mrkr setMarkerAlpha 0.001;  

} foreach _allobjectsNew;

//////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 40000]; 
_objectCountFull = count _objectLoc;
_objectCount = round ( _objectCountFull / 1 );
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{ 
_pos = [ getPos _x, 10, 2000, 3, 0, 1, 0] call BIS_fnc_findSafePos;
_markerName = "MineMark" + (str (getPos _x));
_mrkr = createMarker [_markerName, _pos];
_mrkr setMarkerType "loc_mine"; 
_mrkr setMarkerSize [1, 1];  
_mrkr setMarkerColor "colorOPFOR";  
_mrkr setMarkerAlpha 0.001;

} foreach _allobjectsNew;



sleep 3;

_objectLocT = allMapMarkers select { markerType _x == 'loc_mine' };
	{
if (count (nearestobjects [(getMarkerPos _x), ["LocationVillage_F", "LocationCity_F", "LocationCityCapital_F"], 400]) > 0) then { 
deleteMarker _x ; 

};} foreach _objectLocT;

//////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 40000]; 
_objectCountFull = count _objectLoc;
_objectCount = round ( _objectCountFull / 2 );
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{ 
_nearRoad = selectRandom ((getPos _x) nearRoads 3500) ; 
_markerName = "ArmorMark" + (str (getPos _x));
_mrkr = createMarker [_markerName, getPos _nearRoad];   
_mrkr setMarkerType "o_armor";  
_mrkr setMarkerColor "colorOPFOR";  
_mrkr setMarkerSize [1.2, 1.2];   
_mrkr setMarkerAlpha 0.001;  

} foreach _allobjectsNew;

_objectLoc = nearestobjects [_Centerposition, ["Sign_Pointer_Cyan_F"], 40000]; 


if (count _objectLoc > 0) then {
	
_objectLoc = nearestobjects [_Centerposition, ["Sign_Pointer_Cyan_F"], 40000]; 
	
_objectCountFull = count _objectLoc;
_objectCountNew = round ( _objectCountFull / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];
		
		{ 

_markerName = "ArmorMark" + (str (getPos _x));
_mrkr = createMarker [_markerName, getPos _x];   
_mrkr setMarkerType "o_armor";  
_mrkr setMarkerColor "colorOPFOR";  
_mrkr setMarkerSize [1.2, 1.2];   
_mrkr setMarkerAlpha 0.001;  


		} foreach _allobjectsNew;
	
};

//////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 40000]; 
_objectCount = count _objectLoc;
_objectCountNew = round ( _objectCount / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];
{ 
_nearRoad = selectRandom ( (getPos _x) nearRoads 2500 ) ; 
_mrkr = createMarker [str(_nearRoad), getPos _nearRoad];   
_mrkr setMarkerType "o_service";  
_mrkr setMarkerColor "colorOPFOR"; 
_mrkr setMarkerSize [0.8, 0.8]; 
_mrkr setMarkerAlpha 0.001;  

} foreach _allobjectsNew;


//////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [_Centerposition, ["LocationVillage_F"], 40000]; 

{
_markerName = "InsurVillMark" + (str (_x getPos [(0 +(random 100)), (0 + (random 360))])) ;  
_mrkr = createMarker [_markerName, (getPos _x)] ;   
_mrkr setMarkerType "o_inf"; 
_mrkr setMarkerSize [0.7, 0.7]; 
_mrkr setMarkerColor "colorOPFOR";
_mrkr setMarkerAlpha 0.001;  

} forEach _objectLoc; 


//////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 40000]; 
_objectCount = count _objectLoc;
_AASlash = round ( _objectCount / 2 );
_objectCountNew = round ( _AASlash / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{ 
_Mount = selectRandom nearestLocations [(getPos _x), ["Mount"], 2000];
_markerName = "AAMark" + (str (getPos _x));   
_mrkr = createMarker [_markerName, locationPosition _Mount];   
_mrkr setMarkerType "o_antiair";  
_mrkr setMarkerColor "colorOPFOR";  
_mrkr setMarkerSize [1.2, 1.2]; 
_mrkr setMarkerAlpha 0.001;  

} foreach _allobjectsNew;
//////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 40000];  
_objectCount = count _objectLoc;
_AASlash = round ( _objectCount / 2 );
_objectCountNew = round ( _AASlash / EnemyPrec );
if (_objectCountNew == 0) then {_objectCountNew = 1;};
_allobjectsShuffled = _objectLoc call BIS_fnc_arrayShuffle;
_allobjectsNew = _allobjectsShuffled select [0, _objectCountNew];

{  
_markName = "marker" + (str(_forEachIndex + 1)); 
_mrkr = createMarker [_markName, _x getPos [(0 + (random 300)), (0 + (random 350))]];    
_mrkr setMarkerType "o_plane";   
_mrkr setMarkerColor "colorOPFOR";   
_mrkr setMarkerSize [1, 1]; 
_mrkr setMarkerAlpha 0.001;   
    
} foreach _allobjectsNew;
//////////////////////////////////////////////////////////////////////////////////////////////

sleep 2;

_AllMarks = allMapMarkers select {markerType _x == "o_support" or markerType _x == "n_support" or markerType _x == "o_installation" or markerType _x == "n_installation" or markerType _x == "o_antiair" or markerType _x == "o_armor" or markerType _x == "o_service" or markerType _x == "o_plane" or markerType _x == "o_maint" or markerType _x == "loc_mine" or markerType _x == "loc_Power" or markerType _x == "loc_Ruin" or markerType _x == "mil_unknown" or markerType _x == "mil_warning" or markerType _x == "o_naval" or markerType _x == "o_recon" or markerType _x == "o_inf" };     
_AllMarksNear = _AllMarks select {getPos TheCommander distance getMarkerpos _x < 2000};
	{  
deleteMarker _x ; 
	} forEach _AllMarksNear;


sleep 2;

_markerName = "respawn_west" + (str (position player));  
_mrkr = createMarker [_markerName, (position player)];  
_mrkr setMarkerType "b_unknown";
_mrkr setMarkerSize [0.6, 0.6]; 
_mrkr setMarkerText "Respawn"; 
_mrkr setMarkerAlpha 1;
 


MarLOCC = 1;
publicVariable "MarLOCC";


