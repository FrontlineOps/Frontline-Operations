


hint "";
titleText ["Loading . . .", "BLACK IN",9999];


for "_i" from count waypoints (group player) - 1 to 0 step -1 do
{deleteWaypoint [(group player), _i];};

	
openMap [true, false]; 
openMap [false, false]; 

ShowHUD [true, true, true, true, true, true, true, true, true, true];
{_x enableAI "RADIOPROTOCOL"} foreach Units Group player;

removeAllActions player;

if ((typeOf player == F_Diver_Eod) || (typeOf player == F_Diver_Rfl) || (typeOf player == F_Diver_TL) || (typeOf player == "B_T_Diver_F")) then {
[player] call EtV_Actions;
};

if ((typeOf player == F_Assault_Eod)  || (typeOf player == F_Recon_Eod) || (typeOf player == "B_CTRG_soldier_engineer_exp_F") || (typeOf player == "B_G_Soldier_exp_F")) then {
	player setUnitTrait ["explosiveSpecialist", true];
player setVariable ["ACE_isEOD", true];
};

if ((typeOf player == F_Assault_Eng)  || (typeOf player == "B_G_engineer_F")  || (typeOf player == F_Recon_Eng)) then {
	player setUnitTrait ["engineer", true];
player setVariable ["ACE_isEngineer", true];
// [player,[
// 	"<img size=2 color='#f37c00' image='\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\repair_ca.paa'/><t font='PuristaBold' color='#f37c00'>REPAIR Vehicles",
// {
// (_this select 0) playMove "AinvPknlMstpSnonWnonDnon_medic_1" ; 
// [(_this select 0)] execVM "Scripts\REPAIRVEH.sqf" ;
// },
// 	nil,
// 	9999,
// 	true,
// 	true,
// 	"",
// 	"_this distance _target < 5", // _target, _this, _originalTarget
// 	5,
// 	false,
// 	"",
// 	""
// ]] remoteExec ["addAction",0,true];
};

// if ((typeOf player == F_Assault_Amm)  || (typeOf player == "B_G_Soldier_A_F")) then {
// [player,[
// 	"<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>REARM Infantry",
// {
// (_this select 0) playMove "AinvPknlMstpSnonWnonDnon_medic_1" ; 
// [(_this select 0)] execVM "Scripts\REARM.sqf" ;
// },
// 	nil,
// 	9999,
// 	true,
// 	true,
// 	"",
// 	"_this distance _target < 5", // _target, _this, _originalTarget
// 	5,
// 	false,
// 	"",
// 	""
// ]] remoteExec ["addAction",0,true];
// } ;

if ((typeOf player == F_Recon_Med)  || (typeOf player == F_Assault_Med)  || (typeOf player == "B_G_medic_F")  || (typeOf player == "B_CTRG_soldier_M_medic_F")) then {
	player setUnitTrait ["medic", true];
player setVariable ["ace_medical_medicclass",2, true];
// [player,[
// 	"<img size=2 color='#0bff00' image='\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_revive_ca.paa'/><t font='PuristaBold' color='#0bff00'>HEAL Infantry",
// {
// (_this select 0) playMove "AinvPknlMstpSnonWnonDnon_medic_1" ; 
// [(_this select 0)] execVM "Scripts\HEAL.sqf" ;
// },
// 	nil,
// 	9999,
// 	true,
// 	true,
// 	"",
// 	"_this distance _target < 5", // _target, _this, _originalTarget
// 	5,
// 	false,
// 	"",
// 	""
// ]] remoteExec ["addAction",0,true];
} ;


player addAction
	[
	"<t color='#7CC2FF'>" + localize "STR_KPPLM_ACTIONOPEN" + "</t>",
    {[] call KPPLM_fnc_openDialog;},
	nil,
    -803,
	true,		
	true,		
	"",			
	"true", 	
	5,			
	false,		
	"",			
	""			
];

{_x enableAI "RADIOPROTOCOL"} foreach Units Group player;

if ((isClass (configfile >> "CfgVehicles" >> "Box_cTab_items") == true) && !("ItemAndroid" in ((vestItems player + uniformitems player + backpackItems player))) ) then { player addItem "ItemAndroid"; };  
if ((isClass (configfile >> "CfgVehicles" >> "Box_cTab_items") == true) && !("ItemcTab" in ((vestItems player + uniformitems player + backpackItems player))) ) then { player addItem "ItemcTab"; }; 


_Unts = Units Group player ; 
NewGrpID = groupId (group player) ; 
publicVariable "NewGrpID" ; 

sleep 3 ; 

_Group = createGroup West; 
[player] join _Group ;

sleep 3 ; 

_Unts join player ;
_Group setGroupIdGlobal [NewGrpID] ; 



if ((serverCommandAvailable "#kick")  &&  (serverCommandAvailable "#debug")) then {
	
	{unassignCurator ZEUS;} remoteExec ["call", 2];

ZEUSNetworkId = clientOwner;
publicVariable "ZEUSNetworkId";

	{		
		_ZEUSPLYOBJ = allPlayers select {owner _x == ZEUSNetworkId};	
		(_ZEUSPLYOBJ select 0) assignCurator ZEUS;
		
	} remoteExec ["call", 2]; 
  
 }; 


private _headlessClients = entities "HeadlessClient_F";
private _humanPlayers = allPlayers - _headlessClients;
hcRemoveAllGroups player;  
 {player hcRemoveGroup _x ;} forEach (allGroups select {side _x == west}); 
 _GRPs = (allGroups select {(side _x == (side player)) && !(((units _x) select 0) in switchableUnits)}); 
if (count _humanPlayers == 1 ) then {
{player hcSetGroup [_x];} forEach _GRPs;
}else{
{TheCommander hcSetGroup [_x];} forEach _GRPs;
};
   

titleText ["", "BLACK IN",1];

sleep 3 ; 

if (leader group player != player) then { group player selectLeader player; };
{_x enableAI "RADIOPROTOCOL"} foreach Units Group player;
