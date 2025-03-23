sleep 18;

["STR_FLO_SUPPORTDISABLED_TITLE", "STR_FLO_SUPPORTD_HELI", "success"] call FLO_fnc_sendNotification;

HELIDIS = 1;

_Helis = nearestObjects [ player, East_Air_Heli, 40000];
{
_x setFuel 0;
_x setVehicleAmmo 0;
((crew _x) select 0) leaveVehicle _x;

} forEach _Helis;

sleep 3600 ;

HELIDIS = 0;
