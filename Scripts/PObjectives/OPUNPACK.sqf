// Find the repair slingload container near the player
private _repairContainer = nearestObjects [player, ["B_Slingload_01_Repair_F"], 200] select 0;
private _containerPos = getPos _repairContainer;
private _containerDir = getDirVisual _repairContainer;

// Remove the container
sleep 1;
_repairContainer setPos [0,0,0];
deleteVehicle _repairContainer;

// Create the Observation Post building
private _opBuilding = createVehicle [F_OP_01, _containerPos, [], 0, "CAN_COLLIDE"];
_opBuilding setDir _containerDir;

// Place the communication equipment inside the building
private _buildingInteriorPos = (_opBuilding buildingPos -1) select 0;
private _commEquipment = createVehicle [F_OP_C_01, _buildingInteriorPos, [], 0, "CAN_COLLIDE"];
_commEquipment setDir _containerDir + 45;

// Initialize the Observation Post functionality
sleep 1;
private _initScript = execVM "Scripts\Init\init_OP.sqf";
waitUntil {scriptDone _initScript};