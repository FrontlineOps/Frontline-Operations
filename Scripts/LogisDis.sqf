sleep 18;

["showNotification", ["SUPPORT DISABLED", "Enemy Logistics Support Dismantled For the Next Hour", "success"]] call FLO_fnc_intelSystem;

LOGDIS = 1;
publicVariable "LOGDIS";

 _LOGs = nearestObjects [ player, East_Ground_Vehicles_Ambient, 40000];
{
_x setFuel 0;
_x setVehicleAmmo 0;
((crew _x) select 0) leaveVehicle _x;

} forEach _LOGs;

sleep 3600 ;

LOGDIS = 0;
publicVariable "LOGDIS";

