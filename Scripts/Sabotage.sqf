thisGenerator = _this select 0;
publicVariable "thisGenerator";


Lightsss = nearestObjects [thisGenerator, [
"Lamps_Base_F", 
"Land_PortableLight_single_F",
"Land_PortableLight_double_F",
"Land_LampAirport_F", 
"Land_LampSolar_F", 
"Land_LampStreet_F", 
"Land_LampStreet_small_F", 
"PowerLines_base_F", 
"Land_LampDecor_F", 
"Land_LampHalogen_F", 
"Land_LampHarbour_F", 
"Land_LampShabby_F", 
"Land_PowerPoleWooden_L_F", 
"Land_NavigLight", 
"Land_runway_edgelight", 
"Land_runway_edgelight_blue_F", 
"Land_Flush_Light_green_F", 
"Land_Flush_Light_red_F", 
"Land_Flush_Light_yellow_F", 
"Land_Runway_PAPI", 
"Land_Runway_PAPI_2", 
"Land_Runway_PAPI_3", 
"Land_Runway_PAPI_4", 
"Land_fs_roof_F", 
"Land_fs_sign_F" 
], 2500];

publicVariable "Lightsss";


{ {_x setdamage 0.9 ;} forEach Lightsss; } remoteExec ["call", 0];



  // {
  //     _nvg = hmd _x;
  //     _x unassignItem _nvg;
  //     _x removeItem _nvg;
	//   _x addPrimaryWeaponItem "acc_flashlight";
	//   _x assignItem "acc_flashlight";
	//   _x enableGunLights "ForceOn";
  // } foreach (allUnits select {side _x == east}); 

sleep 18;

["showNotification", ["SUPPORT DISABLED", "Region Power Disabled For the Next Hour", "success"]] call FLO_fnc_intelSystem;

PowerOFF = 1 ;
publicVariable "PowerOFF";

[] spawn {  
  while { sleep 90 ; PowerOFF == 1} do{ 
 
 { 
 
 _LantLoc = nearestObjects [thisGenerator, ["Land_Camping_Light_F"], 2500];

{ 
deleteVehicle _x
} forEach _LantLoc; 
 
_ENMs = {(side _x != west) && (alive _x == true)} count nearestObjects [thisGenerator,["Man"], 2500] ;
  if ((dayTime > 19) or (dayTime < 7)) then {	{_x disableAI "CHECKVISIBLE" ;} forEach _ENMs ; };
 } remoteExec ["call", 0];			
 
  };  
};


sleep 3600;

{
_x setdamage 0 ;
} forEach _LightLoc;


PowerOFF = 0 ;
publicVariable "PowerOFF";



