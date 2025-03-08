_thisShipTrigger = _this select 0; 

_Chance = selectRandom [1, 2, 3]; 

_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

VEH = createVehicle ["Land_Destroyer_01_base_F", (getPos _thisShipTrigger), [], 2, "NONE"]; 
VEH setPosWorld (getPos _thisShipTrigger); 
VEH setVectorUp [0,0,1]; 
VEH setDir (0 +(random 360));
VEH call BIS_fnc_Carrier01PosUpdate; 
 
_destroyer = VEH;   
_flag = [_destroyer, "ShipFlag_US_F"] call bis_fnc_destroyer01GetShipPart;  
_flag setflagtexture "a3\data_f\flags\flag_csat_co.paa"; 

_dir = getDirVisual VEH + 100; 
P1 = selectRandom [ 
 "Ship_01",  
 "Ship_02",  
 "Ship_03"   
 ]; 
[ P1, getPos VEH, [-9,-2,4], _dir, true ] call LARs_fnc_spawnComp; 
{_x setUnitLoadout selectRandom East_Units;} forEach nearestObjects [getPosATL _thisShipTrigger,["Man"],100];



VP = selectRandom [ 
 "O_Boat_Armed_01_hmg_F",
 "O_Boat_Transport_01_F"
 ]; 
_V = createVehicle [ VP, (getpos VEH), [], 200, "NONE"]; 
_V setPilotLight true;
_V setDir (0 +(random 360));
_CVEH = [(getpos VEH), east, 4] call BIS_fnc_spawnGroup;
{_x setUnitLoadout selectRandom East_Units;} forEach units _CVEH;  
{_x moveInAny _V} foreach units _CVEH;  


if (_AGGRSCORE > 5) then {
VP = selectRandom [ 
 "O_Boat_Armed_01_hmg_F",
 "O_Boat_Transport_01_F"
 ]; 
_V = createVehicle [ VP, (getpos VEH), [], 200, "NONE"]; 
_V setPilotLight true;
_V setDir (0 +(random 360));
_CVEH = [(getpos VEH), east, 4] call BIS_fnc_spawnGroup;
{_x setUnitLoadout selectRandom East_Units;} forEach units _CVEH;  
{_x moveInAny _V} foreach units _CVEH;  
};

if (_AGGRSCORE > 10) then {
VP = selectRandom [ 
 "O_Boat_Armed_01_hmg_F",
 "O_Boat_Transport_01_F"
 ]; 
_V = createVehicle [ VP, (getpos VEH), [], 200, "NONE"]; 
_V setPilotLight true;
_V setDir (0 +(random 360));
_CVEH = [(getpos VEH), east, 4] call BIS_fnc_spawnGroup;
{_x setUnitLoadout selectRandom East_Units;} forEach units _CVEH;  
{_x moveInAny _V} foreach units _CVEH;  
};

sleep 10;
 
_trg = createTrigger ["EmptyDetector", getpos _thisShipTrigger];  
_trg setTriggerArea [120, 120, 0, false, 200];  
_trg setTriggerInterval 6;  
_trg setTriggerActivation ["WEST SEIZED", "PRESENT", false];  
_trg setTriggerStatements [  
"this", "  

_MMarks = allMapMarkers select { markerType _x == 'o_naval'};
_M = [_MMarks,  thisTrigger] call BIS_fnc_nearestPosition;

deleteMarker _M ; 

				[50, 'SHIP'] call FLO_fnc_notification ;

[50] call FLO_fnc_addReward;
[] execVM 'Scripts\DangerPlus.sqf';

 ", ""]; 

