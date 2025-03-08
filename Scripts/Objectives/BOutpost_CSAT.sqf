
thisBaseTrigger = _this select 0;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
sleep 15; 

[thisBaseTrigger] execVM "Scripts\HMGspawn.sqf" ; 

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

if (count ( nearestobjects [getPos thisBaseTrigger, ["Land_HelipadCircle_F","Land_HelipadCivil_F","Heli_H_rescue","Land_HelipadRescue_F","Land_HelipadSquare_F","HeliHRescue","Heli_H_civil","HeliHCivil","HeliH"], 500]) > 0) then { 
_HPAD = nearestobjects [getPos thisBaseTrigger, ["Land_HelipadCircle_F","Land_HelipadCivil_F","Heli_H_rescue","Land_HelipadRescue_F","Land_HelipadSquare_F","HeliHRescue","Heli_H_civil","HeliHCivil","HeliH"], 500] select 0;
_V = createVehicle [ selectRandom East_Air_Heli, getpos _HPAD, [], 0, "NONE"]; 
_V setVehicleLock "LOCKED";
_dir =  getDir _HPAD;
_V setDir _dir; 

sleep 3;

_V addEventHandler ["Killed", {  
["ScoreAdded", ["Enemy Aircraft Sabotaged", 20]] remoteExec ["BIS_fnc_showNotification", 0];
[20] call FLO_fnc_addReward;
 playMusic "EventTrack01_F_Curator"; 
 execVM 'Scripts\HeliDis.sqf';
}];
} ;

if (count ( nearestobjects [getPos thisBaseTrigger, ["Land_Ss_hangar", "Land_Ss_hangard", "Land_Mil_hangar_EP1", "Land_Airport_01_hangar_F", "Land_TentHangar_V1_F", "Land_Hangar_F"], 500]) > 0) then { 
_HPAD = nearestobjects [getPos thisBaseTrigger, ["Land_Ss_hangar", "Land_Ss_hangard", "Land_Mil_hangar_EP1", "Land_Airport_01_hangar_F", "Land_TentHangar_V1_F", "Land_Hangar_F"], 500] select 0;

_V = createVehicle [ selectRandom East_Air_Jet, [(0 + (random 50)), (0 + (random 50)), 100], [], 0, "NONE"]; 
_V setVehicleLock "LOCKED";
_dir =  getDir _HPAD;
_V setDir _dir; 
_V setPos (getpos _HPAD) ;
sleep 3;

_PRL = [_HPAD getPos [(10 +(random 20)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[_PRL, _HPAD getPos [(10 +(random 20)), (0 + (random 360))], 50] call BIS_fnc_taskPatrol;

_V addEventHandler ["Killed", {  
["ScoreAdded", ["Enemy Aircraft Sabotaged", 20]] remoteExec ["BIS_fnc_showNotification", 0];
[20] call FLO_fnc_addReward;
 playMusic "EventTrack01_F_Curator"; 

}];
} ;

if (_AGGRSCORE > 5) then {
			_AssltDestMrks = allMapMarkers select {markerType _x == "b_installation"  && (markerColor _x == "ColorYellow" or  markerColor _x == "colorBLUFOR" or markerColor _x == "colorWEST")};  
			_StrtM = [_AssltDestMrks,  thisBaseTrigger] call BIS_fnc_nearestPosition;
[thisBaseTrigger, _StrtM] execVM "Scripts\VehiInsert_CSAT_2.sqf";			

};

if (_AGGRSCORE > 10) then {
			_AssltDestMrks = allMapMarkers select {markerType _x == "b_installation"  && (markerColor _x == "ColorYellow" or  markerColor _x == "colorBLUFOR" or markerColor _x == "colorWEST")};  
			_StrtM = [_AssltDestMrks,  thisBaseTrigger] call BIS_fnc_nearestPosition;
[thisBaseTrigger, _StrtM] execVM "Scripts\VehiInsert_CSAT_2.sqf";	
};


_nearRoad = selectRandom ( (getpos thisBaseTrigger) nearRoads 300 ) ; 
_V = createVehicle [ selectRandom East_Ground_Vehicles_Ambient, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"]; 
_nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
_dir = _nearRoad getDir _nextRoad;
_V setDir _dir;

_nearRoad = selectRandom ( (getpos thisBaseTrigger) nearRoads 300 ) ; 
_V = createVehicle [ selectRandom East_Ground_Vehicles_Ambient, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"]; 
_nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
_dir = _nearRoad getDir _nextRoad;
_V setDir _dir;

_nearRoad = selectRandom ( (getpos thisBaseTrigger) nearRoads 300 ) ; 
_V = createVehicle [ selectRandom East_Ground_Vehicles_Ambient, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"]; 
_nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
_dir = _nearRoad getDir _nextRoad;
_V setDir _dir;

_nearRoad = selectRandom ( (getpos thisBaseTrigger) nearRoads 300 ) ; 
_V = createVehicle [ selectRandom East_Ground_Vehicles_Ambient, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"]; 
_nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
_dir = _nearRoad getDir _nextRoad;
_V setDir _dir;

_poss = [(getpos thisBaseTrigger), 10, 20, 4, 0.1 , 0] call BIS_fnc_findSafePos;
_VLAMP = createVehicle [ "Land_LampAirport_F", _poss, [], 5, "NONE"];

_allBuildings = nearestObjects [(getpos thisBaseTrigger), (FLO_configCache get "buildings"), 300];  

_HQ = selectRandom _allBuildings;
_dir = getDirVisual _HQ;
[ "Intel_01", (selectRandom (_HQ buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 

_HQ = selectRandom _allBuildings;
_dir = getDirVisual _HQ;
[ "Intel_01", (selectRandom (_HQ buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 

_HQ = selectRandom _allBuildings;
_dir = getDirVisual _HQ;
[ "Intel_01", (selectRandom (_HQ buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 

_HQ = selectRandom _allBuildings;
_dir = getDirVisual _HQ;
[ "Intel_01", (selectRandom (_HQ buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 

_HQ = selectRandom _allBuildings;
_dir = getDirVisual _HQ;
[ "Intel_01", (selectRandom (_HQ buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 

_HQ = selectRandom _allBuildings;
_dir = getDirVisual _HQ;
[ "Intel_01", (selectRandom (_HQ buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 

if (_AGGRSCORE > 5) then {
	_HQ = selectRandom _allBuildings;
_dir = getDirVisual _HQ;
[ "Intel_01", (selectRandom (_HQ buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 

	_HQ = selectRandom _allBuildings;
_dir = getDirVisual _HQ;
[ "Intel_01", (selectRandom (_HQ buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 
};

if (_AGGRSCORE > 10) then {
_HQ = selectRandom _allBuildings;
_dir = getDirVisual _HQ;
[ "Intel_01", (selectRandom (_HQ buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 
	
_HQ = selectRandom _allBuildings;
_dir = getDirVisual _HQ;
[ "Intel_01", (selectRandom (_HQ buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 
};

_HeavGuns =  nearestObjects [(getpos thisBaseTrigger), ["O_G_HMG_02_high_F", "O_G_Mortar_01_F"], 300];

{
CrewGroup = createVehicleCrew _x; 
_VC = createGroup East;
{[_x] join _VC} forEach units CrewGroup;
{_x setUnitLoadout selectRandom East_Units;} forEach units _VC;
} forEach _HeavGuns;

  
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 sleep 10;
 
_trg = createTrigger ["EmptyDetector", getPos thisBaseTrigger, false];  
_trg setTriggerArea [1000, 1000, 0, false, 200];  
_trgA setTriggerTimeout [2, 2, 2, true];
_trg setTriggerActivation ["WEST", "PRESENT", false];  
_trg setTriggerStatements [  
"this",  "[thisTrigger, 1500] execVM 'Scripts\Objectives\ZONEs.sqf';", ""]; 
 
 
   
_trg = createTrigger ["EmptyDetector", getPos thisBaseTrigger, false];  
_trg setTriggerArea [220, 220, 0, false, 200];  
_trg setTriggerTimeout [10, 10, 10, true];
_trg setTriggerActivation ["WEST SEIZED", "PRESENT", true];  
_trg setTriggerStatements [  
"this",  "  

[parseText '<t color=""#1AA3FF"" font=""PuristaBold"" align = ""right"" shadow = ""1"" size=""2"">SITREP</t><br /><t color=""#959393"" align = ""right"" shadow = ""1"" size=""0.8"">Friendly Forces Dominating the Battle,</t><br /><t color=""#959393"" align = ""right"" shadow = ""1"" size=""0.8"">Keep Up the Fight, We will Capture and Secure the Outpost,</t>', [0, 0.5, 1, 1], nil, 5, 1.7, 0] remoteExec ['BIS_fnc_textTiles', 0];
_allMarks = allMapMarkers select {markerType _x == 'n_support'};  
_FOBMrk = [_allMarks,  thisTrigger] call BIS_fnc_nearestPosition;
						_FOBMrk setMarkerColor 'ColorGrey' ;	
									_attackingAtGrid = mapGridPosition getMarkerPos _FOBMrk;
								[[west,'HQ'], 'Friendly Forces Dominating the Battle at grid ' + _attackingAtGrid] remoteExec ['sideChat', 0];

[thisTrigger] execVM 'Scripts\Objectives\Outpost_CSAT_CAPTURE_West.sqf';

", "

_allMarks = allMapMarkers select {markerType _x == 'n_support'};  
_FOBMrk = [_allMarks,  thisTrigger] call BIS_fnc_nearestPosition;
						_FOBMrk setMarkerColor 'colorOPFOR' ;	

"]; 

 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
{ if !((side _x) == west) then {
            ZEUS removeCuratorEditableObjects [[_x],true];
}; } foreach allUnits;
 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

[thisBaseTrigger, 300] execVM "Scripts\INTLitems.sqf";


sleep 2;
