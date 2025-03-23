sleep 18 ;

["STR_FLO_SUPPORTDISABLED_TITLE", "STR_FLO_SUPPORTD_AIR", "success"] call FLO_fnc_sendNotification;

AIRDIS = 1;

_AIRs = nearestObjects [ player, East_Air_Jet, 40000];
{
_x setFuel 0;
_x setVehicleAmmo 0;
((crew _x) select 0) leaveVehicle _x;

} forEach _AIRs;
 
sleep 3600 ;

AIRDIS = 0;


