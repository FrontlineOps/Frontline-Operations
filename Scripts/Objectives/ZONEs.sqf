/*
    Author: [FLO]
    Description: Creates a zone around a trigger with watchposts and defensive positions
    
    Parameter(s):
        _this select 0: OBJECT - Trigger object
        _this select 1: NUMBER - Radius of the zone
    
    Returns: HASHMAP - Zone data structure
*/

params [
    ["_triggerObj", objNull, [objNull]],
    ["_radius", 1000, [0]]
];

if (isNull _triggerObj) exitWith {
    diag_log "[FLO] Error: Invalid trigger object passed to ZONEs.sqf";
    objNull
};

// Initialize zone data structure
private _zoneData = createHashMapObject [[
    ["position", getPos _triggerObj],
    ["radius", _radius],
    ["watchpostPositions", []],
    ["watchpostMarkers", []],
    ["mounts", []],
    ["aggrScore", 0]
]];

// Get aggression score from marker
private _markers = allMapMarkers select {markerColor _x == "Color6_FD_F"};
if (count _markers > 0) then {
    _zoneData set ["aggrScore", parseNumber (markerText (_markers select 0))];
};

// Find suitable mount positions
private _allMounts = nearestLocations [_zoneData get "position", ["Mount"], _zoneData get "radius"];
private _allWatchposts = [
    "Watchpost_1", "Watchpost_2", "Watchpost_3", "Watchpost_4", 
    "Watchpost_5", "Watchpost_6", "Watchpost_7", "Watchpost_8",
    "Watchpost_9", "Watchpost_10"
];

// Find enemy positions from markers
private _enemyMarkers = allMapMarkers select {
    markerType _x == "b_installation"
};

private _enemyPositions = _enemyMarkers apply {getMarkerPos _x};

// Function to check if position is suitable for watchpost
private _isSuitablePosition = {
    params ["_pos"];
    private _tooClose = false;
    {
        if (_pos distance2D _x < 500) exitWith {
            _tooClose = true;
        };
    } forEach (_zoneData get "watchpostPositions");
    !_tooClose
};

// Function to score position based on direction to enemies
private _scorePosition = {
    params ["_pos"];
    if (_enemyPositions isEqualTo []) exitWith {1};
    
    private _zonePos = _zoneData get "position";
    private _zoneToPos = _zonePos getDir _pos;
    
    private _bestScore = 0;
    {
        private _zoneToEnemy = _zonePos getDir _x;
        private _angleDiff = abs ((_zoneToEnemy - _zoneToPos + 180) % 360 - 180);
        private _dirScore = 1 - (_angleDiff / 180); // 1 when facing enemy, 0 when facing away
        _bestScore = _bestScore max _dirScore;
    } forEach _enemyPositions;
    
    _bestScore
};

// Sort mounts by score
private _sortedMounts = [_allMounts, [], {-([locationPosition _x] call _scorePosition)}] call BIS_fnc_sortBy;

// Function to create a watchpost with garrison
private _createWatchpostGarrison = {
    params ["_mountPos", "_compName"];
    
    // Create marker for the watchpost
    private _markerName = format ["wpMark_%1_%2", floor (_mountPos select 0), floor (_mountPos select 1)];
    createMarker [_markerName, _mountPos];
    _markerName setMarkerType "o_recon";
    _markerName setMarkerColor "ColorEAST";
    _markerName setMarkerAlpha 0.0; // Invisible on map
    
    // Store the marker
    (_zoneData get "watchpostMarkers") pushBack _markerName;
    
    // Get aggression score for garrison size
    private _aggrScore = _zoneData get "aggrScore";
    private _garrisonSize = 4; // Base size
    
    // Scale garrison size based on aggression
    if (_aggrScore > 5) then {
        _garrisonSize = 6;
    };
    if (_aggrScore > 10) then {
        _garrisonSize = 8;
    };
    
    // Spawn the composition
    [_mountPos, _compName] execVM "Scripts\Objectives\WatchPostComp.sqf";
    
    // Create the garrison with the garrison manager
    ["spawn", [_markerName, _garrisonSize, false]] call FLO_fnc_garrisonManager;
    
    diag_log format ["[FLO][Zone] Created watchpost garrison at %1 with size %2", _markerName, _garrisonSize];
    
    // Return the marker
    _markerName
};

// Place initial watchposts with direction consideration
{
    private _mountPos = locationPosition _x;
    if ([_mountPos] call _isSuitablePosition) then {
        private _score = [_mountPos] call _scorePosition;
        if (_score > 0.5) then { // Only place if reasonably facing enemies
            // Create garrison at this position
            private _selectedComp = selectRandom _allWatchposts;
            [_mountPos, _selectedComp] call _createWatchpostGarrison;
            (_zoneData get "watchpostPositions") pushBack _mountPos;
        };
    };
    if (count (_zoneData get "watchpostPositions") >= 3) exitWith {};
} forEach _sortedMounts;

// Add additional watchposts based on aggression score
if ((_zoneData get "aggrScore") > 5) then {
    if ((_zoneData get "radius") >= 2000) then {
        private _validMounts = _allMounts select {[locationPosition _x] call _isSuitablePosition};
        if !(_validMounts isEqualTo []) then {
            private _sortedMounts = [_validMounts, [], {-([locationPosition _x] call _scorePosition)}] call BIS_fnc_sortBy;
            private _mount = _sortedMounts select 0;
            if ([locationPosition _mount] call _scorePosition > 0.5) then {
                private _mountPos = locationPosition _mount;
                private _selectedComp = selectRandom _allWatchposts;
                [_mountPos, _selectedComp] call _createWatchpostGarrison;
                (_zoneData get "watchpostPositions") pushBack _mountPos;
            };
        };
    };

    if ((_zoneData get "radius") >= 1000) then {
        private _validMounts = _allMounts select {[locationPosition _x] call _isSuitablePosition};
        if !(_validMounts isEqualTo []) then {
            private _sortedMounts = [_validMounts, [], {-([locationPosition _x] call _scorePosition)}] call BIS_fnc_sortBy;
            private _mount = _sortedMounts select 0;
            if ([locationPosition _mount] call _scorePosition > 0.5) then {
                private _mountPos = locationPosition _mount;
                private _selectedComp = selectRandom _allWatchposts;
                [_mountPos, _selectedComp] call _createWatchpostGarrison;
                (_zoneData get "watchpostPositions") pushBack _mountPos;
            };
        };
    };
};

// Add even more watchposts for high aggression
if ((_zoneData get "aggrScore") > 10) then {
    {
        if (_x >= (_zoneData get "radius")) then {
            private _validMounts = _allMounts select {[locationPosition _x] call _isSuitablePosition};
            if !(_validMounts isEqualTo []) then {
                private _sortedMounts = [_validMounts, [], {-([locationPosition _x] call _scorePosition)}] call BIS_fnc_sortBy;
                private _mount = _sortedMounts select 0;
                if ([locationPosition _mount] call _scorePosition > 0.5) then {
                    private _mountPos = locationPosition _mount;
                    private _selectedComp = selectRandom _allWatchposts;
                    [_mountPos, _selectedComp] call _createWatchpostGarrison;
                    (_zoneData get "watchpostPositions") pushBack _mountPos;
                };
            };
        };
    } forEach [2000, 1500];
};

// Return the zone data
_zoneData
