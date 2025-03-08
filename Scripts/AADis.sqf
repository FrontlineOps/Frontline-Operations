sleep 18 ;


_OAA = nearestObjects [position player, ["O_Radar_System_02_F", "O_SAM_System_04_F"], 40000];

{
deleteVehicleCrew vehicle _x ;
 } foreach _OAA;
 
 FLO_Intel_System call ["showNotification", ["SUPPORT DISABLED", "Enemy Anti-Air Sites Disabled For the Next Hour", "success"]];


sleep 3600 ;


{
_gRPcREW = createVehicleCrew _x ;
_Group = createGroup East; 
{[_x] join _Group} forEach units _gRPcREW;

 } foreach _OAA;