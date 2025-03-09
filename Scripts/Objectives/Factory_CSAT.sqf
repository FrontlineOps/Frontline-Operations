_thisFactoryTrigger = _this select 0; 
_Chance = selectRandom [1, 2, 3]; 

_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

sleep 3;
_objectLoc = nearestobjects [getPos _thisFactoryTrigger, ["O_MBT_02_cannon_F"], 100]; 
{  
	_x hideObject true ; 
	sleep 1;

	_dir = getDirVisual _x ;
	_pos = position _x ;

	_NewVeh = createVehicle [selectRandom East_Ground_Vehicles_Heavy, [0,0, (500 + random 2000)], [], 0, "CAN_COLLIDE"] ;
		_NewVeh setDir _dir ;
		_NewVeh setVehicleLock "LOCKED";

	deleteVehicle _x ;

	_NewVeh setVehiclePosition [ _pos, [], 0, "CAN_COLLIDE"];


	sleep 1;
		_NewVeh addEventHandler ["Killed", {
	["ScoreAdded", ["Enemy Armor Sabotaged", 10]] remoteExec ["BIS_fnc_showNotification", 0];
	[10] call FLO_fnc_addReward; 
	playMusic "EventTrack01_F_Curator"; 
	execVM 'Scripts\ArmorDis.sqf';
	}];
} forEach _objectLoc;

sleep 10;

_trg = createTrigger ["EmptyDetector", getPos _thisFactoryTrigger, false];  
_trg setTriggerArea [1000, 1000, 0, false, 200];  
_trgA setTriggerTimeout [2, 2, 2, true];
_trg setTriggerActivation ["WEST", "PRESENT", false];  
_trg setTriggerStatements [  
"this",  "[thisTrigger, 750] execVM 'Scripts\Objectives\ZONEs.sqf';", ""]; 

_trg = createTrigger ["EmptyDetector", getpos _thisFactoryTrigger, false];  
_trg setTriggerArea [120, 120, 0, false, 200];  
_trg setTriggerInterval 6;  
_trg setTriggerActivation ["WEST SEIZED", "PRESENT", false];  
_trg setTriggerStatements [  
"this && {(alive _x) && ((side _x) == EAST) && (position _x inArea thisTrigger)} count allUnits < 3", "  

{ if (((side _x) == east) && (position _x inArea  thisTrigger))then {
_x disableAI 'PATH';
_x disableAI 'ANIM'; 
removeAllWeapons _x;
removeBackpack _x;
_x setCaptive true;
_x switchMove 'AmovPercMstpSsurWnonDnon';

_x addEventHandler ['Killed', { 
[] execVM 'Scripts\DangerPlusSurr.sqf';
removeAllActions (_this select 0) ;
}];

[
  _x,
'Arrest',
'Screens\FOBA\holdAction_secure_ca.paa',
'Screens\FOBA\holdAction_secure_ca.paa',
'_this distance _target < 3',       
'_caller distance _target < 3',  
{},
{},
{
(_this select 0) enableAI 'ANIM';
(_this select 0) enableAI 'PATH';
(_this select 0) switchMove '';
(_this select 0) setBehaviour 'AWARE';
[(_this select 0)] joinSilent player;
removeAllActions (_this select 0);
},
{},
[],
3,
0,
true,
false
] remoteExec ['BIS_fnc_holdActionAdd', 0, _x]; 

[
  _x,
'Release',
'\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_unbind_ca.paa',
'\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_unbind_ca.paa',
'_this distance _target < 3',       
'_caller distance _target < 3',  
{(_this select 0) setDir (position (_this select 0) getDir position player);},
{},
{
(_this select 0) enableAI 'ANIM';
(_this select 0) enableAI 'PATH';
(_this select 0) switchMove '';
(_this select 0) setBehaviour 'AWARE';
removeAllActions (_this select 0);
_x removeAllEventHandlers 'Killed';
( group (_this select 0)) addWaypoint [ player getPos [ (3000 + (random 1000)),(0 + (random 360))], 0];

[] execVM 'Scripts\DangerMinusSurr.sqf';

[(_this select 0),(_this select 2)] remoteExec ['bis_fnc_holdActionRemove',[0,-2] select isDedicated,true];

},
{},
[],
3,
0,
true,
false
] remoteExec ['BIS_fnc_holdActionAdd', 0, _x]; 

}; } foreach allUnits;

_alltriggers = allMissionObjects 'EmptyDetector';
_triggers = _alltriggers select {triggerInterval _x == 10 && getPos _x distance thisTrigger < 100};
_referencePos = getPos thisTrigger; 
_sortedByRange = [_triggers,[],{_referencePos distanceSqr getPos _x},'ASCEND'] call BIS_fnc_sortBy;
_sortedByRange params ['_nearesttrigger'];
deleteVehicle _nearesttrigger;

_MMarks = allMapMarkers select { markerType _x == ""o_maint""};
_M = [_MMarks,  thisTrigger] call BIS_fnc_nearestPosition;

deleteMarker _M ; 

_markerName = ""respawn_west"" + (str (getPos thisTrigger));  
_mrkr = createMarker [_markerName, getPos thisTrigger] ;
_mrkr setMarkerType ""b_installation""; 
_mrkr setMarkerColor ""colorBLUFOR"";
_mrkr setMarkerSize [1.2, 1.2]; 

 _TFOBB = createTrigger [""EmptyDetector"", getPos thisTrigger, false];
_TFOBB setTriggerArea [100, 100, 0, false, 50];
_TFOBB setTriggerInterval 2;
_TFOBB setTriggerActivation [""EAST SEIZED"", ""PRESENT"", false];
_TFOBB setTriggerStatements [
'this && {(alive _x) && ((side _x) == WEST) && (position _x inArea thisTrigger)} count allUnits < 5 ','

[playerSide, 'HQ'] commandChat 'all Forces Fall Back. We Lost the Region,...';

_allMarks = allMapMarkers select {markerPos _x inArea thisTrigger && markerType _x == 'b_installation'};  
	{ deleteMarker _x ; } forEach _allMarks; 

_markerName = ""Outpost"" + (str (getPos thisTrigger));  
_mrkr = createMarker [_markerName, getPos thisTrigger] ;
_mrkr setMarkerType ""o_support""; 
_mrkr setMarkerColor ""colorOPFOR"";
_mrkr setMarkerSize [1.2, 1.2]; 

_alltriggers = allMissionObjects ""EmptyDetector"";
_triggers = _alltriggers select {position _x inArea thisTrigger};
{deleteVehicle _x;}forEach _triggers;

', ''];

[50] call FLO_fnc_addReward;
[thisTrigger, 1000] call FLO_fnc_requestQRF;

_markerName = ""AssaultMark"" + (str (position player));  
_mrkr = createMarker [_markerName, position player]; 
_mrkr setMarkerType ""loc_Bunker"";
_mrkr setMarkerAlpha 0.003;

_mrkrs = allMapMarkers select {markerColor _x == 'Color6_FD_F'};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  
_allCaptureMarks = allMapMarkers select {markerType _x == ""loc_Bunker""};  

if ((_AGGRSCORE > 10) && (count (_allCaptureMarks) >=1)) then { execVM ""Scripts\Mission_Defend.sqf""; };
if (count (_allCaptureMarks) ==2) then { _Chance = selectRandom [1, 2];  if (_Chance == 1) then { execVM ""Scripts\Mission_Defend.sqf""; }; };
if (count (_allCaptureMarks) ==3) then { execVM ""Scripts\Mission_Defend.sqf""; };

[] execVM 'Scripts\DangerPlus.sqf';

[""ScoreAdded"", [""Logistic Base Secured"", 50]] remoteExec ['BIS_fnc_showNotification', 0];
 playMusic ""EventTrack01_F_Curator"";   


", ""]; 

_trg = createTrigger ["EmptyDetector", getpos _thisFactoryTrigger, false];
_trg setTriggerArea [5000, 5000, 0, false, 500];
_trg setTriggerInterval 10;
_trg setTriggerTimeout [10, 10, 10, true];
_trg setTriggerActivation ["WEST", "NOT PRESENT", false];
_trg setTriggerStatements [
"this","


{deleteVehicle _x}foreach (allUnits select {side _x == east && getPos _x distance thisTrigger < 200}); 
_Vehicles = nearestobjects [thisTrigger, [""LandVehicle"", ""Air""], 200]; 
{deleteVehicle _x}foreach _Vehicles; 

_alltriggers = allMissionObjects 'EmptyDetector';
_triggers = _alltriggers select {triggerInterval _x == 6 && getPos _x distance thisTrigger < 100};
_referencePos = getPos thisTrigger; 
_sortedByRange = [_triggers,[],{_referencePos distanceSqr getPos _x},'ASCEND'] call BIS_fnc_sortBy;
_sortedByRange params ['_nearesttrigger'];
deleteVehicle _nearesttrigger;

_trgA = createTrigger ['EmptyDetector', getPos thisTrigger, false];
_trgA setTriggerArea [2000, 2000, 0, false, 300];
_trgA setTriggerInterval 20;
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
'this','

[thisTrigger] execVM ""Scripts\Objectives\Factory_CSAT.sqf"";

', ''];

", ""];

 
{ if !((side _x) == west) then {
            ZEUS removeCuratorEditableObjects [[_x],true];
}; } foreach allUnits;
 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

[_thisFactoryTrigger, 200] execVM "Scripts\INTLitems.sqf";

sleep 2 ;



if ((!isMultiplayer) or (isServer)) then {
UNIT_LIMIT = 50 ;
	publicVariable "UNIT_LIMIT";
} ;

if (isDedicated) then {
UNIT_LIMIT = 100 ;
	publicVariable "UNIT_LIMIT";
};

if (!(isServer) && !(hasInterface)) then {
UNIT_LIMIT = 150 ;
	publicVariable "UNIT_LIMIT";
} ; 