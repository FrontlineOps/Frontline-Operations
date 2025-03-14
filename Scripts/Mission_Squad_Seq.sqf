_thisIntelItem = _this select 0;

_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

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

_MMarks = allMapMarkers select { markerType _x == "mil_warning"};
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


[ "Intel_MIS_02", (selectRandom (_HQB buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 
_V = createVehicle [(selectRandom _CRT), (selectRandom (_HQB buildingPos -1)), [], 15, "NONE"]; 
_V = createVehicle [(selectRandom _CRT), (selectRandom (_HQB buildingPos -1)), [], 15, "NONE"]; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
((units _G) select 0) disableAI "PATH";  
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
((units _G) select 0) disableAI "PATH";  
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 


PRL = [_HQB getPos [(50 +(random 50)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 200] call BIS_fnc_taskPatrol;

								_markerName = "InvesMark" + (str (getPos _HQB));   
								_mrkr = createMarker [_markerName, (getPos _HQB)];   
								_mrkr setMarkerType "mil_warning";  
								_mrkr setMarkerColor "colorOPFOR";  
								_mrkr setMarkerSize [0.8, 0.8]; 

								["showNotification", ["+ NEW INTEL", "Military Intel Received", "intel"]] call FLO_fnc_intelSystem;
									_attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
								[[west,"HQ"], "Enemy Presence Confirmed at grid " + _attackingAtGrid] remoteExec ["sideChat", 0];
								
//////////////////////////////////


G = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  

G = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  

if (_AGGRSCORE > 5) then {
G = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
}; 

if (_AGGRSCORE > 10) then {
G = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
}; 


//////GROUPS/////////////////////////////////////////////////////////////////////////////////////////

PRL = [_HQB getPos [(50 +(random 200)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 500] call BIS_fnc_taskPatrol;


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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

if ((typeOf _thisIntelItem == "Land_Document_01_F") && (_AGGRSCORE > 10)) then {

_MMarks = allMapMarkers select { markerType _x == "mil_warning"};
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


[ "Intel_MIS_03", (selectRandom (_HQB buildingPos -1)), [0,0,0], _dir, false, false, true ] call LARs_fnc_spawnComp; 
_V = createVehicle [(selectRandom _CRT), (selectRandom (_HQB buildingPos -1)), [], 15, "NONE"]; 
_V = createVehicle [(selectRandom _CRT), (selectRandom (_HQB buildingPos -1)), [], 15, "NONE"]; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
((units _G) select 0) disableAI "PATH";  
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
((units _G) select 0) disableAI "PATH";  
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 
_G = [ (selectRandom (_HQB buildingPos -1)), East,[selectRandom East_Units]] call BIS_fnc_spawnGroup; 


PRL = [_HQB getPos [(50 +(random 50)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 200] call BIS_fnc_taskPatrol;

								_markerName = "InvesMark" + (str (getPos _HQB));   
								_mrkr = createMarker [_markerName, (getPos _HQB)];   
								_mrkr setMarkerType "mil_warning";  
								_mrkr setMarkerColor "colorOPFOR";  
								_mrkr setMarkerSize [0.8, 0.8]; 
								
								["showNotification", ["+ NEW INTEL", "Military Intel Received", "intel"]] call FLO_fnc_intelSystem;
									_attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
								[[west,"HQ"], "Enemy Presence Confirmed at grid " + _attackingAtGrid] remoteExec ["sideChat", 0];
								
								
//////Gaurds/////////////////////////////////////////////////////////////////////////////////////////


G = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  

G = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  

if (_AGGRSCORE > 5) then {
G = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
}; 

if (_AGGRSCORE > 10) then {
G = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East,[selectRandom East_Units]] call BIS_fnc_spawnGroup;  
}; 


//////GROUPS/////////////////////////////////////////////////////////////////////////////////////////

PRL = [_HQB getPos [(50 +(random 250)), (0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, getPos _HQB, 500] call BIS_fnc_taskPatrol;


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


};


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

if ((typeOf _thisIntelItem == "Land_Map_Malden_F") || ((typeOf _thisIntelItem == "Land_Document_01_F") && (_AGGRSCORE < 11)) || ((typeOf _thisIntelItem == "Land_File2_F") && (_AGGRSCORE < 6))) then {


_MMarks = allMapMarkers select { markerType _x == "mil_warning"};
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

								_markerName = "InvesMark" + (str (getPos _HQB));   
								_mrkr = createMarker [_markerName, (getPos _HQB)];   
								_mrkr setMarkerType "mil_warning";  
								_mrkr setMarkerColor "colorOPFOR";  
								_mrkr setMarkerSize [0.8, 0.8]; 
								
								["showNotification", ["+ NEW INTEL", "Military Intel Received", "intel"]] call FLO_fnc_intelSystem;
									_attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
								[[west,"HQ"], "Enemy Presence Confirmed at grid " + _attackingAtGrid] remoteExec ["sideChat", 0];



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


_G = [ (selectRandom (_HQB buildingPos -1)), civilian,["B_Pilot_F", "B_Pilot_F", "B_Pilot_F", "B_Pilot_F"]] call BIS_fnc_spawnGroup; 

{_x disableAI "PATH"; _x setCaptive true; _x setUnitPos "MIDDLE";} forEach units _G; 

((units _G) select 0) setUnitLoadout F_Assault_TL;
((units _G) select 1) setUnitLoadout F_Assault_Med;
((units _G) select 2) setUnitLoadout F_Assault_Eng;
((units _G) select 3) setUnitLoadout F_Assault_Amm;

((units _G) select 0) setPos ((_HQB buildingPos -1) select 1);
((units _G) select 1) setPos ((_HQB buildingPos -1) select 2);
((units _G) select 2) setPos ((_HQB buildingPos -1) select 3);
((units _G) select 3) setPos ((_HQB buildingPos -1) select 4);


_TFOBH = createTrigger ["EmptyDetector", getPos _HQB];  
_TFOBH setTriggerArea [10, 10, 0, false, 5];  
_TFOBH setTriggerInterval 2;  
_TFOBH setTriggerActivation ["ANYPLAYER", "PRESENT", false];  
_TFOBH setTriggerStatements [  
"this",  
"  

			playSound3D [(getMissionPath 'Sounds\c_eb_35_natojoin_KER_0.ogg'), player];

_MMarks = allMapMarkers select { markerType _x == 'mil_warning'};
_M = [_MMarks,  thisTrigger] call BIS_fnc_nearestPosition;

deleteMarker _M ; 

_POW = nearestObjects [thisTrigger , ['B_Pilot_F'], 200] ;  
_CPOW = _POW select {side _x == civilian};
_THPOW = _CPOW select 0;
_GRS = group _THPOW;
			playSound3D [(getMissionPath 'Sounds\c_eb_35_natojoin_MEM_0.ogg'), _THPOW];

_Group = createGroup West; 
{[_x] join _Group; _x enableAI 'PATH'; _x setCaptive false; _x setUnitPos 'AUTO';} forEach units _GRS;

private _headlessClients = entities 'HeadlessClient_F';
private _humanPlayers = allPlayers - _headlessClients;
hcRemoveAllGroups player;  
 {player hcRemoveGroup _x ;} forEach (allGroups select {side _x == west}); 
 _GRPs = (allGroups select {(side _x == (side player)) && !(((units _x) select 0) in switchableUnits)}); 
if (count _humanPlayers == 1 ) then {
{player hcSetGroup [_x];} forEach _GRPs;
}else{
{TheCommander hcSetGroup [_x];} forEach _GRPs;
};

			playSound3D [(getMissionPath 'Sounds\c_eb_35_natojoin_MEM_0.ogg'), ((units _Group) select 0)];
			
[50, 'MISSING SQUAD'] call FLO_fnc_notification ;
[thisTrigger, 1500] call FLO_fnc_requestQRF;
[50] call FLO_fnc_addReward;
 ", ""]; 
 
}; 
 
 /////////////////////////////////////////////////////////////////////////////////////////
 
 sleep 2 ;
