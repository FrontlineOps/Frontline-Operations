sleep 18 ;


["STR_FLO_SUPPORTDISABLED_TITLE", "STR_FLO_SUPPORTD_ARMOR", "success"] call FLO_fnc_sendNotification;




ARMDIS = 1;

_ARMs = nearestObjects [ player, East_Ground_Vehicles_Heavy, 40000];
{
_x setFuel 0;
_x setVehicleAmmo 0;
((crew _x) select 0) leaveVehicle _x;

} forEach _ARMs;
 
sleep 3600 ;

ARMDIS = 0;
