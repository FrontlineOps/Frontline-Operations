if (!isServer) exitWith {};

Centerposition = [worldSize / 2, worldsize / 2, 0];

["LOADING . . . "] remoteExec ["hint", 0];
///////// Init Weather //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_Fog_Int = selectRandom [0, 0, 0.05, 0.05, 0.1, 0.1, 0.1, 0.2, 0.2, 0.3, 0.4, 0.5] ;
_Fog_Dec = selectRandom [0.01, 0.01, 0.01, 0.02, 0.03,  0.05, 0.05, 0.1, 0.1] ;
_OverC_Int = selectRandom [ 0.1, 0.1, 0.1, 0.3,  0.3,  0.3,  0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1, 1] ;

_Fog_Alt = 0 ;

if (_OverC_Int >= 0.6) then {
0 setFog [_Fog_Int, _Fog_Dec, _Fog_Alt];
}else{
0 setFog [0, _Fog_Dec, _Fog_Alt];
}	;

0 setOvercast _OverC_Int;

forceWeatherChange;

[[west,"HQ"], "Weather Initialized Successfully ..."] remoteExec ["sideChat", 0];

///////// Init FOBs //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Initialize FOB objects
private _centerPosition = [worldSize / 2, worldsize / 2, 0];

// Find all FOB buildings of type F_HQ_01
private _fobBuildings = nearestObjects [_centerPosition, [F_HQ_01], 40000];
FOBB = _fobBuildings;
publicVariable "FOBB";

// Add creation factory to FOBs with container
{
    private _nearbyContainers = nearestObjects [_x, [F_HQ_C_01], 20];
    if (count _nearbyContainers > 0) then {
        { nul = [_x, -1, west, "LIGHT"] execVM "R3F_LOG\USER_FUNCT\init_creation_factory.sqf"; } remoteExec ["call", 0, true];
    };
} forEach _fobBuildings;

// Find additional FOB building types
FOBB = nearestObjects [_centerPosition, ["Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"], 40000];
publicVariable "FOBB";

{ 
	if (count (nearestObjects [ _x, [F_HQ_C_01], 20]) > 0) then { 

		// Create marker and set variable
    	_relpos = _x getRelPos [12, 0];
    	_markerName = "respawn_west" + (str (getPos _x));  
    	_mrkr = createMarker [_markerName, _relpos];  
    	_mrkr setMarkerType "b_installation";
    	_mrkr setMarkerColor "ColorYellow";
    	_mrkr setMarkerText "FOB";
    	_mrkr setMarkerSize [2, 2];
    	_x setVariable ["fobMarkerName", _markerName, true];  // Set on FOB object

		{ nul = [_x, -1, west, "LIGHT"] execVM "R3F_LOG\USER_FUNCT\init_creation_factory.sqf"; } remoteExec ["call", 0, true];


		[ _x,
		"<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
		"Screens\FOBA\mg_ca.paa",
		"Screens\FOBA\mg_ca.paa",
			"_this distance _target < 10",			
			"_caller distance _target < 10",	
		{},
		{},
		{
			
			if (isClass (configfile >> "ace_arsenal_loadoutsDisplay") == true ) then {
				[player, player, true] call ace_arsenal_fnc_openBox;
			} else {
				["Open", true] spawn BIS_fnc_arsenal;
			};
		},
		{},
		[],
		1,
		9999999,
		false,
		false
		] remoteExec ["BIS_fnc_holdActionAdd",0,true];   



		[ _x,
		"<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Pack FOB",
		"Screens\FOBA\b_hq.paa",
		"Screens\FOBA\b_hq.paa",
		"player == TheCommander",       
		"_caller distance _target < 40",  
		{},
		{},
		{execVM 'Scripts\FOBPACK.sqf';},
		{},
		[],
		5,
		2,
		false,
		false
		] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

		[_x,[
			"<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>REQUEST MENU",
			"Scripts\RequestMenu\Dialog_Request.sqf",
			nil,
			99999,
			true,
			true,
			"",
			"", // _target, _this, _originalTarget
			40,
			false,
			"",
			""
		]] remoteExec ["addAction",0,true];


		// _TFOBH = createTrigger ["EmptyDetector", getPos _x];  
		// _TFOBH setTriggerArea [5, 5, 0, false, 7];  
		// _TFOBH setTriggerTimeout [3, 3, 3, true];
		// _TFOBH setTriggerActivation ["NONE", "PRESENT", true];  
		// _TFOBH setTriggerStatements [  
		// "count (nearestobjects [thisTrigger,East_Units_Officers,5]) > 0 ",  
		// "  
		// _HOS = nearestobjects [thisTrigger,East_Units_Officers,10] select 0 ;    
		// deleteVehicle _HOS ; 
		// 	[] execVM 'Scripts\INTL.sqf';	
		// [125] call FLO_fnc_addReward;
		// 	[125, 'ENEMY OFFICER'] call FLO_fnc_notification ;

		// ", ""]; 

		// _TFOBH attachTo [_x, [0, 0, 0]]; 

		// _TFOBH = createTrigger ["EmptyDetector", getPos _x];  
		// _TFOBH setTriggerArea [5, 5, 0, false, 7];  
		// _TFOBH setTriggerTimeout [3, 3, 3, true];
		// _TFOBH setTriggerActivation ["NONE", "PRESENT", true];  
		// _TFOBH setTriggerStatements [  
		// "count (nearestobjects [thisTrigger,East_Units,5]) > 0 ",  
		// "  
		// _HOS = nearestobjects [thisTrigger,East_Units,10] select 0 ;    
		// deleteVehicle _HOS ; 
		// 	[] execVM 'Scripts\INTL.sqf';	
		// [50] call FLO_fnc_addReward;
		// 	[50, 'ENEMY SOLDIER'] call FLO_fnc_notification ;

		// ", ""]; 

		// _TFOBH attachTo [_x, [0, 0, 0]]; 



		_CIVTRG = createTrigger ["EmptyDetector", getPos _x];  
		_CIVTRG setTriggerArea [5, 5, 0, false, 7];  
		_CIVTRG setTriggerTimeout [3, 3, 3, true];
		_CIVTRG setTriggerActivation ["NONE", "PRESENT", true];  
		_CIVTRG setTriggerStatements [  
		"{(alive  _x) && (side _x == civilian)} count (thisTrigger nearEntities [['Man'], 5]) > 0",  
		"
		_CIVIL = (nearestObjects [thisTrigger ,['Man'], 7] select {(alive _x) && ((side _x) == civilian)}) select 0 ;
		
		if ( _CIVIL getUnitTrait 'engineer' == true) then {
			[50, 'INSURGENT'] call FLO_fnc_notification ;
			[50] call FLO_fnc_addReward;
			deleteVehicle _CIVIL ; 
			[] execVM 'Scripts\INTL_Civ.sqf';	
			[] execVM 'Scripts\ReputationPlus.sqf';
		}else{
			[0, 'CIVILIAN'] call FLO_fnc_notification ;
			deleteVehicle _CIVIL ; 
			[] execVM 'Scripts\ReputationMinus.sqf';
		};
		", ""]; 

		_CIVTRG attachTo [_x, [0, 0, 0]]; 



		_TFOBA = createTrigger ["EmptyDetector", getPos _x];  
		_TFOBA setTriggerArea [5, 5, 0, false, 7];  
		_TFOBA setTriggerTimeout [3, 3, 3, true];
		_TFOBA setTriggerActivation ["NONE", "PRESENT", true];  
		_TFOBA setTriggerStatements [  
		"count (nearestobjects [thisTrigger,['CargoNet_01_box_F'],4]) > 0 ",  
		"  
		_RES = nearestobjects [thisTrigger,['CargoNet_01_box_F'],10] select 0 ;    
		deleteVehicle _RES ; 
			[100, 'RESOURCE'] call FLO_fnc_notification ;

		[100, thisTrigger] execVM 'Scripts\Reward_Supplies.sqf';
		", ""]; 

		_TFOBA attachTo [_x, [0, 0, 0]]; 




					_x addEventHandler ["Killed", {
										
						[playerSide, 'HQ'] commandChat 'all Forces Fall Back. We Lost the FOB,...';
						_FOBC = nearestObjects [ (_this select 0), ['B_Slingload_01_Cargo_F'], 1000] select 0;
						_FOBB = nearestObjects [ (_this select 0), [F_HQ_01], 1000] select 0;
						_FOBT = nearestObjects [(_this select 0), [F_HQ_C_01], 1000]  select 0;
						deleteVehicle _FOBC;
						_FOBB setdamage 1;
						deleteVehicle _FOBT;
						
						_allMarks = allMapMarkers select {markerText _x == 'FOB' && markerType _x == 'b_installation'};  
						_FOBMrk = [_allMarks,  (_this select 0)] call BIS_fnc_nearestPosition;
						if (typeName _FOBMrk == "STRING") then {deleteMarker _FOBMrk;} ; 

						[] execVM 'Scripts\Failed.sqf';

						_alltriggers = allMissionObjects "EmptyDetector";
						_triggers = _alltriggers select {position _x distance (_this select 0) < 20};
						{deleteVehicle _x;}forEach _triggers;
										
									}]; 





		// Start holdout monitoring for FOB
		[_x] spawn {
			params ["_fob"];
			private _holdoutTime = 0;
			private _maxHoldTime = 900; // 15 minutes
			private _checkInterval = 1;
			private _areaRadius = 200;
			private _statusMarker = nil;
			
			while {alive _fob} do {
				private _bluforCount = {alive _x && side _x == WEST && (_x distance _fob) < _areaRadius} count allUnits;
				private _opforCount = {alive _x && side _x == EAST && (_x distance _fob) < _areaRadius} count allUnits;

				if (_opforCount > _bluforCount && _opforCount > 0) then {
					if (isNil "_statusMarker") then {
						_statusMarker = createMarker ["FOB_Status", getPos _fob];
						_statusMarker setMarkerType "mil_objective";
						_statusMarker setMarkerColor "ColorRed";
						_statusMarker setMarkerSize [1.5,1.5];
					};
					
					_holdoutTime = _holdoutTime + _checkInterval;
					private _timeLeft = _maxHoldTime - _holdoutTime;
					private _minutes = floor(_timeLeft/60);
					private _seconds = _timeLeft % 60;
					_statusMarker setMarkerText format["FOB UNDER SIEGE: %1:%2", _minutes, [_seconds, 2] call CBA_fnc_formatNumber];
					
					if (_timeLeft % 60 == 0) then {
						[format["FOB under siege! %1 minutes remaining", ceil(_timeLeft/60)]] remoteExec ["hint", -2];
					};
					
					if (_holdoutTime >= _maxHoldTime) exitWith {
						_statusMarker setMarkerText "FOB LOST!";
						_statusMarker setMarkerColor "ColorBlack";
						deleteMarker _statusMarker;
						
						"FOB has fallen to enemy forces!" remoteExec ["hint", -2];
						
						private _FOBC = nearestObjects [_fob, ['B_Slingload_01_Cargo_F'], 1000] param [0, objNull];
						private _FOBT = nearestObjects [_fob, [F_HQ_C_01], 1000] param [0, objNull];
						
						if (!isNull _FOBC) then { deleteVehicle _FOBC };
						if (!isNull _fob) then { _fob setDamage 1 };
						if (!isNull _FOBT) then { deleteVehicle _FOBT };
						
						private _markerName = _fob getVariable "fobMarkerName";
						deleteMarker _markerName;
						
						private _allTriggers = allMissionObjects "EmptyDetector";
						private _triggers = _allTriggers select { position _x distance _fob < 500 };
						{ deleteVehicle _x } forEach _triggers;
						
						// Call failure script
						[] execVM 'Scripts\Failed.sqf';
					};
				} else {
					if (!isNil "_statusMarker") then {
						deleteMarker _statusMarker;
						_statusMarker = nil;
						if (_holdoutTime > 0) then {
							"FOB defense successful! Timer reset." remoteExec ["hint", -2];
						};
					};
					_holdoutTime = 0;
				};
				
				sleep _checkInterval;
			};
			
			if (!isNil "_statusMarker") then {
				deleteMarker _statusMarker;
			};
		};

}
} foreach FOBB;

 ///////////////////////////////////////////////////////
 
_FOBT = nearestObjects [Centerposition, [F_HQ_C_01], 40000];

{

[ _x,
"<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Skip_Time",
"Screens\FOBA\b_hq.paa",
"Screens\FOBA\b_hq.paa",
"((player == TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player == TheCommander) && (isServer)) || ((player == TheCommander) && (isServer))",       
"_caller distance _target < 40",  
{},
{},
{createDialog 'C_LOCK';},
{},
[],
5,
4,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

[ _x,
"<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Change_Weather",
"Screens\FOBA\b_hq.paa",
"Screens\FOBA\b_hq.paa",
"((player == TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player == TheCommander) && (isServer)) || ((player == TheCommander) && (isServer))",       
"_caller distance _target < 40",  
{},
{},
{ { null = execVM "Scripts\Init\init_Weather.sqf" ;} remoteExec ["call", 2];},
{},
[],
5,
4,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

[ _x,
	"<img size=2 color='#FFE496' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#FFE496'>SAVE Mission Progress",
"Screens\FOBA\b_hq.paa",
"Screens\FOBA\b_hq.paa",
"((player == TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player == TheCommander) && (isServer)) || ((player == TheCommander) && (isServer))",       
"_caller distance _target < 40",  
{},
{},
{
	
			remoteExec ["FLO_fnc_MissionSave", 2] ;
	
	},
{},
[],
7,
6,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

[ _x,
	"<img size=2 color='#FFE496' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#FFE496'>RESET Mission Progress",
'Screens\FOBA\b_hq.paa',
'Screens\FOBA\b_hq.paa',
"((player == TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player == TheCommander) && (isServer)) || ((player == TheCommander) && (isServer))",       
'_caller distance _target < 40',  
{},
{},
{{ null = execVM "Scripts\MissionReset.sqf" } remoteExec ["call", 2];},
{},
[],
7,
5,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

[ _x,
	"<img size=2 color='#59ff58' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#59ff58'>Bribe_Militia_(200)",
'Screens\FOBA\b_hq.paa',
'Screens\FOBA\b_hq.paa',
"((player == TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player == TheCommander) && (isServer)) || ((player == TheCommander) && (isServer))",       
'_caller distance _target < 40',  
{},
{},
{[] execVM "Scripts\BRIBE.sqf"; },
{},
[],
5,
3,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

[ _x,
	"<img size=2 color='#FF0000' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#FF0000'>Create Custom Mission",
'Screens\FOBA\b_hq.paa',
'Screens\FOBA\b_hq.paa',
"((player == TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player == TheCommander) && (isServer)) || ((player == TheCommander) && (isServer))",       
'_caller distance _target < 40',  
{},
{},
{ execVM "Scripts\Mission_Select_Action.sqf" ;},
{},
[],
2,
1.5,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

[ _x,
	"<img size=2 color='#FF0000' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#FF0000'>Create Custom Zone",
'Screens\FOBA\b_hq.paa',
'Screens\FOBA\b_hq.paa',
"((player == TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player == TheCommander) && (isServer)) || ((player == TheCommander) && (isServer))",       
'_caller distance _target < 40',  
{},
{},
{ execVM "Scripts\CCO.sqf" ;},
{},
[],
2,
1.5,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   
 
 } foreach _FOBT;
 

[[west,"HQ"], "F.O.Bs Initialized Successfully ..."] remoteExec ["sideChat", 0];
 
///////// Init OPs //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



_FOBB = nearestObjects [Centerposition, [F_OP_01], 40000];

{ if (count (nearestObjects [ _x, [F_OP_C_01], 6]) > 0) then {  
	
// Create marker and set variable
_relpos = _x getRelPos [12, 0];
_markerName = "respawn_west" + (str (getPos _x));  
_mrkr = createMarker [_markerName, _relpos];  
_mrkr setMarkerType "b_installation";
_mrkr setMarkerColor "ColorYellow";
_mrkr setMarkerText "OP";
_mrkr setMarkerSize [1.5, 1.5];
_x setVariable ["opMarkerName", _markerName, true];  // Set on OP object   

{ nul = [_x, -1, west, "LIGHT"] execVM "R3F_LOG\USER_FUNCT\init_creation_factory.sqf"; } remoteExec ["call", 0, true];

[ _x,
"<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
"Screens\FOBA\mg_ca.paa",
"Screens\FOBA\mg_ca.paa",
	"_this distance _target < 10",			
	"_caller distance _target < 10",	
{},
{},
{
	
	if (isClass (configfile >> "ace_arsenal_loadoutsDisplay") == true ) then {
		[player, player, true] call ace_arsenal_fnc_openBox;
	} else {
		["Open", true] spawn BIS_fnc_arsenal;
	};
},
{},
[],
1,
1,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   



[ _x,
"<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Pack OP",
"Screens\FOBA\b_hq.paa",
"Screens\FOBA\b_hq.paa",
"true",       
"_caller distance _target < 40",  
{},
{},
{execVM 'Scripts\OPPACK.sqf';},
{},
[],
5,
2,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   


[_x,[
	"<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>REQUEST MENU",
	"Scripts\RequestMenu\Dialog_Request_OP.sqf",
	nil,
	99999,
	true,
	true,
	"",
	"", // _target, _this, _originalTarget
	40,
	false,
	"",
	""
]] remoteExec ["addAction",0,true];




// _TFOBH = createTrigger ["EmptyDetector", getPos _x];  
// _TFOBH setTriggerArea [5, 5, 0, false, 7];  
// _TFOBH setTriggerTimeout [3, 3, 3, true];
// _TFOBH setTriggerActivation ["NONE", "PRESENT", true];  
// _TFOBH setTriggerStatements [  
// "count (nearestobjects [thisTrigger,East_Units_Officers,3]) > 0 ",  
// "  
// _HOS = nearestobjects [thisTrigger,East_Units_Officers,10] select 0 ;    
// deleteVehicle _HOS ; 
// [125] call FLO_fnc_addReward;
// [] execVM 'Scripts\INTL.sqf';
// 	[125, 'ENEMY OFFICER'] call FLO_fnc_notification ;

//  ", ""]; 

// _TFOBH attachTo [_x, [0, 0, 0]]; 

// _TFOBH = createTrigger ["EmptyDetector", getPos _x];  
// _TFOBH setTriggerArea [5, 5, 0, false, 7];  
// _TFOBH setTriggerTimeout [3, 3, 3, true];
// _TFOBH setTriggerActivation ["NONE", "PRESENT", true];  
// _TFOBH setTriggerStatements [  
// "count (nearestobjects [thisTrigger,East_Units,3]) > 0 ",  
// "  
// _HOS = nearestobjects [thisTrigger,East_Units,10] select 0 ;    
// deleteVehicle _HOS ; 

// [50] call FLO_fnc_addReward;
// [] execVM 'Scripts\INTL.sqf';
// 	[50, 'ENEMY SOLDIER'] call FLO_fnc_notification ;

//  ", ""]; 

// _TFOBH attachTo [_x, [0, 0, 0]]; 


_CIVTRG = createTrigger ["EmptyDetector", getPos _x];  
_CIVTRG setTriggerArea [5, 5, 0, false, 7];  
_CIVTRG setTriggerTimeout [3, 3, 3, true];
_CIVTRG setTriggerActivation ["NONE", "PRESENT", true];  
_CIVTRG setTriggerStatements [  
"{(alive  _x) && (side _x == civilian)} count (thisTrigger nearEntities [['Man'], 5]) > 0",  
"
_CIVIL = (nearestObjects [thisTrigger ,['Man'], 7] select {(alive _x) && ((side _x) == civilian)}) select 0 ;
  
if ( _CIVIL getUnitTrait 'engineer' == true) then {
	[50, 'INSURGENT'] call FLO_fnc_notification ;
	[50] call FLO_fnc_addReward;
	deleteVehicle _CIVIL ; 
	[] execVM 'Scripts\INTL_Civ.sqf';	
	[] execVM 'Scripts\ReputationPlus.sqf';
}else{
	[0, 'CIVILIAN'] call FLO_fnc_notification ;
	deleteVehicle _CIVIL ; 
	[] execVM 'Scripts\ReputationMinus.sqf';
};
 ", ""]; 

_CIVTRG attachTo [_x, [0, 0, 0]]; 


_TFOBA = createTrigger ["EmptyDetector", getPos _x];  
_TFOBA setTriggerArea [3, 3, 0, false, 7];  
_TFOBA setTriggerTimeout [3, 3, 3, true];
_TFOBA setTriggerActivation ["NONE", "PRESENT", true];  
_TFOBA setTriggerStatements [  
"count (nearestobjects [thisTrigger,['CargoNet_01_box_F'],3]) > 0 ",  
"  
_RES = nearestobjects [thisTrigger,['CargoNet_01_box_F'],10] select 0 ;    
deleteVehicle _RES ; 
	[100, 'RESOURCE'] call FLO_fnc_notification ;

[100, thisTrigger] execVM 'Scripts\Reward_Supplies.sqf';
 ", ""]; 

_TFOBA attachTo [_x, [0, 0, 0]]; 




			_x addEventHandler ["Killed", {
								
					[playerSide, 'HQ'] commandChat 'all Forces Fall Back. We Lost the OP,...';
					_FOBC = nearestObjects [ (_this select 0), ['B_Slingload_01_Cargo_F'], 1000] select 0;
					_FOBB = nearestObjects [ (_this select 0), [F_OP_01], 1000] select 0;
					_FOBT = nearestObjects [(_this select 0), [F_OP_C_01], 1000]  select 0;
					deleteVehicle _FOBC;
					_FOBB setdamage 1;
					deleteVehicle _FOBT;
				_allMarks = allMapMarkers select {markerText _x == 'OP' && markerType _x == 'b_installation'};  
				_FOBMrk = [_allMarks,  (_this select 0)] call BIS_fnc_nearestPosition;
				deleteMarker _FOBMrk ; 


					_alltriggers = allMissionObjects "EmptyDetector";
					_triggers = _alltriggers select {position _x distance (_this select 0) < 20};
					{deleteVehicle _x;}forEach _triggers;
							}]; 







		// Modified holdout monitoring for OP
		[_x] spawn {
			params ["_op"];
			private _holdoutTime = 0;
			private _maxHoldTime = 600; // 10 minutes
			private _checkInterval = 1;
			private _areaRadius = 100;
			private _statusMarker = nil;
			
			while {alive _op} do {
				private _bluforCount = {alive _x && side _x == WEST && (_x distance _op) < _areaRadius} count allUnits;
				private _opforCount = {alive _x && side _x == EAST && (_x distance _op) < _areaRadius} count allUnits;


				if (_opforCount > _bluforCount && _opforCount > 0) then {
					if (isNil "_statusMarker") then {
						_statusMarker = createMarker ["OP_Status", getPos _op];
						_statusMarker setMarkerType "mil_objective";
						_statusMarker setMarkerColor "ColorRed";
						_statusMarker setMarkerSize [1.2,1.2];
					};
					
					_holdoutTime = _holdoutTime + _checkInterval;
					private _timeLeft = _maxHoldTime - _holdoutTime;
					private _minutes = floor(_timeLeft/60);
					private _seconds = _timeLeft % 60;
					_statusMarker setMarkerText format["OP UNDER SIEGE: %1:%2", _minutes, [_seconds, 2] call CBA_fnc_formatNumber];
					
					if (_timeLeft % 60 == 0) then {
						[format["OP under siege! %1 minutes remaining", ceil(_timeLeft/60)]] remoteExec ["hint", -2];
					};
					
					if (_holdoutTime >= _maxHoldTime) exitWith {
						_statusMarker setMarkerText "OP LOST!";
						_statusMarker setMarkerColor "ColorBlack";
						deleteMarker _statusMarker;
						
						"OP has fallen to enemy forces!" remoteExec ["hint", -2];
						
						// Execute OP destruction sequence
						private _OPC = nearestObjects [_op, ['B_Slingload_01_Cargo_F'], 1000] param [0, objNull];
						private _OPT = nearestObjects [_op, [F_OP_C_01], 1000] param [0, objNull];
						
						if (!isNull _OPC) then { deleteVehicle _OPC };
						if (!isNull _op) then { _op setDamage 1 };
						if (!isNull _OPT) then { deleteVehicle _OPT };
						
						// Delete OP marker
						private _markerName = _op getVariable "opMarkerName";
						deleteMarker _markerName;
						
						// Cleanup triggers
						private _allTriggers = allMissionObjects "EmptyDetector";
						private _triggers = _allTriggers select { position _x distance FOBB < 300 };
						{ deleteVehicle _x } forEach _triggers;
					};
				} else {
					if (!isNil "_statusMarker") then {
						deleteMarker _statusMarker;
						_statusMarker = nil;
						if (_holdoutTime > 0) then {
							"OP defense successful! Timer reset." remoteExec ["hint", -2];
						};
					};
					_holdoutTime = 0;
				};
				
				sleep _checkInterval;
			};
			
			if (!isNil "_statusMarker") then {
				deleteMarker _statusMarker;
			};
		};

[playerSide, "HQ"] commandChat "OP Deployed";
 }
 } foreach _FOBB;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 _FOBC = nearestObjects [Centerposition, ["B_Slingload_01_Cargo_F"], 40000];
{
[_x,[
	"<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack FOB",
	"Scripts\FOBUNPACK.sqf",
	nil,
	0,
	true,
	true,
	"",
	"true", // _target, _this, _originalTarget
	40,
	false,
	"",
	""
]] remoteExec ["addAction",0,true];	
 } foreach _FOBC;
 
  _FOBC = nearestObjects [Centerposition, ["B_Slingload_01_Repair_F"], 40000];
{
[_x,[
	"<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack OP",
	"Scripts\OPUNPACK.sqf",
	nil,
	0,
	true,
	true,
	"",
	"true", // _target, _this, _originalTarget
	40,
	false,
	"",
	""
]] remoteExec ["addAction",0,true];
 } foreach _FOBC;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////// Vehicles Crew Management /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


ALLFACVEHs = nearestobjects [Centerposition,[
"B_SAM_System_01_F",
"B_AAA_System_01_F",
"B_SAM_System_02_F",
"B_SAM_System_03_F",
"B_GMG_01_A_F",
"B_HMG_01_A_F",
"B_W_Static_Designator_01_F",
"B_UGV_02_Demining_F",
"B_UAV_02_lxWS",
"B_UAV_01_F",
"B_SDV_01_F",
"USAF_A10",
"USAF_F22",
"USAF_F22_Heavy",
"USAF_F35A_STEALTH",
"USAF_F35A",
"USAF_AC130U",
"USAF_C130J",
"USAF_C130J_Cargo",
"usaf_kc135",
"USAF_C17",
F_RADAR,
F_ABT_01,
F_UAV_01,
F_UAV_02,
F_UAV_03,
F_UGV_01,
F_turret_01,
F_turret_02,
F_turret_03,
F_Car_01,
F_Car_02,
F_Car_03,
F_Car_04,
F_Car_05,
F_Car_06,
F_MRAP_01,
F_MRAP_02,
F_MRAP_03,
F_MRAP_04,
F_MRAP_05,
F_MRAP_06,
F_Truck_01,
F_Truck_02,
F_Truck_03,
F_Truck_04,
F_Truck_05,
F_Truck_06,
F_APC_01,
F_APC_02,
F_APC_03,
F_APC_04,
F_APC_05,
F_APC_06,
F_TNK_01,
F_TNK_02,
F_TNK_03,
F_TNK_04,
F_Art_00,
F_Art_01,
F_Art_02,
F_Heli_01,
F_Heli_02,
F_Heli_03,
F_Heli_04,
F_Heli_05,
F_Heli_06_G,
F_Heli_07_G,
F_Plane_01_CAS,
F_Plane_02_CAS,
F_Plane_03,
F_Plane_04,
F_Plane_05,
F_Plane_06
],40000] ;

_EXCVEH = vehicles;

{
	deleteVehicleCrew _x; 
} foreach _EXCVEH;  
	

////////////////Radio Towers EHs/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_objectLocT = allMapMarkers select { markerType _x == "loc_Transmitter" };
	{
		
TWRs = nearestobjects [(getMarkerPos _x), ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"], 200];

		if (count TWRs > 0 ) then {
			TWR = TWRs select 0 ;

				TWR removeAllEventHandlers "Killed";
				TWR addEventHandler ["Killed", { 
				_MMarks = allMapMarkers select { markerType _x == "loc_Transmitter"};
				_M = [_MMarks, (_this select 0)] call BIS_fnc_nearestPosition;
				deleteMarker _M ; 
				  
								[] execVM "Scripts\DangerMinus.sqf";					
								[] execVM "Scripts\DangerMinus.sqf";					
								[] execVM "Scripts\DangerMinus.sqf";					
				[] execVM "Scripts\ReputationMinus.sqf";
				[] execVM "Scripts\ReputationMinus.sqf";

				  
				[30, "RADIO TOWER"] call FLO_fnc_notification ;

				[30] call FLO_fnc_addReward;
				 execVM "Scripts\COMDIS.sqf";
				}];
		};
			
    } forEach _objectLocT;	

//////////////Zones Capture Triggers ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


_objectLocT = allMapMarkers select { markerType _x == "b_installation" && markerColor _x == "ColorWEST"};

	{
		
_trg = createTrigger ["EmptyDetector", (getMarkerPos _x), false];  
_trg setTriggerArea [220, 220, 0, false, 200];  
_trg setTriggerTimeout [10, 10, 10, true];
_trg setTriggerActivation ["EAST SEIZED", "PRESENT", true];  
_trg setTriggerStatements [  
"this",  "  

				[parseText '<t color=""#FF3619"" font=""PuristaBold"" align = ""right"" shadow = ""1"" size=""2"">SITREP</t><br /><t color=""#7c7c7c""  align = ""right"" shadow = ""1"" size=""0.8"">Enemy Forces Dominating the Battle,</t><br /><t color=""#7c7c7c"" align = ""right"" shadow = ""1"" size=""0.8"">Keep Up the Fight, We Must Defend and Take Back the Outpost, </t>', [0, 0.5, 1, 1], nil, 5, 1.7, 0] remoteExec ['BIS_fnc_textTiles', 0];
				_allMarks = allMapMarkers select {markerType _x == 'b_installation'};  
				_FOBMrk = [_allMarks,  thisTrigger] call BIS_fnc_nearestPosition;
				_FOBMrk setMarkerColor 'ColorGrey' ;	
				_attackingAtGrid = mapGridPosition getMarkerPos _FOBMrk;
				[[west,'HQ'], 'Enemy Forces Dominating the Battle at grid ' + _attackingAtGrid] remoteExec ['sideChat', 0];					
				
				[thisTrigger] execVM 'Scripts\City_CSAT_CAPTURE_East.sqf';

", "

				_allMarks = allMapMarkers select {markerType _x == 'b_installation'};  
				_FOBMrk = [_allMarks,  thisTrigger] call BIS_fnc_nearestPosition;
				_FOBMrk setMarkerColor 'ColorWEST' ;		

"];				

    } forEach _objectLocT;	

_objectLocT = allMapMarkers select { markerType _x == "b_installation" && markerColor _x == "colorBLUFOR"};

	{

_trg = createTrigger ["EmptyDetector", (getMarkerPos _x), false];  
_trg setTriggerArea [120, 120, 0, false, 200];  
_trg setTriggerTimeout [10, 10, 10, true];
_trg setTriggerActivation ["EAST SEIZED", "PRESENT", true];  
_trg setTriggerStatements [  
"this",  "  

				[parseText '<t color=""#FF3619"" font=""PuristaBold"" align = ""right"" shadow = ""1"" size=""2"">SITREP</t><br /><t color=""#7c7c7c""  align = ""right"" shadow = ""1"" size=""0.8"">Enemy Forces Dominating the Battle,</t><br /><t color=""#7c7c7c"" align = ""right"" shadow = ""1"" size=""0.8"">Keep Up the Fight, We Must Defend and Take Back the Outpost, </t>', [0, 0.5, 1, 1], nil, 5, 1.7, 0] remoteExec ['BIS_fnc_textTiles', 0];
				_allMarks = allMapMarkers select {markerType _x == 'b_installation'};  
				_FOBMrk = [_allMarks,  thisTrigger] call BIS_fnc_nearestPosition;
				_FOBMrk setMarkerColor 'ColorGrey' ;	
				_attackingAtGrid = mapGridPosition getMarkerPos _FOBMrk;
				[[west,'HQ'], 'Enemy Forces Dominating the Battle at grid ' + _attackingAtGrid] remoteExec ['sideChat', 0];					
				
				[thisTrigger] execVM 'Scripts\Objectives\Outpost_CSAT_CAPTURE_East.sqf';

", "

				_allMarks = allMapMarkers select {markerType _x == 'b_installation'};  
				_FOBMrk = [_allMarks,  thisTrigger] call BIS_fnc_nearestPosition;
				_FOBMrk setMarkerColor 'colorBLUFOR' ;		

"];				

    } forEach _objectLocT;	
	
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////Support Stations/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

[] spawn {  
  while { true } do{  
{
 _x setDamage 0;  
 
  [true] remoteExec ["showHud", _x]; 
 
  _x stop false; 
 _x enableAI "all";    

 [_x, false] remoteExec ["setCaptive", 0, false]; 
  
 ["GetOutMan"] remoteExec ["removeAllEventHandlers", _x, false];
 
	[_x, _x] remoteExec ["ace_medical_treatment_fnc_fullHeal", _x, false]; 
	
		if ( animationState _x == "ainjppnemstpsnonwrfldnon" ) then {  [_x, "agonyStop"] remoteExec ["playActionNow", 0, false]; };
	if ( animationState _x == "unconscious" ) then {  [_x, "agonyStop"] remoteExec ["playActionNow", 0, false]; };
		_x enableAI "all";    
	
  } forEach (allUnits select {((side _x == civilian) || (side _x == west)) && (count ( nearestobjects [_x ,["Land_Medevac_house_V1_F", "Land_Medevac_HQ_V1_F", "B_Slingload_01_Medevac_F", "Land_MedicalTent_01_MTP_closed_F", "Land_MedicalTent_01_white_IDAP_med_closed_F"],20]) > 0)}) ; 
 
 sleep 3;  
 
	  {
	if ( animationState _x == "ainjppnemstpsnonwrfldnon" ) then {  [_x, "agonyStop"] remoteExec ["playActionNow", 0, false]; };
	if ( animationState _x == "unconscious" ) then {  [_x, "agonyStop"] remoteExec ["playActionNow", 0, false]; };
		_x enableAI "all";    
  } forEach (allUnits select {((side _x == civilian) || (side _x == west)) && (count ( nearestobjects [_x ,["Land_Medevac_house_V1_F", "Land_Medevac_HQ_V1_F", "B_Slingload_01_Medevac_F", "Land_MedicalTent_01_MTP_closed_F", "Land_MedicalTent_01_white_IDAP_med_closed_F"],20]) > 0)}) ; 


 sleep 30;  
  };  
};



[] spawn {  
  while { true } do{  
{
  {_x setDamage 0; } remoteExec ["call", 0]; 
 	
	} forEach (vehicles select {((side (gunner  _x) == west) or (side (driver  _x) == west)) && (count ( nearestobjects [_x ,[F_Truck_04, "B_Slingload_01_Repair_F"],50]) > 0)}) ; 

 sleep 30;  
  };  
};



[] spawn {  
  while { true } do{  
{
	{ _x setVehicleAmmo 1;  } remoteExec ["call", 0]; 
 	
	} forEach (vehicles select {((side (gunner  _x) == west) or (side (driver  _x) == west)) && (count ( nearestobjects [_x ,[F_Truck_03, "B_Slingload_01_Ammo_F", "Box_NATO_AmmoVeh_F"],50]) > 0)}) ; 

 sleep 30;  
  };  
};



[] spawn {  
  while { true } do{  
_MOBRESMarks = allMapMarkers select {markerType _x == "b_unknown" && markerColor _x == "ColorYellow" && markerAlpha _x == 0.7};
	{deleteMarker _x} forEach _MOBRESMarks ;
_MOBRESVeh = vehicles select {(typeOf _x == F_Truck_05 or typeOf _x == F_Heli_04) && alive _x } ;	
{
_markerName = "respawn_west" + (str (getPos _x));  
_mrkr = createMarkerLocal [_markerName, getPos _x];  
_mrkr setMarkerTypeLocal "b_unknown";
_mrkr setMarkerColorLocal "ColorYellow";
_mrkr setMarkerSizeLocal [1, 1]; 
_mrkr setMarkerAlpha 0.7; 
} foreach _MOBRESVeh;

 sleep 5;  
  };  
};


{ 
	_MOBSER = nearestobjects [Centerposition,[F_Truck_04],40000] ;
	{
		[_x, -1, west, "LIGHT"] execVM "R3F_LOG\USER_FUNCT\init_creation_factory.sqf";
	} forEach _MOBSER; 
} remoteExec ["call", 0, true];

_MOBARS = nearestobjects [Centerposition,[F_Truck_03],40000] ;
{

[ _x,
"<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
"Screens\FOBA\mg_ca.paa",
"Screens\FOBA\mg_ca.paa",
	"_this distance _target < 10",			
	"_caller distance _target < 10",	
{},
{},
{
	
	if (isClass (configfile >> "ace_arsenal_loadoutsDisplay") == true ) then {
		[player, player, true] call ace_arsenal_fnc_openBox;
	} else {
		["Open", true] spawn BIS_fnc_arsenal;
	};
},
{},
[],
1,
1,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

[ _x,
"<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>REARM Infantry",
"Screens\FOBA\mg_ca.paa",
"Screens\FOBA\mg_ca.paa",
	"_this distance _target < 10",			
	"_caller distance _target < 10",	
{},
{},
{
[(_this select 0)] execVM "Scripts\REARM.sqf" ;
},
{},
[],
5,
1,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

} forEach _MOBARS ;

_SUPPARS = nearestobjects [Centerposition,["B_CargoNet_01_ammo_F"],40000] ;
{

[ _x,
"<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
"Screens\FOBA\mg_ca.paa",
"Screens\FOBA\mg_ca.paa",
	"_this distance _target < 10",			
	"_caller distance _target < 10",	
{},
{},
{
	
	if (isClass (configfile >> "ace_arsenal_loadoutsDisplay") == true ) then {
		[player, player, true] call ace_arsenal_fnc_openBox;
	} else {
		["Open", true] spawn BIS_fnc_arsenal;
	};
},
{},
[],
1,
1,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

[ _x,
"<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>REARM Infantry",
"Screens\FOBA\mg_ca.paa",
"Screens\FOBA\mg_ca.paa",
	"_this distance _target < 10",			
	"_caller distance _target < 10",	
{},
{},
{
[(_this select 0)] execVM "Scripts\REARM.sqf" ;
},
{},
[],
5,
1,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

} forEach _SUPPARS ;

_SUPPVEH = nearestobjects [Centerposition,["Box_NATO_AmmoVeh_F"],40000] ;
{

[ _x,
"<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>REARM Vehicles",
"Screens\FOBA\mg_ca.paa",
"Screens\FOBA\mg_ca.paa",
	"_this distance _target < 10",			
	"_caller distance _target < 10",	
{},
{},
{
[(_this select 0)] execVM "Scripts\REARMVEH.sqf" ;
},
{},
[],
10,
1,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

} forEach _SUPPVEH ;

[[west,"HQ"], "Support Stations Initialized Successfully ..."] remoteExec ["sideChat", 0];

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_VEHs = nearestobjects [Centerposition,[
F_Heli_01,
F_Heli_02,
F_Heli_03,
F_Heli_04,
F_Heli_05
],40000] ;

{(group (driver _x)) setVariable ["Vcm_Disable",true]; } forEach _VEHs ; 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_objectLoc = nearestobjects [Centerposition, ["rhsusf_stryker_m1126_m2_d", "rhsusf_stryker_m1126_mk19_d", "rhsusf_stryker_m1134_d"], 40000]; 
{[_x,["Tan",1]] call BIS_fnc_initVehicle;} forEach _objectLoc;

_TVC = nearestobjects [Centerposition, ["rhsusf_mrzr4_d"], 40000]; 
if (((markerText "Friendly_Handle" == "United States Armed Forces _ Woodland _ CUP + RHS") or (markerText "Friendly_Handle" == "United States Armed Forces _ Woodland _ RHS")) && (count _TVC > 0)) then {[_x,["mud_olive",1]] call BIS_fnc_initVehicle;} forEach _TVC;
 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

{ _LOG = nearestObjects [Centerposition, ["Sign_Pointer_Blue_F" , "Land_InvisibleBarrier_F", "LocationCityCapital_F", "LocationCity_F", "Sign_Pointer_Blue_F" ], 40000]; {deleteVehicle _x} forEach _LOG ; } remoteExec ["call", 0];

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


  _AAAs = nearestObjects [Centerposition, ["O_Radar_System_02_F","O_SAM_System_04_F","vn_o_nva_navy_static_v11m", "vn_o_pl_static_zpu4"], 40000];
  {createVehicleCrew _x; } forEach _AAAs ; 

{
	
	_x setUnitTrait ["explosiveSpecialist", true];
_x setVariable ["ACE_isEOD", true];
} forEach (allUnits select { (side _x == west) && ((typeOf _x == F_Assault_Eod)  || (typeOf _x == F_Recon_Eod) || (typeOf _x == "B_CTRG_soldier_engineer_exp_F") || (typeOf _x == "B_G_Soldier_exp_F"))} ) ;

 { {
[_x,'MENU_COMMS_UAV_RECON',nil,nil,''] call BIS_fnc_addCommMenuItem;	
[_x,'MENU_COMMS_SUPPLYDROP',nil,nil,''] call BIS_fnc_addCommMenuItem;
[_x,'MENU_COMMS_INF',nil,nil,''] call BIS_fnc_addCommMenuItem;	
[_x,'MENU_COMMS_GRD',nil,nil,''] call BIS_fnc_addCommMenuItem;	
[_x,'MENU_COMMS_CAS_HELI',nil,nil,''] call BIS_fnc_addCommMenuItem;	
[_x,'MENU_COMMS_ARTI',nil,nil,''] call BIS_fnc_addCommMenuItem;	

} forEach (allUnits select {side _x == west}) ;  } remoteExec ["call", 0];

	//{[_x] execVM "Scripts\LDTInit.sqf" ;} forEach (allUnits select {side _x == west}) ; 

[[west,"HQ"], "Mission StartUp Initialized Successfully ..."] remoteExec ["sideChat", 0];