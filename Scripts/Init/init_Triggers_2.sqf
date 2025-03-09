////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

//////Resources/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_objectLocT = allMapMarkers select { markerType _x == "n_support"};

{
	
_trg = createTrigger ["EmptyDetector", getMarkerpos _x, false];
_trg setTriggerArea [2000, 2000, 0, false, 300];
_trg setTriggerTimeout [1, 1, 1, true];
_trg setTriggerActivation ["WEST", "PRESENT", false];
_trg setTriggerStatements [
"this","

[thisTrigger] execVM 'Scripts\Insurgents_Init.sqf';

if ( count (nearestObjects [(getPos thisTrigger), ['Land_Cargo_Tower_V3_F', 'Land_Cargo_Tower_V2_F', 'Land_Cargo_Tower_V1_F', 'Land_Cargo_HQ_V3_F', 'Land_Cargo_HQ_V2_F', 'Land_Cargo_HQ_V1_F'], 100] ) == 0) then {

_TERR = nearestTerrainObjects [(getPos thisTrigger), ['FOREST', 'House', 'TREE', 'SMALL TREE', 'BUSH', 'ROCK', 'ROCKS'], 40]; 
{_x hideObjectGlobal true;} forEach _TERR ;

_P1 = [ 
'FOB_01',  
'FOB_02',  
'FOB_03'
]; 	
_dir = 0 + (random 360);
if (count (nearestObjects [(getPos thisTrigger), ['House'], 300]) != 0) then {
_dir = getDirVisual ((nearestObjects [(getPos thisTrigger), ['House'], 300]) select 0);
};


_COM = [ selectRandom _P1, (getPos thisTrigger), [0,0,0], _dir, true ] call LARs_fnc_spawnComp;
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1];} forEach _ARRAY;
};



_trgA = createTrigger ['EmptyDetector', (getPos thisTrigger), false];
_trgA setTriggerArea [1000, 1000, 0, false, 300];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\Objectives\BOutpost_CSAT.sqf';

"",""""];

_trgA = createTrigger ['EmptyDetector', (getPos thisTrigger) getPos [(300 + (random 300)),(0 + (random 350))], false];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\Objectives\Recon_CSAT.sqf';

"",""""];

_trgA = createTrigger ['EmptyDetector', (getPos thisTrigger) getPos [(500 + (random 2000)),(0 + (random 350))], false];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\HeliInsert_CSAT.sqf';

"",""""];

_trgA = createTrigger ['EmptyDetector', (getPos thisTrigger) getPos [(500 + (random 2000)),(0 + (random 350))], false];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\VehiInsert_CSAT.sqf';

"",""""];

", ""];


} forEach _objectLocT;

["LOADING . . . "] remoteExec ["hint", 0];
sleep 1;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


_objectLocT = allMapMarkers select { markerType _x == "loc_Ruin" };

{

_trg = createTrigger ["EmptyDetector", getMarkerpos _x, false];
_trg setTriggerArea [2000, 2000, 0, false, 300];
_trg setTriggerTimeout [1, 1, 1, true];
_trg setTriggerActivation ["WEST", "PRESENT", false];
_trg setTriggerStatements [
"this","

[thisTrigger] execVM 'Scripts\Insurgents_Init.sqf';

_TERR = nearestTerrainObjects [(getPos thisTrigger), ['FOREST', 'House', 'TREE', 'SMALL TREE', 'BUSH', 'ROCK', 'ROCKS'], 40]; 
{_x hideObjectGlobal true;} forEach _TERR ;

_mrkrs = allMapMarkers select {markerColor _x == 'Color6_FD_F'};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

if (_AGGRSCORE < 6) then {
BRKC = [ 
'B_1_CSAT',  
'B_2_CSAT',  
'B_3_CSAT'   
]; };

if (_AGGRSCORE > 5) then {
BRKC =  [ 
'B_4_CSAT',  
'B_5_CSAT',  
'B_6_CSAT'   
]; };

if (_AGGRSCORE > 10) then {
BRKC =  [ 
'B_7_CSAT',  
'B_8_CSAT',  
'B_9_CSAT'   
]; };

_dir = 0 + (random 360);
if (count (nearestObjects [(getPos thisTrigger), ['House'], 300]) != 0) then {
_dir = getDirVisual ((nearestObjects [(getPos thisTrigger), ['House'], 300]) select 0);
};

_COM = [ selectRandom BRKC, (getPos thisTrigger), [0,0,0], _dir, true ] call LARs_fnc_spawnComp;
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1];} forEach _ARRAY;

_Position = nearestObjects [(getPos thisTrigger), ['Land_i_Barracks_V1_F', 'Land_u_Barracks_V2_F', 'Land_i_Barracks_V2_F', 'Land_Barracks_01_grey_F', 'Land_Barracks_01_dilapidated_F' , 'Land_vn_barracks_01_camo_f', 'Land_Barracks_01_camo_F'], 100] select 0;  
_Position addEventHandler ['Killed', { 
_MMarks = allMapMarkers select { markerType _x == 'loc_Ruin'};
_M = [_MMarks, (_this select 0)] call BIS_fnc_nearestPosition;
deleteMarker _M ; 

				[40, 'BARRACKS'] call FLO_fnc_notification ;

[40] call FLO_fnc_addReward;

				_markerName = 'AssaultMark' + (str [(0 + (random 1000)), (0 + (random 1000)), 0]);  
				_mrkr = createMarker [_markerName, [(0 + (random 1000)), (0 + (random 1000)), 0]]; 
_mrkr setMarkerType 'loc_Bunker';
_mrkr setMarkerAlpha 0.003;

[] execVM 'Scripts\DangerPlus.sqf';
[(_this select 0), 1000] call FLO_fnc_requestQRF;
  
 execVM 'Scripts\InfDis.sqf';

}];



_trgA = createTrigger ['EmptyDetector', (getPos thisTrigger), false];
_trgA setTriggerArea [1000, 1000, 0, false, 300];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\Mission_POW.sqf';

"",""""];

_trgA = createTrigger ['EmptyDetector', (getPos thisTrigger) getPos [(300 + (random 300)),(0 + (random 350))], false];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\Objectives\Recon_CSAT.sqf';

"",""""];

", ""];

} forEach _objectLocT;


sleep 1;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_objectLocT = allMapMarkers select { markerType _x == "loc_Power" };

{
	
_trg = createTrigger ["EmptyDetector", getMarkerpos _x, false];
_trg setTriggerArea [2000, 2000, 0, false, 300];
_trg setTriggerTimeout [1, 1, 1, true];
_trg setTriggerActivation ["WEST", "PRESENT", false];
_trg setTriggerStatements [
"this","	

[thisTrigger] execVM 'Scripts\Insurgents_Init.sqf';

_TERR = nearestTerrainObjects [(getPos thisTrigger), [], 40]; 
{_x hideObjectGlobal true;} forEach _TERR ;
	
_mrkrs = allMapMarkers select {markerColor _x == 'Color6_FD_F'};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

if (_AGGRSCORE < 6) then {			 
RDRC = [ 
'Radar_1',  
'Radar_2',  
'Radar_3'   
]; };	

if (_AGGRSCORE > 5) then {
RDRC =  [ 
'Radar_4',  
'Radar_5',  
'Radar_6'   
]; };					   					   
					   
if (_AGGRSCORE > 10) then {
RDRC =  [ 
'Radar_7',  
'Radar_8',  
'Radar_9'   
]; };				
					   
_dir = 0 + (random 360);
if (count (nearestObjects [(getPos thisTrigger), ['House'], 300]) != 0) then {
_dir = getDirVisual ((nearestObjects [(getPos thisTrigger), ['House'], 300]) select 0);
};

_TERR = nearestTerrainObjects [(getPos thisTrigger), [], 40]; 
{_x hideObjectGlobal true;} forEach _TERR ;

_COM = [ selectRandom RDRC, (getPos thisTrigger), [0,0,0], _dir, true ] call LARs_fnc_spawnComp;
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1];} forEach _ARRAY;

_RDR = nearestobjects [(getPos thisTrigger), ['Land_Radar_F'], 100] select 0;
_RDR addEventHandler ['Killed', { 
_MMarks = allMapMarkers select { markerType _x == 'loc_Power'};
_M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;

deleteMarker _M ; 
    				[40, 'RADAR SITE'] call FLO_fnc_notification ;


[40] call FLO_fnc_addReward;
[] execVM 'Scripts\DangerMinus.sqf';
[] execVM 'Scripts\DangerMinus.sqf';
[] execVM 'Scripts\DangerMinus.sqf';
[(_this select 0), 1000] call FLO_fnc_requestQRF;

 execVM 'Scripts\AADis.sqf';


 
}];


_trgA = createTrigger ['EmptyDetector', (getPos thisTrigger), false];
_trgA setTriggerArea [1000, 1000, 0, false, 100];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\Objectives\Mission_Radar.sqf';

"",""""];

_trgA = createTrigger ['EmptyDetector', (getPos thisTrigger) getPos [(300 + (random 300)),(0 + (random 350))], false];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerInterval 3;
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\Objectives\Recon_CSAT.sqf';

"",""""];

", ""];

} forEach _objectLocT;


["LOADING . . . "] remoteExec ["hint", 0];
sleep 1;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
sleep 1;

_objectLocT = allMapMarkers select { markerType _x == "o_naval" };

{

_trgA = createTrigger ["EmptyDetector", getMarkerpos _x];
_trgA setTriggerArea [3000, 3000, 0, false, 1000];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this","

[thisTrigger] execVM 'Scripts\Objectives\Mission_Ship.sqf';

", ""];

sleep 0.2 ;

} forEach _objectLocT;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

sleep 4;

TRG2LOCC = 1;
publicVariable "TRG2LOCC";

