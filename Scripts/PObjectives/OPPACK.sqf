// Delete nearby triggers
private _allTriggers = allMissionObjects "EmptyDetector";
private _playerPos = getPosWorld player;
private _sortedTriggers = [_allTriggers, [], {_playerPos distanceSqr getPos _x}, "ASCEND"] call BIS_fnc_sortBy;

if (count _sortedTriggers > 0) then {
    deleteVehicle (_sortedTriggers select 0);
    
    sleep 1;
    
    // Delete second trigger after the first one
    _allTriggers = allMissionObjects "EmptyDetector";
    _sortedTriggers = [_allTriggers, [], {_playerPos distanceSqr getPos _x}, "ASCEND"] call BIS_fnc_sortBy;
    
    if (count _sortedTriggers > 0) then {
        deleteVehicle (_sortedTriggers select 0);
    };
};

// Delete the OP marker
private _opMarkers = allMapMarkers select {markerText _x == "OP" && markerType _x == "b_installation"};
if (count _opMarkers > 0) then {
    private _nearestMarker = [_opMarkers, player] call BIS_fnc_nearestPosition;
    deleteMarker _nearestMarker;
};

// Find and delete OP buildings
private _opBuilding = nearestObjects [position player, ["Land_Cargo_House_V1_F", "Land_Cargo_House_V3_F"], 70] select 0;
private _opEquipment = nearestObjects [position player, ["Land_TripodScreen_01_dual_v2_F", "Land_TripodScreen_01_dual_v2_sand_F"], 70] select 0;

// Store position and direction before deletion
private _buildingPos = getPos _opBuilding;
private _buildingDir = getDirVisual _opBuilding;

// Delete buildings
deleteVehicle _opBuilding;
deleteVehicle _opEquipment;

sleep 1;

// Create packed container
private _container = createVehicle ["B_Slingload_01_Repair_F", _buildingPos, [], 0, "NONE"];
_container setDir _buildingDir;

[_container, [
    "<t font='PuristaBold' color='#FF0000' size='1.15'>Move OP</t>", 
    { [player, true] call IDS_Logistics_fnc_initBuildCamera; }, 
    nil, 
    1.4, 
    false, 
    true, 
    "", 
    "!IDS_Logistics_isHolding"
]] remoteExec ["addAction", 0, true];

// Add unpack action
[_container, [
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack OP",
    "Scripts\PObjectives\OPUNPACK.sqf",
    nil,
    0,
    true,
    true,
    "",
    "true",
    40,
    false,
    "",
    ""
]] remoteExec ["addAction", 0, true];
