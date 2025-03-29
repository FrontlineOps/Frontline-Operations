// Delete all nearby triggers
private _fobTriggers = [];
for "_i" from 1 to 4 do {
    private _alltriggers = allMissionObjects "EmptyDetector";
    private _referencePos = getPosWorld player;
    private _sortedByRange = [_alltriggers, [], {_referencePos distanceSqr getPos _x}, "ASCEND"] call BIS_fnc_sortBy;
    
    if (count _sortedByRange > 0) then {
        private _nearestTrigger = _sortedByRange select 0;
        deleteVehicle _nearestTrigger;
        _fobTriggers pushBack _nearestTrigger;
    };
    
    sleep 1;
};

// Delete FOB marker
private _fobMarkers = allMapMarkers select {markerText _x == "FOB"};
private _nearestMarker = [_fobMarkers, player] call BIS_fnc_nearestPosition;
deleteMarker _nearestMarker;

// Find FOB buildings
private _fobHQ = nearestObjects [position player, ["Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"], 70] select 0;
private _fobScreen = nearestObjects [position player, ["Land_TripodScreen_01_large_sand_F", "Land_TripodScreen_01_large_F"], 70] select 0;

// Store position and direction before deletion
private _pos = getPos _fobHQ;
private _dir = getDirVisual _fobHQ;

// Delete FOB buildings
deleteVehicle _fobHQ;
deleteVehicle _fobScreen;

sleep 1;

// Create packed FOB container
private _fobContainer = createVehicle ["B_Slingload_01_Cargo_F", _pos, [], 0, "NONE"];
_fobContainer setDir _dir;

[_fobContainer, [
    "<t font='PuristaBold' color='#FF0000' size='1.15'>Move FOB</t>", 
    { [player, true] call IDS_Logistics_fnc_initBuildCamera; }, 
    nil, 
    1.4, 
    false, 
    true, 
    "", 
    "!IDS_Logistics_isHolding"
]] remoteExec ["addAction", 0, true];

// Add unpack action to FOB container
[_fobContainer, [
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack FOB",
    "Scripts\PObjectives\FOBUNPACK.sqf",
    nil,
    0,
    true,
    true,
    "",
    "player == TheCommander",
    40,
    false,
    "",
    ""
]] remoteExec ["addAction", 0, true];