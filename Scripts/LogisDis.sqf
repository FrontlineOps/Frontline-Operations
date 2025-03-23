sleep 18;

["STR_FLO_SUPPORTDISABLED_TITLE", "STR_FLO_SUPPORTD_LOGI", "success"] call FLO_fnc_sendNotification;

LOGDIS = 1;

 _LOGs = nearestObjects [ player, East_Ground_Vehicles_Ambient, 40000];
{
_x setFuel 0;
_x setVehicleAmmo 0;
((crew _x) select 0) leaveVehicle _x;

} forEach _LOGs;

sleep 3600 ;

LOGDIS = 0;