/////////////////////Rescue POW////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_thisPatrolTrigger = _this select 0; 

_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

_Chance = selectRandom [1, 2, 3]; 
 
//////OBJECTIVE/////////////////////////////////////////////////////////////////////////////////////////


_Buildings = nearestObjects [(getpos _thisPatrolTrigger), ["House"], 200];  
_allPositionBuildings = _Buildings select {count (_x buildingPos -1) > 2}; 
_Position = _allPositionBuildings select 0;
_Pos = selectRandom (_Position buildingPos -1);

_V = createVehicle ["Box_FIA_Ammo_F", _Pos, [], 500, "NONE"]; 
_V allowDammage false;
_V setPos _Pos;
sleep 3;
_V allowDammage true;
_V addEventHandler ["Killed", { 
_MMarks = allMapMarkers select { markerText _x == "Mission : Counter Insurgency"};
_M = [_MMarks, (_this select 0)] call BIS_fnc_nearestPosition;

deleteMarker _M ; 
  
["ScoreAdded", ["Insurgent Stash Destroyed", 30]] call BIS_fnc_showNotification; 

[30] call FLO_fnc_addReward;
[] execVM "Scripts\DangerMinus.sqf";

execVM "Scripts\Civ_Relations.sqf";

 playMusic "EventTrack01_F_Curator"; 
}];



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
 
execVM "Scripts\INTL.sqf"; 
 
 },    
 {},              
 [],             
 3,            
 0,             
 true,             
 false             
] remoteExec ["BIS_fnc_holdActionAdd", 0, _OFC]; 
 
 _Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup;   
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;  
 ((units G) select 0) disableAI "PATH";
 
_Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup;    
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;   

 
 _Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup;    
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;   



if (_AGGRSCORE > 5) then {
_allPositionBuildings = _Buildings select {count (_x buildingPos -1) > 2}; 
_Position = selectRandom _allPositionBuildings ;
_Pos = selectRandom (_Position buildingPos -1);
G = [_Pos, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup;   
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;  
 ((units G) select 0) disableAI "PATH";
 
  _Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup; 
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;   

 
_Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup; 
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;   

};

if (_AGGRSCORE > 10) then {
_allPositionBuildings = _Buildings select {count (_x buildingPos -1) > 2}; 
_Position = selectRandom _allPositionBuildings ;
_Pos = selectRandom (_Position buildingPos -1);
G = [_Pos, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup; 
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;      
((units G) select 0) disableAI "PATH";

 _Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;   

 
_Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup; 
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;   

};

//////Gaurds/////////////////////////////////////////////////////////////////////////////////////////
 

_poss = [getpos _Position, 10, 30, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup;  
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;  
((units G) select 0) disableAI "PATH"; 

if (_AGGRSCORE > 5) then {
_poss = [getpos _Position, 10, 30, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup;  
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;  
((units G) select 0) disableAI "PATH"; 
}; 
if (_AGGRSCORE > 10) then {
_poss = [getpos _Position, 10, 30, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom CivMenArray]] call BIS_fnc_spawnGroup;  
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units G;  
((units G) select 0) disableAI "PATH"; 
}; 
 
//////GROUPS/////////////////////////////////////////////////////////////////////////////////////////


PRL = [(getPos _Position) getPos [30, 50], East, [selectRandom CivMenArray, selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units PRL;  
[PRL, getpos _Position, 20] call BIS_fnc_taskPatrol;

if (_AGGRSCORE > 5) then {
PRL = [(getPos _Position) getPos [30, 180], East, [selectRandom CivMenArray, selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
{_uniform = uniform _x;
_x setUnitLoadout (selectRandom GuerMenArray);
removeHeadgear _x; 
_x forceAddUniform _uniform;
} foreach Units PRL;  
[PRL, getpos _Position, 200] call BIS_fnc_taskPatrol;
};

//////Vehicles/////////////////////////////////////////////////////////////////////////////////////////


if ((_AGGRSCORE > 5) && (count [(getpos _Position) nearRoads 70] > 0))then {
	
_nearRoad = selectRandom ( (getpos _Position) nearRoads 70 ) ; 
_V = createVehicle [ selectRandom CivVehArray, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"]; 
_nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
_dir = _nearRoad getDir _nextRoad;
_V setDir _dir;
	};

if ((_AGGRSCORE > 10) && (count [(getpos _Position) nearRoads 70] > 0)) then {
	
_nearRoad = selectRandom ((getpos _Position) nearRoads 70 ) ; 
_V = createVehicle [ selectRandom CivVehArray, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"]; 
_nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
_dir = _nearRoad getDir _nextRoad;
_V setDir _dir;
	};


{ if !((side _x) == west) then {
            ZEUS removeCuratorEditableObjects [[_x],true];
}; } foreach allUnits;

