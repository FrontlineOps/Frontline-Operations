////////////////////////////////////////////////////////////////////////////////////////////////////////////

_FOBC = nearestobjects [player,["B_Slingload_01_Repair_F"],200] select 0 ;
_pos = getpos _FOBC;
_dir = getDirVisual _FOBC;
sleep 1;

_FOBC setPos [0,0,0];
deleteVehicle _FOBC;



_FOB = createVehicle [F_OP_01,_pos, [], 0, "CAN_COLLIDE"];
_FOB setDir _dir;


_pos = (_FOB buildingPos -1) select 0 ;  
_FOBTV = createVehicle [F_OP_C_01,_pos, [], 0, "CAN_COLLIDE"];
_FOBTV setDir _dir + 45 ;


sleep 1 ;
_FOBADD = execVM "Scripts\Init\init_OP.sqf";  
waitUntil { scriptDone _FOBADD };



////////////////////////////////////////////////////////////////////////////////////////////////////////////
