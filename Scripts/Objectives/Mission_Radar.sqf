/*
    Script: Mission_Radar.sqf
    
    Description:
    Sets up a radar mission objective with intel items and triggers.
*/

// Get passed trigger
private _radarTrigger = _this select 0;
private _radarPos = getPos _radarTrigger;

// Get current aggression score from marker
private _aggrMarkers = allMapMarkers select {markerColor _x == "Color6_FD_F"};
private _aggrScore = 0;
if (count _aggrMarkers > 0) then {
    _aggrScore = parseNumber (markerText (_aggrMarkers select 0));
};

// Spawn HMG positions
[_radarTrigger] execVM "Scripts\HMGspawn.sqf";

// Find building positions for intel placement
private _nearBuildings = nearestObjects [_radarPos, [
    "House", "Land_MilOffices_V1_F", 
    "Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V2_F", "Land_Cargo_Tower_V1_F", 
    "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V1_F", 
    "Land_Cargo_House_V3_F", "Land_Cargo_House_V1_F"
], 300];

private _allPositions = [];
{
    _allPositions append (_x buildingPos -1);
} forEach _nearBuildings;

// Only proceed if we found valid positions
if (count _allPositions > 0) then {
    // Spawn intel item at random building position
    ["Intel_01", selectRandom _allPositions, [0,0,0], 0, false, false, true] call LARs_fnc_spawnComp;
};

// Spawn intel items around radar position
[_radarTrigger, 200] execVM "Scripts\INTLitems.sqf";