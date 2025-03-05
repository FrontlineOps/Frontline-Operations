////////////////////////////////////////////////////////////////////////////////////////////////////////////

_FOBC = nearestobjects [player,["B_Slingload_01_Cargo_F"],200] select 0 ;
_pos = getpos _FOBC;
_dir = getDirVisual _FOBC;
sleep 1;

_FOBC setPos [0,0,0];
deleteVehicle _FOBC;



_FOB = createVehicle [F_HQ_01,_pos, [], 0, "CAN_COLLIDE"];
_FOB setDir _dir;


_pos = (_FOB buildingPos -1) select 10 ;  
_FOBTV = createVehicle [F_HQ_C_01,_pos, [], 0, "CAN_COLLIDE"];
_FOBTV setDir _dir + 180 ;


sleep 1 ;
_FOBADD = execVM "Scripts\Init\init_FOB.sqf";  
waitUntil { scriptDone _FOBADD };


////////////////////////////////////////////////////////////////////////////////////////////////////////////
