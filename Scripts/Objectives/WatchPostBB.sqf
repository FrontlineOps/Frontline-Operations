/*
    Author: [FLO]
    Description: Creates a watchpost at a road position with AI defenders
    
    Parameter(s):
        _this select 0: OBJECT - Road object
        _this select 1: NUMBER - Direction
    
    Returns: HASHMAP - Watchpost data structure
*/

params [
    ["_nearRoad", objNull, [objNull]],
    ["_dir", 0, [0]]
];

if (isNull _nearRoad) exitWith {
    diag_log "[FLO] Error: Invalid road object passed to WatchPostBB.sqf";
    objNull
};

// Initialize watchpost data structure
private _watchpostData = createHashMapObject [[
    ["position", getPos _nearRoad],
    ["direction", _dir],
    ["marker", ""],
    ["units", []],
    ["groups", []]
]];

// Define available watchpost compositions
private _watchpostTypes = [
    "Watchpost_1", "Watchpost_2", "Watchpost_3", "Watchpost_4", 
    "Watchpost_5", "Watchpost_6", "Watchpost_7", "Watchpost_8",
    "Watchpost_9", "Watchpost_10"
];

// Clear terrain objects
private _terrainObjects = nearestTerrainObjects [_watchpostData get "position", ["House", "TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS"], 15];
{_x hideObjectGlobal true} forEach _terrainObjects;

// Spawn composition
private _composition = [
    selectRandom _watchpostTypes,
    _watchpostData get "position",
    [0,0,0],
    random 350,
    false,
    false,
    true
] call LARs_fnc_spawnComp;

// Create marker for the road watchpost
private _pos = _watchpostData get "position";
private _markerName = format ["rdMark_%1_%2", floor (_pos select 0), floor (_pos select 1)];
createMarker [_markerName, _pos];
_markerName setMarkerType "o_service";
_markerName setMarkerColor "ColorEAST";
_markerName setMarkerAlpha 0.0; // Invisible on map

// Store marker in watchpost data
_watchpostData set ["marker", _markerName];

// Define garrison size - roadblocks typically smaller than mountain watchposts
private _garrisonSize = 6;

// Create the garrison using the garrison manager
private _units = ["spawn", [_markerName, _garrisonSize, true]] call FLO_fnc_garrisonManager;
_watchpostData set ["units", _units];

diag_log format ["[FLO][Roadblock] Created roadblock garrison at %1 with size %2", _markerName, _garrisonSize];

// Add patrol vehicle if needed
if (random 1 < 0.5) then {
    ["patrol", [_markerName, 400, selectRandom East_Ground_Vehicles_Light]] call FLO_fnc_vehicleGarrison;
    diag_log format ["[FLO][Roadblock] Added patrol vehicle to roadblock at %1", _markerName];
};

// Setup heavy weapons if present in the composition
private _weaponSetup = {
    {
        [_x, 3, position _x, "ATL"] call BIS_fnc_setHeight;
        _x setVectorUp [0,0,1];
    } forEach _this;
};

private _heavyWeapons = nearestObjects [_watchpostData get "position", ["O_G_HMG_02_high_F", "O_G_Mortar_01_F"], 100];
_heavyWeapons call _weaponSetup;

// Return the watchpost data
_watchpostData
