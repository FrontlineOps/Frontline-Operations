/////////////////////Rescue POW////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
thisPOWTrigger = _this select 0; 

_Chance = selectRandom [1, 2, 3]; 
 
 _mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  
//////OBJECTIVE/////////////////////////////////////////////////////////////////////////////////////////
sleep 15 ; 
waitUntil { count (nearestobjects [thisPOWTrigger, ["Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F", "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F", "Land_vn_barracks_01_camo_f", "Land_Barracks_01_camo_F"], 400]) > 0};

_Position = nearestObjects [thisPOWTrigger, ["Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F", "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F", "Land_vn_barracks_01_camo_f", "Land_Barracks_01_camo_F"], 400] select 0;  

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

[thisPOWTrigger] execVM "Scripts\HMGspawn.sqf" ; 

//////Garrisons/////////////////////////////////////////////////////////////////////////////////////////


_Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom East_Units_Officers]] call BIS_fnc_spawnGroup;     
_OFC = ((units G) select 0) ;
_OFC disableAI "PATH";
[ 
 _OFC,            
 "Search Officer",           
 "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa",  
 "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa",  
 "(_this distance _target)<2",       
 "(_this distance _target)<2",       
 { 
 playSound3D [ "a3\missions_f_oldman\data\sound\intel_body\1sec\intel_body_1sec_02.wss", (_this select 0)];  
  
 },             
 {},              
 {  
 
[] call FLO_fnc_militaryIntel;
 
 },    
 {},              
 [],             
 3,            
 0,             
 true,             
 false             
] remoteExec ["BIS_fnc_holdActionAdd", 0, _OFC]; 
 
_Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;     
 ((units G) select 0) disableAI "PATH";
 			G deleteGroupWhenEmpty true;

 _Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;     
			G deleteGroupWhenEmpty true;




if (_AGGRSCORE > 5) then {
_Pos = selectRandom (_Position buildingPos -1);
G = [_Pos, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;   
 ((units G) select 0) disableAI "PATH";
 			G deleteGroupWhenEmpty true;

  _Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;     
			G deleteGroupWhenEmpty true;

};

if (_AGGRSCORE > 10) then {
_Pos = selectRandom (_Position buildingPos -1);
G = [_Pos, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;     
((units G) select 0) disableAI "PATH";
			G deleteGroupWhenEmpty true;

 _Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;     
			G deleteGroupWhenEmpty true;

};
//////Gaurds/////////////////////////////////////////////////////////////////////////////////////////
//////Gaurds/////////////////////////////////////////////////////////////////////////////////////////



_allBuildings = nearestObjects [(getpos thisPOWTrigger), ["House", "Land_MilOffices_V1_F", "Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V2_F", "Land_Cargo_Tower_V1_F", "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V3_F", "Land_Cargo_House_V1_F"], 300];  
_allPositions = [];  
_allBuildings apply {_allPositions append (_x buildingPos -1)}; 
 

[ "Intel_01", selectRandom _allPositions, [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 
 
G = [selectRandom _allPositions, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH";   
			G deleteGroupWhenEmpty true;
G = [selectRandom _allPositions, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;     
			G deleteGroupWhenEmpty true;
G = [selectRandom _allPositions, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;     
			G deleteGroupWhenEmpty true;
G = [selectRandom _allPositions, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;     
((units G) select 0) disableAI "PATH";
			G deleteGroupWhenEmpty true;

if (_AGGRSCORE > 5) then {
G = [selectRandom _allPositions, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH";   
			G deleteGroupWhenEmpty true;
G = [selectRandom _allPositions, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;     
			G deleteGroupWhenEmpty true;
};

if (_AGGRSCORE > 10) then {
G = [selectRandom _allPositions, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH";   
			G deleteGroupWhenEmpty true;
G = [selectRandom _allPositions, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;     
			G deleteGroupWhenEmpty true;
};

//////Gaurds/////////////////////////////////////////////////////////////////////////////////////////
 

_poss = [getpos thisPOWTrigger, 10, 30, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH"; 
			G deleteGroupWhenEmpty true;

if (_AGGRSCORE > 5) then {
_poss = [getpos thisPOWTrigger, 10, 30, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH"; 
			G deleteGroupWhenEmpty true;
}; 
if (_AGGRSCORE > 10) then {
_poss = [getpos thisPOWTrigger, 10, 30, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH"; 
			G deleteGroupWhenEmpty true;
}; 
 
//////GROUPS/////////////////////////////////////////////////////////////////////////////////////////


PRL = [(getPos thisPOWTrigger) getPos [30, 50], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getpos thisPOWTrigger, 50] call BIS_fnc_taskPatrol;
			PRL deleteGroupWhenEmpty true;

PRL = [(getPos thisPOWTrigger) getPos [30, 50], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getpos thisPOWTrigger, 100] call BIS_fnc_taskPatrol;
			PRL deleteGroupWhenEmpty true;


if (_AGGRSCORE > 5) then {
PRL = [(getPos thisPOWTrigger) getPos [30, 180], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getpos thisPOWTrigger, 200] call BIS_fnc_taskPatrol;
			PRL deleteGroupWhenEmpty true;
};

if (_AGGRSCORE > 10) then {
PRL = [(getPos thisPOWTrigger) getPos [30, 270], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getpos thisPOWTrigger, 200] call BIS_fnc_taskPatrol;
			PRL deleteGroupWhenEmpty true;
};
//////Vehicles/////////////////////////////////////////////////////////////////////////////////////////


if (count [(getpos thisPOWTrigger) nearRoads 70] > 0) then {
	
_nearRoad = selectRandom ( (getpos thisPOWTrigger) nearRoads 70 ) ; 
_V = createVehicle [ selectRandom East_Ground_Vehicles_Ambient, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"]; 
_nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
_dir = _nearRoad getDir _nextRoad;
_V setDir _dir;
	};

if ((_AGGRSCORE > 5) && (count [(getpos thisPOWTrigger) nearRoads 70] > 0)) then {
	
_nearRoad = selectRandom ((getpos thisPOWTrigger) nearRoads 70 ) ; 
_V = createVehicle [ selectRandom East_Ground_Vehicles_Ambient, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"]; 
_nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
_dir = _nearRoad getDir _nextRoad;
_V setDir _dir;
	};

[thisPOWTrigger, 200] execVM "Scripts\INTLitems.sqf";