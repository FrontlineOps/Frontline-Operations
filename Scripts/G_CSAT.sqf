

_thisTownTrigger = _this select 0;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ; 


_Chance = selectRandom [0,1,2,3,4]; 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////Veicle////////////////////////////////////////////////////////////////////////

if (_Chance > 1) then {
_nearRoad = selectRandom ( (getPos _thisTownTrigger) nearRoads 200 ) ; 
_V = createVehicle [ selectRandom GuerVehArray, (_nearRoad getRelPos [0, 0]), [], 2, "NONE"]; 

_Group = createVehicleCrew _V; 
_VC = createGroup East;
{[_x] join _VC} forEach units _Group;

sleep 3;
_nearRoad2 =_thisTownTrigger nearRoads 500 ; 
_nearRoad1 = _thisTownTrigger nearRoads 200 ; 

_nearRoadleft = _nearRoad2 - _nearRoad1;
_nearRoad0 = selectRandom _nearRoadleft; 
I1_WP_0 = _VC addWaypoint [getPos _nearRoad0, 0];
I1_WP_0 SetWaypointType "MOVE";
I1_WP_0 setWaypointBehaviour "SAFE";
I1_WP_0 setWaypointSpeed "LIMITED";

I1_WP_00 = _VC addWaypoint [getPos _nearRoad, 0];
I1_WP_00 SetWaypointType "MOVE";
I1_WP_00 setWaypointBehaviour "SAFE";
I1_WP_00 setWaypointSpeed "LIMITED";

I1_WP_1 = _VC addWaypoint [getPos _nearRoad, 3];
I1_WP_1 SetWaypointType "CYCLE";
I1_WP_1 setWaypointBehaviour "SAFE";
I1_WP_1 setWaypointSpeed "LIMITED";
};


//////OBJECTIVE/////////////////////////////////////////////////////////////////////////////////////////


_Buildings = nearestObjects [(getpos _thisTownTrigger), ["House"], 200];  
_allPositionBuildings = _Buildings select {count (_x buildingPos -1) > 2}; 
_Position = _allPositionBuildings select 0;
_Pos = selectRandom (_Position buildingPos -1);

_V = createVehicle [selectRandom ["Land_PowerGenerator_F", "Box_FIA_Ammo_F", "Box_FIA_Support_F"] , _Pos, [], 500, "NONE"]; 


_V allowDammage false;
_V setPos _Pos;
sleep 3;
_V allowDammage true;

if (typeOf _V == "Land_PowerGenerator_F") then {
	_V addEventHandler ["Killed", { 
	
[] execVM "Scripts\ReputationMinus.sqf";
execVM "Scripts\Civ_Relations.sqf";
[(_this select 0)] execVM 'Scripts\Sabotage.sqf';
}];
_V = createVehicle ["Land_TTowerSmall_2_F", getPos _V, [], 2, "NONE"]; 
 
} else {

_V addEventHandler ["Killed", { 
 
["ScoreAdded", ["Insurgent Stash Destroyed", 30]] call BIS_fnc_showNotification; 

[30] call FLO_fnc_addReward;
[] execVM "Scripts\ReputationPlus.sqf";

execVM "Scripts\Civ_Relations.sqf";
 playMusic "EventTrack01_F_Curator"; 
}];

};


_V addBackpackCargoGlobal ["B_UAV_01_backpack_F", 2];
_V addBackpackCargoGlobal ["B_Static_Designator_01_weapon_F", 2];
_V addBackpackCargoGlobal ["B_W_Static_Designator_01_weapon_F", 2];
_V addBackpackCargoGlobal ["B_UGV_02_Demining_backpack_F", 2];
_V addBackpackCargoGlobal ["B_Patrol_Respawn_bag_F", 2];

//////Garrisons/////////////////////////////////////////////////////////////////////////////////////////

_allBuildings = nearestObjects [getPos _thisTownTrigger, ["HOUSE"], 220];
_allPositionBuildings = _allBuildings select {count (_x buildingPos -1) > 2}; 
_Position = _allPositionBuildings select 0;

_Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;    
  ((units G) select 0) disableAI "PATH";

 
_Pos = _thisTownTrigger getPos [(5 +(random 10)), (0 + (random 360))];
 G = [_Pos, East,[selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;    
[G, getPos _thisTownTrigger, 30] call BIS_fnc_taskPatrol;
 
if (_AGGRSCORE > 5) then {
	
_Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;    
   ((units G) select 0) disableAI "PATH";
   
_Pos = _thisTownTrigger getPos [(5 +(random 10)), (0 + (random 360))];
 G = [_Pos, East,[selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;    
[G, getPos _thisTownTrigger, 50] call BIS_fnc_taskPatrol;
 };

if (_AGGRSCORE > 10) then {
	
_Pos = selectRandom (_Position buildingPos -1);
 G = [_Pos, East,[selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;    
   ((units G) select 0) disableAI "PATH";
   
_Pos = _thisTownTrigger getPos [(5 +(random 10)), (0 + (random 360))];
 G = [_Pos, East,[selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;    
[G, getPos _thisTownTrigger, 100] call BIS_fnc_taskPatrol;  

};



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// {

// _nvg = hmd _x;
//  _x unassignItem _nvg;
//  _x removeItem _nvg;
// 	  _x addPrimaryWeaponItem "acc_flashlight";
// 	  _x assignItem "acc_flashlight";
// 	  _x enableGunLights "ForceOn";
//   } foreach (allUnits select {side _x == east}); 


sleep 10;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

{ if !((side _x) == west) then {
            ZEUS removeCuratorEditableObjects [[_x],true];
}; } foreach allUnits;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

sleep 2 ;




