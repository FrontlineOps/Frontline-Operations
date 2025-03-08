/*
    Author: [FLO]
    Description: Creates a watchpost composition at specified location without AI defenders
    
    Parameter(s):
        _this select 0: ARRAY - Position
        _this select 1: STRING - Watchpost composition name
    
    Returns: OBJECT - Watchpost composition object
*/

params [
    ["_position", [0,0,0], [[]]],
    ["_watchpostComp", "", [""]]
];

if (_position isEqualTo [0,0,0] || _watchpostComp == "") exitWith {
    diag_log "[FLO] Error: Invalid parameters passed to WatchPostComp.sqf";
    objNull
};

// Clear terrain objects
private _terrainObjects = nearestTerrainObjects [_position, ["House", "TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS"], 15];
{_x hideObjectGlobal true} forEach _terrainObjects;

// Calculate watchpost direction
private _wpDir = 0;
private _nearbyHouses = nearestObjects [_position, ["House"], 200];
if !(_nearbyHouses isEqualTo []) then {
    _wpDir = getDirVisual (_nearbyHouses select 0);
} else {
    _wpDir = random 360;
};

// Spawn composition
private _composition = [
    _watchpostComp,
    _position,
    [0,0,0],
    _wpDir,
    true
] call LARs_fnc_spawnComp;

// Adjust composition objects
{
    _x setVectorUp [0,0,1];
} forEach ([_composition] call LARs_fnc_getCompObjects);

// Setup heavy weapons
private _heavyWeapons = nearestObjects [_position, ["O_G_HMG_02_high_F", "O_G_Mortar_01_F"], 100];
{
    [_x, 3, position _x, "ATL"] call BIS_fnc_setHeight;
    _x setVectorUp [0,0,1];
} forEach _heavyWeapons;

diag_log format ["[FLO][WatchPost] Created watchpost composition %1 at position %2", _watchpostComp, _position];

// Return the composition object
_composition 