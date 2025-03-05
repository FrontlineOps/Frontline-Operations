/*
    Script: Mission_Air.sqf
    
    Description:
    Creates enemy air patrols based on the current aggression score.
    
    Parameters:
    0: _triggerObject - The trigger that activated this script
*/

private _triggerObject = _this select 0;
private _triggerPos = getPos _triggerObject;

// Get current aggression score from marker
private _aggrMarkers = allMapMarkers select {markerColor _x == "Color6_FD_F"};
private _aggrScore = 0;
if (count _aggrMarkers > 0) then {
    _aggrScore = parseNumber (markerText (_aggrMarkers select 0));
};

// Function to create and setup an aircraft
private _fnc_createAircraft = {
    params ["_spawnPos", "_heading", "_patrolRadius", ["_isFirstAircraft", false]];
    
    // Create aircraft
    private _aircraft = createVehicle [
        selectRandom (FLO_configCache get "vehicles" select 6), 
        _spawnPos getPos [100, _heading], 
        [], 
        100, 
        "FLY"
    ];
    
    // Add killed event handler only for the first aircraft
    if (_isFirstAircraft) then {
        _aircraft addEventHandler ["Killed", { 
            private _airMarkers = allMapMarkers select {markerType _x == "o_plane"};
            private _nearestMarker = [_airMarkers, (_this select 0)] call BIS_fnc_nearestPosition;
            
            deleteMarker _nearestMarker;
            
            [50, "AIR PATROL"] call FLO_fnc_notification;
            [50] call FLO_fnc_addReward;
            [] execVM "Scripts\DangerPlus.sqf";
        }];
    };
    
    // Create crew and group
    private _crewGroup = createVehicleCrew _aircraft;
    private _group = createGroup East;
    {[_x] join _group} forEach units _crewGroup;
    
    // Configure aircraft settings
    _aircraft flyInHeight 700;
    _aircraft disableAI "LIGHTS";
    _aircraft setPilotLight true;
    _aircraft setCollisionLight true;
    
    // Set patrol waypoints
    [_group, _spawnPos, _patrolRadius] call BIS_fnc_taskPatrol;
    
    _aircraft // Return the created aircraft
};

// Create first aircraft (with event handler)
[_triggerPos, 0, 3000, true] call _fnc_createAircraft;

// Create second aircraft
[_triggerPos, 60, 5000] call _fnc_createAircraft;

// Create additional aircraft based on aggression score
if (_aggrScore > 5) then {
    [_triggerPos, 120, 3000] call _fnc_createAircraft;
};

if (_aggrScore > 10) then {
    [_triggerPos, 180, 5000] call _fnc_createAircraft;
};