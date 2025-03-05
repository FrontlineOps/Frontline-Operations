
MType = _this select 0 ;


openMap [true, false]; 
hint "Select Objective Location"; 
onMapSingleClick {
onMapSingleClick {}; 

_markerName = "NewCustom" + (str (_pos));   
mrkr = createMarker [_markerName, _pos];   
mrkr setMarkerType MType;  
mrkr setMarkerColor "colorOPFOR";  

	
    if (MType == "o_unknown") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [0.9, 0.9];

if (count (nearestObjects [_pos, ["House"], 200]) == 0) then {
			   P1 = selectRandom [ 
                      "Compound_01",  
                      "Compound_02", 
                      "Compound_03",  
                      "Compound_04", 
                      "Compound_05",  
                      "Compound_06"   
                       ]; 	

_COM = [ P1, _pos, [0,0,0], (0 + (random 350)), true ] call LARs_fnc_spawnComp;
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1];} forEach _ARRAY;
};

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [1500, 1500, 0, false, 60];
_trgA setTriggerTimeout [2, 2, 2, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Objectives\Town_CSAT.sqf'; ", ""];

	}; 

	if (MType == "o_installation") then {
			hint "You Placed a Custom Mission Marker";

mrkr setMarkerSize [1.2, 1.2]; 

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [1500, 1500, 0, false, 60];
_trgA setTriggerTimeout [13, 13, 13, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this","[thisTrigger] execVM 'Scripts\City_CSAT.sqf'; ", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this"," [thisTrigger] execVM 'Scripts\Objectives\Recon_CSAT.sqf'; ", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [ "this"," [thisTrigger] execVM 'Scripts\HeliInsert_CSAT.sqf'; ", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [ "this"," [thisTrigger] execVM 'Scripts\VehiInsert_CSAT.sqf'; ", ""];

				 };		
				 
	if (MType == "n_installation") then {
			hint "You Placed a Custom Mission Marker";
_mrkr setMarkerSize [1.4, 1.4];   

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [1500, 1500, 0, false, 60];
_trgA setTriggerTimeout [17, 17, 17, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Objectives\Capital_CSAT.sqf';", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Objectives\Recon_CSAT.sqf';", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\HeliInsert_CSAT.sqf';", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\VehiInsert_CSAT.sqf';", ""];	 
				 
				 };		
				 
	if (MType == "o_support") then {
			hint "You Placed a Custom Mission Marker";
_mrkr setMarkerSize [1.2, 1.2]; 


if ( count (nearestObjects [_pos, ["Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V2_F", "Land_Cargo_Tower_V1_F", "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V1_F"], 100] ) == 0) then {
		
_P1 = [ 
 "Outpost_01",  
 "Outpost_02",  
 "Outpost_03",  
 "Outpost_04",  
 "Outpost_05",  
 "Outpost_06",  
 "Outpost_07",  
 "Outpost_08",  
 "Outpost_09",  
 "Outpost_10",  
 "Outpost_11",  
 "Outpost_12"    
]; 	

_dir = 0 + (random 360);
if (count (nearestObjects [_pos, ["House"], 200]) != 0) then {
_dir = getDirVisual ((nearestObjects [_pos, ["House"], 200]) select 0);
};
_COM = [ selectRandom _P1, _pos, [0,0,0], _dir, true ] call LARs_fnc_spawnComp;
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1];} forEach _ARRAY;
};


    _trgA = createTrigger ["EmptyDetector", _pos];
    _trgA setTriggerArea [2000, 2000, 0, false, 200];
    _trgA setTriggerInterval 20;
    _trgA setTriggerActivation ["WEST", "PRESENT", false];
    _trgA setTriggerStatements [
        "this","[thisTrigger] execVM 'Scripts\Objectives\Outpost_CSAT.sqf';", ""];
				 
_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [1000, 1000, 0, false, 200];
_trgA setTriggerInterval 20;
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this","[thisTrigger] execVM 'Scripts\Objectives\Recon_CSAT.sqf';", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [1000, 1000, 0, false, 200];
_trgA setTriggerInterval 20;
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this","[thisTrigger] execVM 'Scripts\HeliInsert_CSAT.sqf';", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [1000, 1000, 0, false, 200];
_trgA setTriggerInterval 20;
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this","[thisTrigger] execVM 'Scripts\VehiInsert_CSAT.sqf';", ""];				 
				 
				 };		
				 
	if (MType == "n_support") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1.4, 1.4];   

if ( count (nearestObjects [_pos, ["Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V2_F", "Land_Cargo_Tower_V1_F", "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V1_F"], 30] ) == 0) then {
		
_P1 = [ 
 "FOB_01",  
 "FOB_02",  
 "FOB_03"
]; 	
_dir = 0 + (random 360);
if (count (nearestObjects [_pos, ["House"], 300]) != 0) then {
_dir = getDirVisual ((nearestObjects [_pos, ["House"], 300]) select 0);
};
_COM = [ selectRandom _P1, _pos, [0,0,0], _dir, true ] call LARs_fnc_spawnComp;
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1];} forEach _ARRAY;
};

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [2000, 2000, 0, false, 60];
_trgA setTriggerTimeout [15, 15, 15, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Objectives\BOutpost_CSAT.sqf';", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Objectives\Recon_CSAT.sqf';", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\HeliInsert_CSAT.sqf';", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\VehiInsert_CSAT.sqf';", ""];
				 
				 };	
				 
	if (MType == "o_service") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1, 1]; 

P1 = selectRandom [ 
 "Road_Post_CSAT_01",  
 "Road_Post_CSAT_02",  
 "Road_Post_CSAT_03"   
 ]; 

       _nearRoad = ( _pos nearRoads 100 ) select 0;
		_nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
		_dir = _nearRoad getDir _nextRoad;
_COM = [ P1, getPosATL _nearRoad, [0,0,0], _dir, true ] call LARs_fnc_spawnComp;	
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1]} forEach _ARRAY;


_trgA = createTrigger ["EmptyDetector", getPos _nearRoad];
_trgA setTriggerArea [1000, 1000, 0, false, 30];
_trgA setTriggerTimeout [3, 3, 3, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this","[thisTrigger] execVM 'Scripts\Objectives\RoadBlock_CSAT.sqf';", ""];
				 
				 };		
	
	if (MType == "o_maint") then {  
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1.2, 1.2]; 

_P1 =  [ 
 "Factory",  
 "Factory",  
 "Factory",  
 "Factory",  
 "Factory_1",  
 "Factory_1",  
 "Factory_1",  
 "Factory_2"    
]; 	
_dir = 0 + (random 360);
if (count (nearestObjects [_pos, ["House"], 200]) != 0) then {
_dir = getDirVisual ((nearestObjects [_pos, ["House"], 200]) select 0);
};
_COM = [ selectRandom _P1, _pos, [0,0,0], _dir, true ] call LARs_fnc_spawnComp;
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1];} forEach _ARRAY;

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [2000, 2000, 0, false, 60];
_trgA setTriggerTimeout [9, 9, 9, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this","[thisTrigger] execVM 'Scripts\Objectives\Factory_CSAT.sqf';", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Objectives\Recon_CSAT.sqf';", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\HeliInsert_CSAT.sqf';", ""];

_trgA = createTrigger ["EmptyDetector", _pos getPos [(1000 + (random 3500)),(0 + (random 350))]];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\VehiInsert_CSAT.sqf';", ""];
	
	};	

	if (MType == "o_antiair") then {  
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1.2, 1.2]; 

_P1 =  [ 
 "AAA_01",  
 "AAA_02",  
 "AAA_03"    
]; 	

_COM = [ selectRandom _P1, _pos, [0,0,0], (0 + (random 360)), true ] call LARs_fnc_spawnComp;
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [2000, 2000, 0, false, 60];
_trgA setTriggerTimeout [7, 7, 7, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this","[thisTrigger] execVM 'Scripts\Objectives\AAA_CSAT.sqf';", ""];

	};	
	
	if (MType == "loc_Power") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1, 1]; 

if (count (nearestObjects [_pos, ["Land_Radar_F"], 100]) == 0) then {
			   P1 = selectRandom [ 
                      "Radar_1",  
                      "Radar_2",  
                      "Radar_3"   
                       ]; 	

              _COM = [ P1, _pos, [0,0,0], (0 + (random 350)), true ] call LARs_fnc_spawnComp;
			  _ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
             {_x setVectorUp [0,0,1];} forEach _ARRAY;
};

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [1500, 1500, 0, false, 60];
_trgA setTriggerTimeout [7, 7, 7, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Objectives\Mission_Radar.sqf';", ""];
				 		
	};

	if (MType == "o_armor") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1,2, 1,2];   

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [2500, 2500, 0, false, 200];
_trgA setTriggerTimeout [2, 2, 2, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Objectives\Mission_Armor.sqf';", ""];

				 		
	};	
	
	if (MType == "o_recon") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1, 1]; 

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [1000, 1000, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Mission_Intel.sqf';", ""];
				 		
	};		
	
	if (MType == "o_plane") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1, 1]; 

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [2000, 2000, 0, false, 2000];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Objectives\Mission_Air.sqf';", ""];
				 		
	};	

	if (MType == "loc_Ruin") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1.2, 1.2]; 

 if (count (nearestObjects [_pos, ["Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F", "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F"], 100]) == 0) then {
			   P1 = selectRandom [ 
                      "B_1_CSAT",  
                      "B_2_CSAT",  
                      "B_3_CSAT"   
                       ]; 	

_COM = [ P1, _pos, [0,0,0], (0 + (random 350)), true ] call LARs_fnc_spawnComp;
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1];} forEach _ARRAY;
 };

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [1500, 1500, 0, false, 60];
_trgA setTriggerTimeout [5, 5, 5, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Mission_POW.sqf';", ""];
				 		
	};	

	if (MType == "loc_Transmitter") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1, 1]; 

if ( count (nearestObjects [_pos, ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"], 100] ) == 0) then {
_P1 =  ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"]; 	
_TWR = createVehicle [ selectRandom _P1,_pos, [], 5, "NONE"];
_TWR setVectorUp [0,0,1];
[
	_TWR,											
	"Intercept Comms",										
	"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",	
	"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",	
	"_this distance _target < 10 && count (allMapMarkers select { markerText _x == ""Radio""}) == 0 ",						
	"_caller distance _target < 10",						
	{
	playSound3D ["a3\missions_f_oldman\data\sound\intel_laptop\2sec\intel_laptop_2sec_03.wss", (_this select 0)]; 
	},												
	{},													
	{ 

[(_this select 0)] execVM "Scripts\Reveal.sqf";

	},				
	{},													
	[],												
	3,													
	0,												
	true,												
	false												
] remoteExec ["BIS_fnc_holdActionAdd", 0, _TWR];	

}else{

_TWR = nearestObjects [_pos, ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"], 100] select 0;
[
	_TWR,											
	"Intercept Comms",										
	"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",	
	"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",	
	"_this distance _target < 10 && count (allMapMarkers select { markerText _x == ""Radio""}) == 0 ",						
	"_caller distance _target < 10",						
	{
	playSound3D ["a3\missions_f_oldman\data\sound\intel_laptop\2sec\intel_laptop_2sec_03.wss", (_this select 0)]; 
	},												
	{},													
	{ 

[(_this select 0)] execVM "Scripts\Reveal.sqf";

	},				
	{},													
	[],												
	3,													
	0,												
	true,												
	false												
] remoteExec ["BIS_fnc_holdActionAdd", 0, _TWR];	

}; 

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [2000, 2000, 0, false, 60];
_trgA setTriggerTimeout [5, 5, 5, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Objectives\RadioTower_CSAT.sqf';", ""];
 		
	};	

	if (MType == "o_naval") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1.2, 1.2]; 

_trgA = createTrigger ["EmptyDetector",_pos];
_trgA setTriggerArea [3000, 3000, 0, false, 60];
_trgA setTriggerTimeout [7, 7, 7, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Mission_Ship.sqf';", ""];
				 		
	};	

	if (MType == "loc_mine") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1, 1];  

_trgMine = createTrigger ["EmptyDetector", _pos];
_trgMine setTriggerArea [1000, 1000, 0, false, 60];
_trgMine setTriggerTimeout [2, 2, 2, true];
_trgMine setTriggerActivation ["WEST", "PRESENT", false];
_trgMine setTriggerStatements [
"this","[thisTrigger] execVM 'Scripts\Objectives\Minefield.sqf';", ""];
				 		
	};	

	if (MType == "mil_unknown") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1, 1]; 

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [2000, 2000, 0, false, 60];
_trgA setTriggerTimeout [7, 7, 7, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Mission_Pilot.sqf';", ""];

	};
				 		
	if (MType == "mil_warning") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [1, 1]; 

    _trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [2000, 2000, 0, false, 60];
_trgA setTriggerTimeout [2, 2, 2, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\Mission_Squad.sqf';", ""];
				 		
	}; 

    if (MType == "u_installation") then {
			hint "You Placed a Custom Mission Marker";
mrkr setMarkerSize [0.9, 0.9];

if (count (nearestObjects [_pos, ["House"], 200]) == 0) then {
			   P1 = selectRandom [ 
                      "Compound_01",  
                      "Compound_02", 
                      "Compound_03",  
                      "Compound_04", 
                      "Compound_05",  
                      "Compound_06"   
                       ]; 	

_COM = [ P1, _pos, [0,0,0], (0 + (random 350)), true ] call LARs_fnc_spawnComp;
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1];} forEach _ARRAY;
};

_trgA = createTrigger ["EmptyDetector", _pos];
_trgA setTriggerArea [1500, 1500, 0, false, 60];
_trgA setTriggerTimeout [2, 2, 2, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this","[thisTrigger] execVM 'Scripts\G_CSAT.sqf';", ""];

mrkr setMarkerAlpha 0;  

	}; 


hint ""; 
};
