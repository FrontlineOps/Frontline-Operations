// Town Hostile Forces System
params ["_thisTownTrigger"];

// Initialize variables
private _triggerPos = getPos _thisTownTrigger;
private _aggrScore = parseNumber (markerText ((allMapMarkers select {markerColor _x == "Color6_FD_F"}) select 0));
private _repScore = parseNumber (markerText ((allMapMarkers select {markerColor _x == "Color4_FD_F"}) select 0));
private _chance = selectRandom [0,1,2,3];

// Cache building positions
private _allBuildings = nearestObjects [_triggerPos, ["HOUSE"], 80];
private _allPositions = [];
{
    _allPositions append (_x buildingPos -1);
} forEach _allBuildings;

// Spawn patrol function
private _fnc_spawnPatrol = {
    params ["_pos", "_radius"];
    private _group = [_pos, East, [selectRandom CivMenArray, selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
    [_group, _pos, _radius] call BIS_fnc_taskPatrol;
    {
        private _uniform = uniform _x;
        _x setUnitLoadout (selectRandom GuerMenArray);
        removeHeadgear _x;
        _x forceAddUniform _uniform;
    } forEach units _group;
    _group
};

// Spawn barricade function
private _fnc_spawnBarricade = {
    params ["_triggerPos", "_minRange", "_maxRange"];
    private _roads = (_triggerPos nearRoads _maxRange) - (_triggerPos nearRoads _minRange);
    if (count _roads == 0) exitWith {};
    
    private _road = selectRandom _roads;
    private _barricade = createVehicle [selectRandom ["Land_Barricade_01_10m_F", "Land_Barricade_01_4m_F"], 
        (_road getRelPos [0, 0]), [], 2, "NONE"];
    
    private _connectedRoad = (roadsConnectedTo _road) select 0;
    if (!isNil "_connectedRoad") then {
        _barricade setDir (_road getDir _connectedRoad);
        _barricade setVectorUp [0,0,1];
    };
    _barricade
};

// Spawn vehicle patrol function
private _fnc_spawnVehiclePatrol = {
    params ["_triggerPos"];
    private _roads = _triggerPos nearRoads 200;
    if (count _roads == 0) exitWith {};
    
    private _spawnRoad = selectRandom _roads;
    private _veh = createVehicle [selectRandom GuerVehArray, (_spawnRoad getRelPos [0, 0]), [], 2, "NONE"];
    private _group = createVehicleCrew _veh;
    private _vehGroup = createGroup East;
    {[_x] join _vehGroup} forEach units _group;
    
    // Create patrol waypoints
    private _patrolRoads = (_triggerPos nearRoads 1500) - (_triggerPos nearRoads 800);
    if (count _patrolRoads > 0) then {
        private _patrolRoad = selectRandom _patrolRoads;
        {
            private _wp = _vehGroup addWaypoint [getPos _x, 0];
            _wp setWaypointType "MOVE";
            _wp setWaypointBehaviour "SAFE";
            _wp setWaypointSpeed "LIMITED";
        } forEach [_patrolRoad, _spawnRoad];
        
        private _cycle = _vehGroup addWaypoint [getPos _spawnRoad, 3];
        _cycle setWaypointType "CYCLE";
        _cycle setWaypointBehaviour "SAFE";
        _cycle setWaypointSpeed "LIMITED";
    };
    [_veh, _vehGroup]
};

// Spawn infantry if enabled
if (INFDIS == 0) then {
    [_triggerPos, 50] call _fnc_spawnPatrol;
    
    if ((dayTime < 21) && (dayTime > 6)) then {
        [_triggerPos, 100] call _fnc_spawnPatrol;
    };
};

// Spawn barricades based on reputation
[_triggerPos, 100, 200] call _fnc_spawnBarricade;
if (_repScore < 7) then { [_triggerPos, 100, 200] call _fnc_spawnBarricade; };
if (_repScore < 5) then { [_triggerPos, 100, 200] call _fnc_spawnBarricade; };

// Spawn vehicle patrols based on chance
if (_chance > 1) then {
    [_triggerPos] call _fnc_spawnVehiclePatrol;
};

// Spawn static weapons and defenses
if (_chance > 0) then {
    if (count _allPositions > 0) then {
        for "_i" from 1 to (1 + floor(random 2)) do {
            private _pos = selectRandom _allPositions;
            private _static = createVehicle [selectRandom ["O_HMG_01_high_F", "O_GMG_01_high_F"], 
                [_pos select 0, _pos select 1, (_pos select 2)], [], 0, "CAN_COLLIDE"];
            private _group = createVehicleCrew _static;
            {
                _x setUnitLoadout (selectRandom GuerMenArray);
                _x disableAI "PATH";
            } forEach units _group;
        };
    };
};

// Spawn supply caches
if (_chance > 1) then {
    for "_i" from 1 to (1 + floor(random 2)) do {
        private _pos = _triggerPos getPos [10 + random 150, random 360];
        private _box = createVehicle ["CargoNet_01_box_F", [_pos select 0, _pos select 1, (_pos select 2) + 5000], [], 2, "NONE"];
        _box allowDamage false;
        if (count _allPositions > 0) then {
            _box setPos (selectRandom _allPositions);
        } else {
            _box setPos _pos;
        };
        sleep 0.1;
        _box allowDamage true;
        clearWeaponCargoGlobal _box;
        clearMagazineCargoGlobal _box;
        clearItemCargoGlobal _box;
        clearBackpackCargoGlobal _box;
        
        // Add random supplies
        {
            _box addItemCargoGlobal [_x, 1 + floor(random 3)];
        } forEach ["FirstAidKit", "Medikit", "ToolKit"];
        
        {
            _box addMagazineCargoGlobal [_x, 2 + floor(random 4)];
        } forEach ["HandGrenade", "MiniGrenade", "SmokeShell"];
    };
};

// Spawn guerrilla forces in buildings
if (_aggrScore > 5 && {count _allPositions > 0}) then {
    for "_i" from 1 to (2 + floor(random 3)) do {
        private _group = [selectRandom _allPositions, East, [selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
        {
            _x disableAI "PATH";
            _x setUnitPos "UP";
        } forEach units _group;
    };
};

// Create trigger for garrison
private _trg = createTrigger ["EmptyDetector", _triggerPos, false];
_trg setTriggerArea [150, 150, 0, false, 20];
_trg setTriggerTimeout [10, 10, 10, true];
_trg setTriggerActivation ["WEST SEIZED","PRESENT", false];
_trg setTriggerStatements [
    "this && {(alive _x) && ((side _x) == EAST) && (position _x inArea thisTrigger)} count allUnits < 3",
    "[] call FLO_fnc_notification; [] execVM 'Scripts\ReputationPlus.sqf'; [] execVM 'Scripts\ReputationPlus.sqf'; [] execVM 'Scripts\ReputationPlus.sqf'; [30] call FLO_fnc_addReward; [thisTrigger] execVM 'Scripts\VehiInsert_CSAT.sqf';",
    ""
];

// Call INTLitems script
[_thisTownTrigger, 200] execVM "Scripts\INTLitems.sqf";
