/*
    Script: Mission_Armor.sqf
    
    Description:
    Creates enemy armor vehicles based on current aggression score.
    
    Parameters:
    0: _triggerObject - The trigger that activated this script
*/

private _triggerObject = _this select 0;
private _triggerPos = getPos _triggerObject;

// Find suitable spawn location (preferably on a road)
private _spawnLocation = _triggerObject;
private _nearbyRoads = _triggerPos nearRoads 300;
if (count _nearbyRoads > 0) then {
    _spawnLocation = selectRandom _nearbyRoads;
};

// Get current aggression score from marker
private _aggrMarkers = allMapMarkers select {markerColor _x == "Color6_FD_F"};
private _aggrScore = 0;
if (count _aggrMarkers > 0) then {
    _aggrScore = parseNumber (markerText (_aggrMarkers select 0));
};

// Create the primary group that will contain all vehicle crews
private _mainGroup = createGroup East;

// Function to create and setup a vehicle
private _fnc_createArmoredVehicle = {
    params ["_spawnPos", "_direction"];
    
    // Create vehicle with some randomization in position
    private _randomPos = _spawnPos getRelPos [70 + random 30, random 360];
    private _vehicle = createVehicle [selectRandom East_Ground_Vehicles_Heavy, _randomPos, [], 4, "NONE"];
    
    // Set vehicle direction if provided
    if (!isNil "_direction") then {
        _vehicle setDir _direction;
    };
    
    // Create crew and add them to the main group
    private _crewGroup = createVehicleCrew _vehicle;
    {[_x] join _mainGroup} forEach units _crewGroup;
    
    // Configure vehicle settings
    _vehicle disableAI "LIGHTS";
    _vehicle setPilotLight true;
    
    // Add killed event handler only for the first vehicle
    if (isNil "trgARM") then {
        trgARM = 0; // Initialize tracking variable
        
        _vehicle addEventHandler ["Killed", {
            private _armorMarkers = allMapMarkers select {markerType _x == "o_armor"};
            private _nearestMarker = [_armorMarkers, (_this select 0)] call BIS_fnc_nearestPosition;
            
            deleteMarker _nearestMarker;
            
            [100, "ARMOR PATROL"] call FLO_fnc_notification;
            [100] call FLO_fnc_addReward;
            [] execVM "Scripts\DangerPlus.sqf";
        }];
    };
    
    _vehicle // Return the created vehicle
};

// Create initial vehicles (always spawn at least 2)
private _direction = 0;
private _road = _spawnLocation;

// Try to get road direction if available
if (_road isEqualType objNull && {isNull _road isEqualTo false}) then {
    private _connectedRoads = roadsConnectedTo _road;
    if (count _connectedRoads > 0) then {
        _direction = _road getDir (_connectedRoads select 0);
    };
};

// Spawn first vehicle (with event handler)
[_spawnLocation, _direction] call _fnc_createArmoredVehicle;

// Spawn second vehicle
[_spawnLocation, _direction] call _fnc_createArmoredVehicle;

// Spawn additional vehicles based on aggression score
if (_aggrScore > 5) then {
    // Spawn two more vehicles at aggression > 5
    [_spawnLocation, _direction] call _fnc_createArmoredVehicle;
    [_spawnLocation, _direction] call _fnc_createArmoredVehicle;
};

if (_aggrScore > 10) then {
    // Spawn two more vehicles at aggression > 10
    [_spawnLocation, _direction] call _fnc_createArmoredVehicle;
    [_spawnLocation, _direction] call _fnc_createArmoredVehicle;
};

// Set patrol waypoints for the entire group
[_mainGroup, _triggerPos getPos [70 + random 90, random 360], 50] call BIS_fnc_taskPatrol;

sleep 3;