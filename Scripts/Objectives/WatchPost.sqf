/*
    Author: [FLO]
    Description: Creates a watchpost at specified location with AI defenders
    
    Parameter(s):
        _this select 0: LOCATION - Mount selection location
        _this select 1: STRING - Watchpost composition name
    
    Returns: OBJECT - Watchpost composition object
*/

params [
    ["_mountSel", locationNull, [locationNull]],
    ["_watchpostComp", "", [""]]
];

if (isNull _mountSel || _watchpostComp == "") exitWith {
    diag_log "[FLO] Error: Invalid parameters passed to WatchPost.sqf";
    objNull
};

// Initialize watchpost data structure
private _watchpostData = createHashMapObject [[
    ["position", locationPosition _mountSel],
    ["composition", _watchpostComp],
    ["marker", ""],
    ["units", []],
    ["groups", []]
]];

// Get aggression score from marker
private _aggrScore = 0;
private _markers = allMapMarkers select {markerColor _x == "Color6_FD_F"};
if (count _markers > 0) then {
    _aggrScore = parseNumber (markerText (_markers select 0));
};

// Clear terrain objects
private _terrainObjects = nearestTerrainObjects [_watchpostData get "position", ["House", "TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS"], 15];
{_x hideObjectGlobal true} forEach _terrainObjects;

// Calculate watchpost direction
private _wpDir = 0;
private _nearbyHouses = nearestObjects [_watchpostData get "position", ["House"], 200];
if !(_nearbyHouses isEqualTo []) then {
    _wpDir = getDirVisual (_nearbyHouses select 0);
} else {
    _wpDir = random 360;
};

// Spawn composition
private _composition = [
    _watchpostData get "composition",
    _watchpostData get "position",
    [0,0,0],
    _wpDir,
    true
] call LARs_fnc_spawnComp;

// Adjust composition objects
{
    _x setVectorUp [0,0,1];
} forEach ([_composition] call LARs_fnc_getCompObjects);

// Create marker for the watchpost
private _pos = _watchpostData get "position";
private _markerName = format ["wpMark_%1_%2", floor (_pos select 0), floor (_pos select 1)];
createMarker [_markerName, _pos];
_markerName setMarkerType "o_recon";
_markerName setMarkerColor "ColorEAST";
_markerName setMarkerAlpha 0.0; // Invisible on map

// Store marker in watchpost data
_watchpostData set ["marker", _markerName];

// Define garrison size based on aggression
private _garrisonSize = 4; // Base size

// Scale garrison size based on aggression
if (_aggrScore > 5) then {
    _garrisonSize = 10;
};
if (_aggrScore > 10) then {
    _garrisonSize = 16;
};

// Create the garrison using the garrison manager
private _units = ["spawn", [_markerName, _garrisonSize, false]] call FLO_fnc_garrisonManager;
_watchpostData set ["units", _units];

diag_log format ["[FLO][Watchpost] Created watchpost garrison at %1 with size %2", _markerName, _garrisonSize];

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
