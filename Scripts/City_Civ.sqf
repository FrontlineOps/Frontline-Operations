params [["_thisCityCivTrigger", objNull, [objNull]]];

private _chance = selectRandom [1, 2, 3];
private _REPSCORE = parseNumber (markerText ((allMapMarkers select {markerColor _x == "Color4_FD_F"}) # 0));
private _triggerPos = getPos _thisCityCivTrigger;

// Setup building event handlers
private _allBuildings = nearestObjects [_triggerPos, ["HOUSE"], 150];
{
    _x removeAllEventHandlers "Killed";
    _x addEventHandler ["Killed", {
        [playerSide, "HQ"] commandChat "WATCH for CIVILIAN PROPERTIES Corporal !";
        [] execVM "Scripts\ReputationMinus.sqf";
        [] execVM "Scripts\Civ_Relations.sqf";
    }];
} forEach _allBuildings;

// Generator setup
private _houses = nearestObjects [_triggerPos, ["HOUSE"], 300];
private _otherHouses = nearestObjects [_triggerPos, ["HOUSE"], 50];
private _powerHouses = _houses - _otherHouses;
private _allPowerHouses = _powerHouses select {count (_x buildingPos -1) > 2};

if (count _allPowerHouses > 0) then {
    private _powerHouse = selectRandom _allPowerHouses;
    private _dir = getDirVisual _powerHouse;
    private _buildingPos = selectRandom (_powerHouse buildingPos -1);
    
    private _generator = createVehicle ["Land_PowerGenerator_F", _buildingPos, [], 0, "FLY"];
    _generator addEventHandler ["Killed", {
        [] execVM "Scripts\ReputationMinus.sqf";
        execVM "Scripts\Civ_Relations.sqf";
        [(_this select 0)] execVM 'Scripts\Sabotage.sqf';
    }];
    
    _generator allowDamage false;
    _generator setPos _buildingPos;
    _generator setDir _dir;
    sleep 3;
    _generator allowDamage true;
    
    createVehicle ["Land_TTowerSmall_2_F", getPos _powerHouse, [], 0, "NONE"];
    
    private _markerName = format ["PowerHouseMark_%1", getPos _powerHouse];
    private _powerMarker = createMarker [_markerName, getPos _powerHouse];
    _powerMarker setMarkerType "loc_Lighthouse";
    _powerMarker setMarkerColor "colorOPFOR";
    _powerMarker setMarkerSize [0.6, 0.6];
    _powerMarker setMarkerAlpha 0.001;
};

// Optimized vehicle spawning function
private _fnc_spawnVehicle = {
    params ["_road", "_vehType", "_addCrew"];
    
    private _pos = _road getRelPos [6, 0];
    private _veh = createVehicle [_vehType, [_pos select 0, _pos select 1, (_pos select 2) + 10], [], 0, "CAN_COLLIDE"];
    private _nextRoad = (roadsConnectedTo _road) select 0;
    _veh setDir (_road getDir _nextRoad);
    
    if (_addCrew) then {
        private _group = createVehicleCrew _veh;
        [_group, _road] call {
            params ["_group", "_startRoad"];
            private _wp0 = _group addWaypoint [getPos (_startRoad nearRoads 5000 select 0), 0];
            _wp0 setWaypointType "MOVE";
            _wp0 setWaypointBehaviour "SAFE";
            _wp0 setWaypointSpeed "LIMITED";
            
            private _wp1 = _group addWaypoint [getPos (_startRoad nearRoads 5000 select 0), 0];
            _wp1 setWaypointType "MOVE";
            
            private _wpCycle = _group addWaypoint [getPos (_startRoad nearRoads 5000 select 0), 3];
            _wpCycle setWaypointType "CYCLE";
        };
    };
    
    _veh
};

// Spawn vehicles based on chance
if (_chance > 0) then {
    for "_i" from 1 to 3 do {
        private _nearRoad = selectRandom ((_triggerPos nearRoads [300, 2000] select _i min 1));
        if (!isNull _nearRoad) then {
            [_nearRoad, selectRandom CivVehArray, false] call _fnc_spawnVehicle;
        };
    };
};

if (_chance > 1) then {
    for "_i" from 1 to 3 do {
        private _nearRoad = selectRandom ((_triggerPos nearRoads [300, 2000] select _i min 1));
        if (!isNull _nearRoad) then {
            private _veh = [_nearRoad, selectRandom CivVehArray, true] call _fnc_spawnVehicle;
            
            if (_REPSCORE < 7) then {
                private _trg = createTrigger ["EmptyDetector", getPos _veh];
                _trg setTriggerArea [15, 15, 0, false, 6];
                _trg setTriggerActivation ["WEST", "PRESENT", false];
                _trg setTriggerStatements [
                    "this or (vehicle player) inArea thisTrigger",
                    "[thisTrigger, 'Sh_155mm_AMOS', 0, 1, 0] spawn BIS_fnc_fireSupportVirtual;",
                    ""
                ];
                _veh addEventHandler ["Killed", {
                    params ["_unit"];
                    [_unit, "Sh_155mm_AMOS", 0, 1, 0] spawn BIS_fnc_fireSupportVirtual;
                }];
                _trg attachTo [_veh, [0, 0, 0]];
            };
        };
    };
};

if (_chance > 2) then {
    for "_i" from 1 to 3 do {
        private _nearRoad = selectRandom ((_triggerPos nearRoads [300, 2000] select _i min 1));
        if (!isNull _nearRoad) then {
            private _veh = [_nearRoad, selectRandom CivVehArray, true] call _fnc_spawnVehicle;
            
            if (_REPSCORE < 7) then {
                private _trg = createTrigger ["EmptyDetector", getPos _veh];
                _trg setTriggerArea [15, 15, 0, false, 6];
                _trg setTriggerActivation ["WEST", "PRESENT", false];
                _trg setTriggerStatements [
                    "this or (vehicle player) inArea thisTrigger",
                    "[thisTrigger, 'Sh_155mm_AMOS', 0, 1, 0] spawn BIS_fnc_fireSupportVirtual;",
                    ""
                ];
                _veh addEventHandler ["Killed", {
                    params ["_unit"];
                    [_unit, "Sh_155mm_AMOS", 0, 1, 0] spawn BIS_fnc_fireSupportVirtual;
                }];
                _trg attachTo [_veh, [0, 0, 0]];
            };
        };
    };
};

// Function to spawn civilians
private _fnc_spawnCivilians = {
    params ["_cityCivTrigger", "_reputationScore"];
    
    private _buildings = nearestObjects [_triggerPos, ["HOUSE"], 200];
    private _allPositions = [];
    {_allPositions append (_x buildingPos -1)} forEach _buildings;
    
    if (count _allPositions == 0) exitWith {};
    
    // Static civilians
    for "_i" from 1 to 6 do {
        private _group = [selectRandom _allPositions, civilian, [selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
        private _unit = (units _group) select 0;
        _unit disableAI "all";
        _unit enableAI "ANIM";
        
        if (_i <= 4 && {_reputationScore < 7 || markerColor ([allMapMarkers, _cityCivTrigger] call BIS_fnc_nearestPosition) == "colorOPFOR"}) then {
            private _building = (nearestObjects [getPos _unit, ["HOUSE"], 30]) select 0;
            if (!isNull _building) then {
                private _pos = selectRandom (_building buildingPos -1);
                private _holder = createVehicle ["groundweaponholder", _pos, [], 0, "CAN_COLLIDE"];
                _holder addItemCargo [selectRandom G_stuff, 1];
                
                if (random 1 > 0.5) then {
                    _unit setUnitTrait ["engineer", true];
                    private _nearVeh = (nearestObjects [getPos _unit, ["LandVehicle"], 50]) select 0;
                    if (!isNull _nearVeh) then {
                        _nearVeh addItemCargo [selectRandom G_stuff, 1];
                    };
                };
            };
        };
    };
    
    // Patrolling civilians
    for "_i" from 1 to 5 do {
        private _group = [selectRandom _allPositions, civilian, [selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
        private _unit = (units _group) select 0;
        {_unit enableAI _x} forEach ["MOVE", "ANIM", "PATH", "TEAMSWITCH"];
        [_group, _cityCivTrigger getPos [random 100, random 350], 100 + random 250] call BIS_fnc_taskPatrol;
    };
};

// Function to spawn guerrilla forces
private _fnc_spawnGuerrillaForces = {
    params ["_cityCivTrigger", "_reputationScore"];
    
    private _buildings = nearestObjects [_triggerPos, ["HOUSE"], 200];
    private _positions = [];
    {_positions append (_x buildingPos -1)} forEach _buildings;
    
    if (count _positions == 0) exitWith {};
    
    // First wave of guerrillas
    if (_reputationScore > 10 || _reputationScore < 7) then {
        for "_i" from 1 to 4 do {
            private _group = [selectRandom _positions, independent, [selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
            if (_i > 1) then {
                [_group, _cityCivTrigger getPos [random 100, random 350], 90] call BIS_fnc_taskPatrol;
            };
        };
    };
    
    // Second wave of guerrillas
    if (_reputationScore > 12 || _reputationScore < 5) then {
        for "_i" from 1 to 4 do {
            private _group = [selectRandom _positions, independent, [selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
            if (_i > 1) then {
                [_group, _cityCivTrigger getPos [random 100, random 350], 90] call BIS_fnc_taskPatrol;
            };
        };
    };
};

// Function to place IEDs
private _fnc_placeIEDs = {
    params ["_cityCivTrigger", "_reputationScore"];
    if (_reputationScore >= 7) exitWith {};
    
    private _iedCount = [4, 8] select (_reputationScore < 5);
    for "_i" from 1 to _iedCount do {
        private _nearRoad = selectRandom ((_triggerPos nearRoads 100));
        if (isNull _nearRoad) continue;
        
        private _pos = _nearRoad getRelPos [8, selectRandom [0, 180]];
        private _clutter = createVehicle [selectRandom _Clutters, _pos, [], random 3, "CAN_COLLIDE"];
        _clutter setVectorUp [0,0,1];
        
        createMine [selectRandom _IEDs, _pos, [], 0];
        
        private _trg = createTrigger ["EmptyDetector", _pos];
        _trg setTriggerArea [10, 10, 0, false, 4];
        _trg setTriggerActivation ["WEST", "PRESENT", false];
        _trg setTriggerStatements [
            "this && stance player != 'PRONE'",
            "[thisTrigger, 'Sh_82mm_AMOS', 0, 1, 0, false, 0, 10, ['']] spawn BIS_fnc_fireSupportVirtual;",
            ""
        ];
    };
};

// Function to handle day/night cycle
private _fnc_handleDayNightCycle = {
    private _isDay = dayTime < 19 && dayTime > 7;
    {
        _x hideObjectGlobal (!_isDay);
        _x enableSimulationGlobal _isDay;
    } forEach (allUnits select {side _x == civilian && _x checkAIFeature "PATH"});
};

// Main execution
[_thisCityCivTrigger, _REPSCORE] call _fnc_spawnCivilians;

// Check for nearby military installations
private _militaryMarkers = allMapMarkers select {
    markerType _x in [
        "n_installation", "o_installation", "o_antiair",
        "o_service", "o_armor", "loc_Power", "o_recon",
        "o_support", "n_support", "loc_Ruin"
    ]
};

private _nearestMilitary = [_militaryMarkers, _thisCityCivTrigger] call BIS_fnc_nearestPosition;
if ((_nearestMilitary distance _thisCityCivTrigger) < 1500) then {
    [_thisCityCivTrigger, _REPSCORE] call _fnc_spawnGuerrillaForces;
    [_thisCityCivTrigger, _REPSCORE] call _fnc_placeIEDs;
};

// Add lighting to buildings
{
    createVehicle ["Land_Camping_Light_F", [
        (getPos _x) select 0,
        (getPos _x) select 1,
        ((getPos _x) select 2) + 1
    ], [], 0, "NONE"];
} forEach (nearestObjects [_triggerPos, ["HOUSE"], 20] select {count (_x buildingPos -1) > 7});

// Handle day/night cycle
call _fnc_handleDayNightCycle;

sleep 5;
execVM "Scripts\Civ_Relations.sqf";