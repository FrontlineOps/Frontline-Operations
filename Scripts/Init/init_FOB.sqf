
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
FOBB = nearestObjects [position player, [F_HQ_01], 150] select 0;
publicVariable "FOBB";

{ null = [FOBB, -1, west, "LIGHT"] execVM "R3F_LOG\USER_FUNCT\init_creation_factory.sqf" } remoteExec ["call", 0]; 


[ FOBB,
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


[ FOBB,
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

[FOBB,[
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


_TFOBH = createTrigger ["EmptyDetector", getPos FOBB];  
_TFOBH setTriggerArea [5, 5, 0, false, 7];  
_TFOBH setTriggerTimeout [3, 3, 3, true];
_TFOBH setTriggerActivation ["NONE", "PRESENT", true];  
_TFOBH setTriggerStatements [  
"count (nearestobjects [thisTrigger,East_Units_Officers,5]) > 0 ",  
"  
_HOS = nearestobjects [thisTrigger,East_Units_Officers,10] select 0 ;    
deleteVehicle _HOS ; 
	[] execVM 'Scripts\INTL.sqf';
	[125, 'ENEMY OFFICER'] call FLO_fnc_notification ;
[125] call FLO_fnc_addReward;

 ", ""]; 

_TFOBH attachTo [FOBB, [0, 0, 0]]; 

_TFOBH = createTrigger ["EmptyDetector", getPos FOBB];  
_TFOBH setTriggerArea [5, 5, 0, false, 7];  
_TFOBH setTriggerTimeout [3, 3, 3, true];
_TFOBH setTriggerActivation ["NONE", "PRESENT", true];  
_TFOBH setTriggerStatements [  
"count (nearestobjects [thisTrigger,East_Units,5]) > 0 ",  
"  
_HOS = nearestobjects [thisTrigger,East_Units,10] select 0 ;    
deleteVehicle _HOS ; 
[25] call FLO_fnc_addReward;
[] execVM 'Scripts\INTL.sqf';
	[25, 'ENEMY SOLDIER'] call FLO_fnc_notification ;

 ", ""]; 

_TFOBH attachTo [FOBB, [0, 0, 0]]; 


_CIVTRG = createTrigger ["EmptyDetector", getPos FOBB];  
_CIVTRG setTriggerArea [5, 5, 0, false, 7];  
_CIVTRG setTriggerTimeout [3, 3, 3, true];
_CIVTRG setTriggerActivation ["NONE", "PRESENT", true];  
_CIVTRG setTriggerStatements [  
"{(alive  _x) && (side _x == civilian)} count (thisTrigger nearEntities [['Man'], 5]) > 0",  
"
_CIVIL = (nearestObjects [thisTrigger ,['Man'], 7] select {(alive _x) && ((side _x) == civilian)}) select 0 ;
  
if ( _CIVIL getUnitTrait 'engineer' == true) then {
	[15, 'INSURGENT'] call FLO_fnc_notification ;
	[15] call FLO_fnc_addReward;

	deleteVehicle _CIVIL ; 
	[] execVM 'Scripts\INTL_Civ.sqf';	
	[] execVM 'Scripts\ReputationPlus.sqf';
}else{
	[0, 'CIVILIAN'] call FLO_fnc_notification ;
	deleteVehicle _CIVIL ; 
	[] execVM 'Scripts\ReputationMinus.sqf';
};
 ", ""]; 

_CIVTRG attachTo [FOBB, [0, 0, 0]]; 



_TFOBA = createTrigger ["EmptyDetector", getPos FOBB];  
_TFOBA setTriggerArea [5, 5, 0, false, 7];  
_TFOBA setTriggerTimeout [3, 3, 3, true];
_TFOBA setTriggerActivation ["NONE", "PRESENT", true];  
_TFOBA setTriggerStatements [  
"count (nearestobjects [thisTrigger,['CargoNet_01_box_F'],4]) > 0 ",  
"  
_RES = nearestobjects [thisTrigger,['CargoNet_01_box_F'],10] select 0 ;    
deleteVehicle _RES ; 
	[60, 'RESOURCE'] call FLO_fnc_notification ;
[60] call FLO_fnc_addReward;

 ", ""]; 

_TFOBA attachTo [FOBB, [0, 0, 0]]; 


			FOBB addEventHandler ["Killed", {
								
				[playerSide, 'HQ'] commandChat 'all Forces Fall Back. We Lost the FOB,...';
				_FOBC = nearestObjects [ (_this select 0), ['B_Slingload_01_Cargo_F'], 1000] select 0;
				_FOBB = nearestObjects [ (_this select 0), [F_HQ_01], 1000] select 0;
				_FOBT = nearestObjects [(_this select 0), [F_HQ_C_01], 1000]  select 0;
				deleteVehicle _FOBC;
				_FOBB setdamage 1;
				deleteVehicle _FOBT;
			
			private _markerName = _this select 0 getVariable "fobMarkerName";
			deleteMarker _markerName;
			
			

				[] execVM 'Scripts\Failed.sqf';

				_alltriggers = allMissionObjects "EmptyDetector";
				_triggers = _alltriggers select {position _x distance (_this select 0) < 20};
				{deleteVehicle _x;}forEach _triggers;
								
							}]; 

// Start holdout monitoring for FOB
[] spawn {
    private _holdoutTime = 0;
    private _maxHoldTime = 900; // 15 minutes for FOB
    private _checkInterval = 1;
    private _areaRadius = 200;
    private _statusMarker = nil;
    
    while {alive FOBB} do {
        private _bluforCount = {alive _x && side _x == WEST && (_x distance FOBB) < _areaRadius} count allUnits;
        private _opforCount = {alive _x && side _x == EAST && (_x distance FOBB) < _areaRadius} count allUnits;

        if (_opforCount > _bluforCount && _opforCount > 0) then {
            if (isNil "_statusMarker") then {
                _statusMarker = createMarker ["FOB_Status", getPos FOBB];
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
                
                private _FOBC = nearestObjects [FOBB, ['B_Slingload_01_Cargo_F'], 1000] param [0, objNull];
                private _FOBT = nearestObjects [FOBB, [F_HQ_C_01], 1000] param [0, objNull];
                
                if (!isNull _FOBC) then { deleteVehicle _FOBC };
                if (!isNull FOBB) then { FOBB setDamage 1 };
                if (!isNull _FOBT) then { deleteVehicle _FOBT };
                
                private _markerName = FOBB getVariable "fobMarkerName";
                deleteMarker _markerName;
                
                private _allTriggers = allMissionObjects "EmptyDetector";
                private _triggers = _allTriggers select { position _x distance FOBB < 500 };
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

[playerSide, "HQ"] commandChat "FOB Deployed";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
_FOBT = nearestObjects [position player, [F_HQ_C_01], 150] select 0;

_relpos = _FOBT getRelPos [12, 0];
_markerName = "respawn_west" + (str (position _FOBT));  
_mrkr = createMarker [_markerName, _relpos];  
_mrkr setMarkerType "b_installation";
_mrkr setMarkerColor "ColorYellow";
_mrkr setMarkerText "FOB";
_mrkr setMarkerSize [2, 2]; 
FOBB setVariable ["fobMarkerName", _markerName, true]; // Store marker name on FOB object


[ _FOBT,
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

[ _FOBT,
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

[ _FOBT,
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

[ _FOBT,
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

[ _FOBT,
	"<img size=2 color='#59ff58' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#59ff58'>Bribe_Militia_(200)",
'Screens\FOBA\b_hq.paa',
'Screens\FOBA\b_hq.paa',
"((player == TheCommander) && (serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')) || ((player == TheCommander) && (isServer)) || ((player == TheCommander) && (isServer))",       
'_caller distance _target < 40',  
{},
{},
{[] execVM "Scripts\BRIBE.sqf";},
{},
[],
7,
3,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   


[ _FOBT,
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

[ _FOBT,
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