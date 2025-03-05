_thisIntelItem = _this select 0;


_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

_anim =  selectRandom [
"Acts_AidlPsitMstpSsurWnonDnon01",
"Acts_AidlPsitMstpSsurWnonDnon02",
"Acts_AidlPsitMstpSsurWnonDnon03",
"Acts_AidlPsitMstpSsurWnonDnon04",
"Acts_AidlPsitMstpSsurWnonDnon05"
];

				[50, 'INTEL'] call FLO_fnc_notification ;
				[50] call FLO_fnc_addReward;

_CRT = [
"Box_IND_WpsSpecial_F",
"Box_East_WpsSpecial_F",
"Box_IND_Support_F",
"Box_East_Support_F",
"Box_CSAT_Equip_F",
"Box_AAF_Equip_F",
"Box_East_WpsLaunch_F",
"Box_IND_WpsLaunch_F",
"Box_East_AmmoOrd_F",
"Box_East_Ammo_F",
"Box_IND_Ammo_F",
"Box_IND_AmmoOrd_F",
"Box_East_Wps_F",
"Box_IND_Wps_F"
];
				
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


if ((typeOf _thisIntelItem == "Land_File2_F") && (_AGGRSCORE > 5)) then {

_MMarks = allMapMarkers select { markerType _x == "mil_unknown"};
_M = [_MMarks,  _thisIntelItem] call BIS_fnc_nearestPosition;
deleteMarker _M ; 

_allMarks = allMapMarkers select {(markerType _x == "b_installation") or (markerType _x == "o_installation") or (markerType _x == "n_installation") or (markerType _x == "o_support") or (markerType _x == "n_support") or  (markerType _x == "loc_Power") or  (markerType _x == "loc_Ruin")};  
_NOSHs = [] ;
{
_NOSH = nearestObjects [getMarkerPos _x , ["HOUSE"], 400] ; 
_NOSHs append _NOSH ;	
} forEach _allMarks ;

_ALLSHs = nearestObjects [_thisIntelItem , ["HOUSE"], 7000] select {count (_x buildingPos -1) > 2};
_NearSHs = nearestObjects [_thisIntelItem , ["HOUSE"], 200] select {count (_x buildingPos -1) > 2};
_SHs = _ALLSHs - _NearSHs ; 
_SH = _SHs - _NOSHs ;


_HQB = _SH select 0 ;
_dir = getDirVisual _HQB;

[ "Intel_CS_02", (selectRandom (_HQB buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 
_V = createVehicle [(selectRandom _CRT), (selectRandom (_HQB buildingPos -1)), [], 15, "NONE"]; 
_V = createVehicle [(selectRandom _CRT), (selectRandom (_HQB buildingPos -1)), [], 15, "NONE"]; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
((units _G) select 0) disableAI "PATH"; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
((units _G) select 0) disableAI "PATH";   
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 


PRL = [_HQB getPos [(50 +(random 50)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 300] call BIS_fnc_taskPatrol;

if (_AGGRSCORE > 10) then {
PRL = [getPos _HQB, East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 300] call BIS_fnc_taskPatrol;
};

								_markerName = "InvesMark" + (str (getPos _HQB));   
								_mrkr = createMarker [_markerName, (getPos _HQB)];   
								_mrkr setMarkerType "mil_unknown";  
								_mrkr setMarkerColor "colorOPFOR";  
								_mrkr setMarkerSize [0.8, 0.8]; 
								
								["showNotification", ["+ NEW INTEL", "Military Intel Received", "intel"]] call FLO_fnc_intelSystem;
									_attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
								[[west,"HQ"], "Enemy Presence Confirmed at grid " + _attackingAtGrid] remoteExec ["sideChat", 0];
//////Gaurds/////////////////////////////////////////////////////////////////////////////////////////

_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH"; 


_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  


if (_AGGRSCORE > 5) then {
_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH"; 
}; 

if (_AGGRSCORE > 10) then {
_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  

}; 

//////GROUPS/////////////////////////////////////////////////////////////////////////////////////////

if (_AGGRSCORE > 5) then {
PRL = [_HQB getPos [(50 +(random 200)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 300] call BIS_fnc_taskPatrol;
};

if (_AGGRSCORE > 10) then {
PRL = [_HQB getPos [(50 +(random 200)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 1000] call BIS_fnc_taskPatrol;
};

_trgA = createTrigger ["EmptyDetector", (getPos _HQB)];
_trgA setTriggerArea [300, 300, 0, false, 60];
_trgA setTriggerInterval 3;
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this", "

_QRF = selectRandom [ 'Scripts\HeliInsert_CSAT.sqf', 'Scripts\VehiInsert_CSAT.sqf']; 
[thisTrigger] execVM _QRF;

",""];


} ;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

if ((typeOf _thisIntelItem == "Land_Document_01_F") && (_AGGRSCORE > 10)) then {
	
_MMarks = allMapMarkers select { markerType _x == "mil_unknown"};
_M = [_MMarks,  _thisIntelItem] call BIS_fnc_nearestPosition;
deleteMarker _M ; 

	

_allMarks = allMapMarkers select {(markerType _x == "b_installation") or (markerType _x == "o_installation") or (markerType _x == "n_installation") or (markerType _x == "o_support") or (markerType _x == "n_support") or  (markerType _x == "loc_Power") or  (markerType _x == "loc_Ruin") };  
_NOSHs = [] ;
{
_NOSH = nearestObjects [getMarkerPos _x , ["HOUSE"], 400] ; 
_NOSHs append _NOSH ;	
} forEach _allMarks ;

_ALLSHs = nearestObjects [_thisIntelItem , ["HOUSE"], 7000] select {count (_x buildingPos -1) > 2};
_NearSHs = nearestObjects [_thisIntelItem , ["HOUSE"], 200] select {count (_x buildingPos -1) > 2};
_SHs = _ALLSHs - _NearSHs ; 
_SH = _SHs - _NOSHs ;


_HQB = _SH select 0 ;
_dir = getDirVisual _HQB;

[ "Intel_CS_03", (selectRandom (_HQB buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 
_V = createVehicle [(selectRandom _CRT), (selectRandom (_HQB buildingPos -1)), [], 15, "NONE"]; 
_V = createVehicle [(selectRandom _CRT), (selectRandom (_HQB buildingPos -1)), [], 15, "NONE"]; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
((units _G) select 0) disableAI "PATH"; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
((units _G) select 0) disableAI "PATH";   
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 


PRL = [_HQB getPos [(50 +(random 50)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 300] call BIS_fnc_taskPatrol;

if (_AGGRSCORE > 10) then {
PRL = [getPos _HQB, East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 300] call BIS_fnc_taskPatrol;
};

								_markerName = "InvesMark" + (str (getPos _HQB));   
								_mrkr = createMarker [_markerName, (getPos _HQB)];   
								_mrkr setMarkerType "mil_unknown";  
								_mrkr setMarkerColor "colorOPFOR";  
								_mrkr setMarkerSize [0.8, 0.8]; 
								
								["showNotification", ["+ NEW INTEL", "Military Intel Received", "intel"]] call FLO_fnc_intelSystem;
									_attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
								[[west,"HQ"], "Enemy Presence Confirmed at grid " + _attackingAtGrid] remoteExec ["sideChat", 0];
//////Gaurds/////////////////////////////////////////////////////////////////////////////////////////

_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH"; 


_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  


if (_AGGRSCORE > 5) then {
_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH"; 
}; 

if (_AGGRSCORE > 10) then {
_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  

}; 

//////GROUPS/////////////////////////////////////////////////////////////////////////////////////////

if (_AGGRSCORE > 5) then {
PRL = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 300] call BIS_fnc_taskPatrol;
};

if (_AGGRSCORE > 10) then {
PRL = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 1000] call BIS_fnc_taskPatrol;
};

_trgA = createTrigger ["EmptyDetector", (getPos _HQB)];
_trgA setTriggerArea [300, 300, 0, false, 60];
_trgA setTriggerInterval 3;
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this", "

_QRF = selectRandom [ 'Scripts\HeliInsert_CSAT.sqf', 'Scripts\VehiInsert_CSAT.sqf']; 
[thisTrigger] execVM _QRF;

",""];


} ;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

if ((typeOf _thisIntelItem == "Land_Map_Malden_F") || ((typeOf _thisIntelItem == "Land_Document_01_F") && (_AGGRSCORE < 11)) || ((typeOf _thisIntelItem == "Land_File2_F") && (_AGGRSCORE < 6))) then {

_MMarks = allMapMarkers select { markerType _x == "mil_unknown"};
_M = [_MMarks,  _thisIntelItem] call BIS_fnc_nearestPosition;
deleteMarker _M ; 

	

_ALLMounts = nearestLocations [getPos _thisIntelItem, ["Mount"], 500];   
_NearMounts = nearestLocations [getPos _thisIntelItem, ["Mount"], 200];   
_Mounts = _ALLMounts - _NearMounts ;
_Mount = selectRandom _Mounts; 
_CrashedHeli = createVehicle ["Land_Wreck_Heli_Attack_01_F",[(locationPosition _Mount) select 0, (locationPosition _Mount) select 1, ((locationPosition _Mount) select 2) + 5],[],0,'NONE'];
_CrashedHeli setVectorUp [0,0,1];

[ _CrashedHeli,
"<img size=2 color='#FFE258' image='Screens\FOBA\destroy_ca.paa'/><t font='PuristaBold' color='#FFE258'>Sabotage Technology",
"Screens\FOBA\destroy_ca.paa",
"Screens\FOBA\destroy_ca.paa",
"true",       
"_caller distance _target < 40",  
{},
{},
{[(_this select 0)] execVM "Scripts\SabTech.sqf";},
{},
[],
5,
1,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   
	
sleep 1;

[ "Crash_Site", getPos _CrashedHeli, [0, 0, 0],0, true ] call LARs_fnc_spawnComp;

[_CrashedHeli, 0, _PosAGL, "ATL"] call BIS_fnc_setHeight;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_allMarks = allMapMarkers select {(markerType _x == "b_installation") or (markerType _x == "o_installation") or (markerType _x == "n_installation") or (markerType _x == "o_support") or (markerType _x == "n_support") or  (markerType _x == "loc_Power") or  (markerType _x == "loc_Ruin") };  
_NOSHs = [] ;
{
_NOSH = nearestObjects [getMarkerPos _x , ["HOUSE"], 400] ; 
_NOSHs append _NOSH ;	
} forEach _allMarks ;

_ALLSHs = nearestObjects [_thisIntelItem , ["HOUSE"], 7000] select {count (_x buildingPos -1) > 2};
_NearSHs = nearestObjects [_thisIntelItem , ["HOUSE"], 200] select {count (_x buildingPos -1) > 2};
_SHs = _ALLSHs - _NearSHs ; 
_SH = _SHs - _NOSHs ;


_HQB = _SH select 0 ;

								_markerName = "InvesMark" + (str (getPos _HQB));   
								_mrkr = createMarker [_markerName, (getPos _HQB)];   
								_mrkr setMarkerType "mil_unknown";  
								_mrkr setMarkerColor "colorOPFOR";  
								_mrkr setMarkerSize [0.8, 0.8]; 
								
								["showNotification", ["+ NEW INTEL", "Military Intel Received", "intel"]] call FLO_fnc_intelSystem;
									_attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
								[[west,"HQ"], "Enemy Presence Confirmed at grid " + _attackingAtGrid] remoteExec ["sideChat", 0];
								
								
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
((units _G) select 0) disableAI "PATH";  
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
((units _G) select 0) disableAI "PATH";  

PRL = [_HQB getPos [(50 +(random 50)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 500] call BIS_fnc_taskPatrol;

PRL = [_HQB getPos [(50 +(random 100)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 500] call BIS_fnc_taskPatrol;


if (_AGGRSCORE > 10) then {
PRL = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 1000] call BIS_fnc_taskPatrol;


_trgA = createTrigger ["EmptyDetector", (getPos _HQB)];
_trgA setTriggerArea [300, 300, 0, false, 60];
_trgA setTriggerInterval 3;
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this", "

_QRF = selectRandom [ 'Scripts\HeliInsert_CSAT.sqf', 'Scripts\VehiInsert_CSAT.sqf']; 
[thisTrigger] execVM _QRF;

",""];
};


_POWG = [(selectRandom (_HQB buildingPos -1)) , civilian,["B_Pilot_F"]] call BIS_fnc_spawnGroup;         
_POW = (units _POWG) select 0;
_POW setUnitLoadout "B_Helipilot_F";
_POW disableAI "ANIM"; 
_POW disableAI "PATH";
_POW switchMove _anim;
removeAllWeapons _POW;
removeBackpack _POW;
removeVest _POW;
_POW setCaptive true;
[
  _POW,
"Rescue",
"\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_unbind_ca.paa",
"\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_unbind_ca.paa",
 "_this distance _target < 5",       
 "_caller distance _target < 5",  
{},
{},
{
_complMessage = selectRandom ["I thought I was gonna die in here!","Thank you so much Brother.","I'M ALIVE."];
["Hostage", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
(_this select 0) switchMove "Acts_AidlPsitMstpSsurWnonDnon_out";
(_this select 0) enableAI "PATH";
(_this select 0) enableAI "ANIM";
(_this select 0) setBehaviour "AWARE";
_POW setCaptive false;
[(_this select 0)] joinSilent player;


_MMarks = allMapMarkers select { markerType _x == "mil_unknown"};
_M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;

deleteMarker _M ; 

[50] call FLO_fnc_addReward;
[(_this select 0), 1500] call FLO_fnc_requestQRF;
				[50, "CAPTURED PILOT"] call FLO_fnc_notification ;


[(_this select 0),(_this select 2)] remoteExec ["bis_fnc_holdActionRemove",[0,-2] select isDedicated,true];
},
{},
[],
3,
0,
true,
false
] remoteExec ["BIS_fnc_holdActionAdd", 0, _POW]; 

//////Gaurds/////////////////////////////////////////////////////////////////////////////////////////

_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH"; 


_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  


if (_AGGRSCORE > 5) then {
_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
((units G) select 0) disableAI "PATH"; 
}; 

if (_AGGRSCORE > 10) then {
_poss = [(getpos _HQB), 30, 50, 5, 1 , 0] call BIS_fnc_findSafePos; 
G = [_poss, East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  

}; 

//////GROUPS/////////////////////////////////////////////////////////////////////////////////////////

if (_AGGRSCORE > 5) then {
PRL = [_HQB getPos [(50 +(random 200)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 300] call BIS_fnc_taskPatrol;
};

if (_AGGRSCORE > 10) then {
PRL = [_HQB getPos [(50 +(random 200)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 1000] call BIS_fnc_taskPatrol;
};

_trgA = createTrigger ["EmptyDetector", (getPos _HQB)];
_trgA setTriggerArea [300, 300, 0, false, 60];
_trgA setTriggerInterval 3;
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this", "

_QRF = selectRandom [ 'Scripts\HeliInsert_CSAT.sqf', 'Scripts\VehiInsert_CSAT.sqf']; 
[thisTrigger] execVM _QRF;

",""];

};

sleep 2 ;

