/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
FOBB = nearestObjects [position player, [F_HQ_01], 150] select 0;
publicVariable "FOBB";

if (!isNil "FOBB") then {
    [FOBB] call FLO_fnc_initializeFOB;
} else {
    ["FOB", 1, "Error: FOBB object not defined for creation factory setup"] call FLO_fnc_log;
};


_FOBT = nearestObjects [position player, [F_HQ_C_01], 150] select 0;

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

[playerSide, "HQ"] commandChat "FOB Deployed!";