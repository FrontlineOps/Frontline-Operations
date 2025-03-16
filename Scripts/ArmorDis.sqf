sleep 18 ;


["showNotification", ["SUPPORT DISABLED", "Enemy Armored Support Dismantled For the Next Hour", "success"]] call FLO_fnc_intelSystem;




ARMDIS = 1;
publicVariable "ARMDIS";

_ARMs = nearestObjects [ player, East_Ground_Vehicles_Heavy, 40000];
{
_x setFuel 0;
_x setVehicleAmmo 0;
((crew _x) select 0) leaveVehicle _x;

} forEach _ARMs;
 
sleep 3600 ;

ARMDIS = 0;
publicVariable "ARMDIS";
