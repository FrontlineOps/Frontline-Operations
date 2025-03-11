// Find the nearest FOB container
private _fobContainer = nearestObjects [player, ["B_Slingload_01_Cargo_F"], 200] select 0;
private _pos = getPos _fobContainer;
private _dir = getDirVisual _fobContainer;

// Delete the container
sleep 1;
_fobContainer setPos [0,0,0];
deleteVehicle _fobContainer;

// Create FOB HQ building
private _fobHQ = createVehicle [F_HQ_01, _pos, [], 0, "CAN_COLLIDE"];
_fobHQ setDir _dir;

// Create FOB screen at the appropriate building position
private _screenPos = (_fobHQ buildingPos -1) select 10;  
private _fobScreen = createVehicle [F_HQ_C_01, _screenPos, [], 0, "CAN_COLLIDE"];
_fobScreen setDir _dir + 180;

// Initialize FOB functionality
sleep 1;
private _fobInit = execVM "Scripts\Init\init_FOB.sqf";  
waitUntil {scriptDone _fobInit};