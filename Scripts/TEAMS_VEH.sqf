
_Unt = _this select 0 ;

hcRemoveAllGroups player; 
_Group = createGroup West; 
{[_x] join _Group} forEach units (group player);

_VEH = vehicle _Unt;
GNR = gunner _VEH;
DVR = driver _VEH;

GNRT = "VEHICLE_GUNNER" ;
DVRT = "VEHICLE_DRIVER" ;

if (isNull GNR) then {GNRT = "" ;};


0 = [] spawn {

  _result = ["! Select Vehicle Role !", "", DVRT, GNRT,nil, false, false] call BIS_fnc_guiMessage;

  hint str _result;
if (_result) then {
					if (getConnectedUAV player != objNull) then {player connectTerminalToUAV objNull;};
			 removeAllActions player ;
			hcRemoveAllGroups player; 
			_Group = createGroup West; 
			{[_x] join _Group} forEach units (group player);

			selectPlayer DVR;

			openMap [true, false]; 
			openMap [false, false]; 

			ShowHUD [true, true, true, true, true, true, true, true, true, true];
			{_x enableAI "RADIOPROTOCOL"} foreach Units Group player;
			hint "";

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
			
			
		if ((isClass (configfile >> "CfgVehicles" >> "Box_cTab_items") == true) && !("ItemAndroid" in ((vestItems player + uniformitems player + backpackItems player))) ) then { player addItem "ItemAndroid"; };  
		if ((isClass (configfile >> "CfgVehicles" >> "Box_cTab_items") == true) && !("ItemcTab" in ((vestItems player + uniformitems player + backpackItems player))) ) then { player addItem "ItemcTab"; }; 		

if ((serverCommandAvailable "#kick")  &&  (serverCommandAvailable "#debug")) then {
	
	{unassignCurator ZEUS;} remoteExec ["call", 2];

ZEUSNetworkId = clientOwner;
publicVariable "ZEUSNetworkId";

	{		
		_ZEUSPLYOBJ = allPlayers select {owner _x == ZEUSNetworkId};	
		(_ZEUSPLYOBJ select 0) assignCurator ZEUS;
		
	} remoteExec ["call", 2]; 
  
 }; 

		
			} ;

if (!_result) then {
						if (getConnectedUAV player != objNull) then {player connectTerminalToUAV objNull;};
			 removeAllActions player ;
			hcRemoveAllGroups player; 
			_Group = createGroup West; 
			{[_x] join _Group} forEach units (group player);

			selectPlayer GNR;

			openMap [true, false]; 
			openMap [false, false]; 

			ShowHUD [true, true, true, true, true, true, true, true, true, true];
			{_x enableAI "RADIOPROTOCOL"} foreach Units Group player;
			hint "";

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
			
		if ((isClass (configfile >> "CfgVehicles" >> "Box_cTab_items") == true) && !("ItemAndroid" in ((vestItems player + uniformitems player + backpackItems player))) ) then { player addItem "ItemAndroid"; };  
		if ((isClass (configfile >> "CfgVehicles" >> "Box_cTab_items") == true) && !("ItemcTab" in ((vestItems player + uniformitems player + backpackItems player))) ) then { player addItem "ItemcTab"; }; 		

if ((serverCommandAvailable "#kick")  &&  (serverCommandAvailable "#debug")) then {
	
	{unassignCurator ZEUS;} remoteExec ["call", 2];

ZEUSNetworkId = clientOwner;
publicVariable "ZEUSNetworkId";

	{		
		_ZEUSPLYOBJ = allPlayers select {owner _x == ZEUSNetworkId};	
		(_ZEUSPLYOBJ select 0) assignCurator ZEUS;
		
	} remoteExec ["call", 2]; 
  
 }; 


			 };
};









