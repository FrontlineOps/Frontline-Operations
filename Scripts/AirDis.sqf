sleep 18 ;

["showNotification", ["SUPPORT DISABLED", "Enemy Aerial Support Dismantled For the Next Hour", "success"]] call FLO_fnc_intelSystem;

AIRDIS = 1;
publicVariable "AIRDIS";

_AIRs = nearestObjects [ player, East_Air_Jet, 40000];
{
_x setFuel 0;
_x setVehicleAmmo 0;
((crew _x) select 0) leaveVehicle _x;

} forEach _AIRs;
 
sleep 3600 ;

AIRDIS = 0;
publicVariable "AIRDIS";


