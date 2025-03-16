sleep 18;

["showNotification", ["SUPPORT DISABLED", "Enemy Heavy Weapons Support Dismantled For the Next Hour", "success"]] call FLO_fnc_intelSystem;

INFDIS = 1;
publicVariable "INFDIS";

				{ _x setdamage 1;} foreach (allUnits select {side _x == east && count (units group _x )> 5}); 


LnchOFF = 1 ;
publicVariable "LnchOFF";

[] spawn {  
  while {(LnchOFF == 1)} do{ 
 
		 { 

				{_x removeWeaponGlobal (secondaryWeapon _x);} foreach (allUnits select {side _x != west}); 

		 } remoteExec ["call", 0];			
 
 sleep 90;  
  };  
};



sleep 3600 ;

INFDIS = 0;
publicVariable "INFDIS";
LnchOFF = 0 ;
publicVariable "LnchOFF";
