params [["_thisCapitalCivTrigger", objNull, [objNull]]];

// Initialize variables
private _triggerPos = getPos _thisCapitalCivTrigger;
private _chance = selectRandom [1, 2, 3];
private _REPSCORE = parseNumber (markerText ((allMapMarkers select {markerColor _x == "Color4_FD_F"}) # 0));

// Function to setup building event handlers
private _fnc_setupBuildingHandlers = {
    params ["_triggerPos"];
    private _allBuildings = nearestObjects [_triggerPos, ["HOUSE"], 300];
    {
        _x removeAllEventHandlers "Killed";
        _x addEventHandler ["Killed", {
            [playerSide, "HQ"] commandChat "WATCH for CIVILIAN PROPERTIES Corporal !";
            [] execVM "Scripts\ReputationMinus.sqf";
            [] execVM "Scripts\Civ_Relations.sqf";
        }];
    } forEach _allBuildings;
};

// Function to setup power generator
private _fnc_setupGenerator = {
    params ["_triggerPos"];
    
    private _houses = nearestObjects [_triggerPos, ["HOUSE"], 400];
    private _otherHouses = nearestObjects [_triggerPos, ["HOUSE"], 100];
    private _powerHouses = _houses - _otherHouses;
    private _allPowerHouses = _powerHouses select {count (_x buildingPos -1) > 2};
    
    if (count _allPowerHouses > 0) then {
        private _powerHouse = selectRandom _allPowerHouses;
        private _dir = getDirVisual _powerHouse;
        private _buildingPos = selectRandom (_powerHouse buildingPos -1);
        
        private _generator = createVehicle ["Land_PowerGenerator_F", _buildingPos, [], 0, "FLY"];
        _generator addEventHandler ["Killed", {
            [
                [
                    ["Power Generator Sabotaged", "<t color='#1AA3FF' align = 'center' shadow = '1' size = '1' font='PuristaBold'>%1</t><br/>"]
                ]
            ] spawn BIS_fnc_typeText;
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
        private _marker = createMarker [_markerName, getPos _powerHouse];
        _marker setMarkerType "loc_Lighthouse";
        _marker setMarkerColor "colorOPFOR";
        _marker setMarkerSize [0.6, 0.6];
        _marker setMarkerAlpha 0.001;
    };
};

// Function to spawn a single vehicle
private _fnc_spawnVehicle = {
    params ["_road", "_addCrew", "_REPSCORE"];
    
    private _pos = _road getRelPos [6, 0];
    private _veh = createVehicle [selectRandom CivVehArray, [_pos select 0, _pos select 1, (_pos select 2) + 10], [], 0, "CAN_COLLIDE"];
    private _nextRoad = (roadsConnectedTo _road) select 0;
    private _dir = _road getDir _nextRoad;
    _veh setDir _dir;
    
    if (_addCrew) then {
        private _group = createVehicleCrew _veh;
        
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
        
        sleep 3;
        private _nearRoad0 = selectRandom (_road nearRoads 5000);
        private _wp0 = _group addWaypoint [getPos _nearRoad0, 0];
        _wp0 setWaypointType "MOVE";
        _wp0 setWaypointBehaviour "SAFE";
        _wp0 setWaypointSpeed "LIMITED";
        
        private _nearRoad1 = selectRandom (_nearRoad0 nearRoads 5000);
        private _wp1 = _group addWaypoint [getPos _nearRoad1, 0];
        _wp1 setWaypointType "MOVE";
        _wp1 setWaypointBehaviour "SAFE";
        _wp1 setWaypointSpeed "LIMITED";
        
        private _wpCycle = _group addWaypoint [getPos _nearRoad1, 7];
        _wpCycle setWaypointType "CYCLE";
    };
    
    _veh
};

// Function to spawn civilians and guerrillas
private _fnc_spawnUnit = {
    params ["_pos", "_side", "_units", ["_enablePatrol", false]];
    
    private _group = [_pos, _side, _units] call BIS_fnc_spawnGroup;
    private _unit = leader _group;
    
    if (_side == civilian) then {
        _unit disableAI "all";
        _unit enableAI "ANIM";
        
        if (_enablePatrol) then {
            {_unit enableAI _x} forEach ["MOVE", "PATH", "TEAMSWITCH"];
            [_group, _triggerPos getPos [random 200, random 350], 100 + random 500] call BIS_fnc_taskPatrol;
        };
    } else {
        [_group, _triggerPos getPos [random 100, random 350], 90] call BIS_fnc_taskPatrol;
    };
    
    _group
};

// Function to setup weapon cache
private _fnc_setupWeaponCache = {
    params ["_unit"];
    
    private _building = (nearestObjects [getPos _unit, ["HOUSE"], 30]) select 0;
    if (isNull _building) exitWith {};
    
    private _pos = selectRandom (_building buildingPos -1);
    private _barrel = createVehicle ["Land_BarrelEmpty_F", [_pos select 0, _pos select 1, (_pos select 2) + 0.1], [], 0, "can_Collide"];
    sleep 0.5;
    private _holder = createVehicle ["groundweaponholder", [_pos select 0, _pos select 1, (getPosATL _barrel select 2)], [], 0, "can_Collide"];
    deleteVehicle _barrel;
    _holder addItemCargo [selectRandom G_stuff, 1];
    
    private _chance = selectRandom [0, 1, 2];
    if (_chance > 0) then {
        _unit setUnitTrait ["engineer", true];
    };
    if (_chance > 1) then {
        private _nearVeh = (nearestObjects [getPos _unit, ["LandVehicle"], 50]) select 0;
        if (!isNull _nearVeh) then {
            _nearVeh addItemCargo [selectRandom G_stuff, 1];
        };
    };
};

// Function to setup IEDs
private _fnc_setupIEDs = {
    params ["_triggerPos", "_REPSCORE"];
    
    if (_REPSCORE < 7) then {
        private _iedCount = if (_REPSCORE < 5) then {6} else {3};
        
        for "_i" from 1 to _iedCount do {
            private _nearRoad = selectRandom (_triggerPos nearRoads 100);
            if (!isNull _nearRoad) then {
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
    };
};

// Function to setup building lights
private _fnc_setupBuildingLights = {
    params ["_triggerPos"];
    
    private _buildings = nearestObjects [_triggerPos, ["HOUSE"], 30] select {count (_x buildingPos -1) > 7};
    {
        createVehicle ["Land_Camping_Light_F", [
            (getPos _x) select 0,
            (getPos _x) select 1,
            ((getPos _x) select 2) + 1
        ], [], 0, "NONE"];
    } forEach _buildings;
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
[_triggerPos] call _fnc_setupBuildingHandlers;
[_triggerPos] call _fnc_setupGenerator;

// Spawn static vehicles based on chance
if (_chance > 0) then {
    for "_i" from 1 to 4 do {
        private _nearRoad = selectRandom (_triggerPos nearRoads 500);
        if (!isNull _nearRoad) then {
            [_nearRoad, false, _REPSCORE] call _fnc_spawnVehicle;
        };
    };
    private _farRoad = selectRandom (_triggerPos nearRoads 3000);
    if (!isNull _farRoad) then {
        [_farRoad, false, _REPSCORE] call _fnc_spawnVehicle;
    };
};

if (_chance > 1) then {
    for "_i" from 1 to 4 do {
        private _nearRoad = selectRandom (_triggerPos nearRoads 500);
        if (!isNull _nearRoad) then {
            [_nearRoad, false, _REPSCORE] call _fnc_spawnVehicle;
        };
    };
    private _farRoad = selectRandom (_triggerPos nearRoads 3000);
    if (!isNull _farRoad) then {
        [_farRoad, false, _REPSCORE] call _fnc_spawnVehicle;
    };
};

if (_chance > 2) then {
    for "_i" from 1 to 4 do {
        private _nearRoad = selectRandom (_triggerPos nearRoads 500);
        if (!isNull _nearRoad) then {
            [_nearRoad, false, _REPSCORE] call _fnc_spawnVehicle;
        };
    };
    private _farRoad = selectRandom (_triggerPos nearRoads 2000);
    if (!isNull _farRoad) then {
        [_farRoad, false, _REPSCORE] call _fnc_spawnVehicle;
    };
};

// Spawn vehicles with crew
if (_chance > 0) then {
    for "_i" from 1 to 3 do {
        private _nearRoad = selectRandom (_triggerPos nearRoads 500);
        if (!isNull _nearRoad) then {
            [_nearRoad, true, _REPSCORE] call _fnc_spawnVehicle;
        };
    };
};

if (_chance > 1) then {
    private _nearRoad = selectRandom (_triggerPos nearRoads 500);
    if (!isNull _nearRoad) then {
        [_nearRoad, true, _REPSCORE] call _fnc_spawnVehicle;
    };
};

if (_chance > 2) then {
    private _nearRoad = selectRandom (_triggerPos nearRoads 500);
    if (!isNull _nearRoad) then {
        [_nearRoad, true, _REPSCORE] call _fnc_spawnVehicle;
    };
};

// Get building positions for unit spawning
private _allBuildings = nearestObjects [_triggerPos, ["HOUSE"], 300];
private _allPositions = [];
{_allPositions append (_x buildingPos -1)} forEach _allBuildings;

// Spawn static civilians
for "_i" from 1 to 10 do {
    private _group = [selectRandom _allPositions, civilian, [selectRandom CivMenArray], false] call _fnc_spawnUnit;
    
    if (_i <= 5 && (_REPSCORE < 7 || markerColor ([allMapMarkers, _thisCapitalCivTrigger] call BIS_fnc_nearestPosition) == "colorOPFOR")) then {
        [leader _group] call _fnc_setupWeaponCache;
    };
};

// Spawn patrolling civilians
for "_i" from 1 to 8 do {
    [selectRandom _allPositions, civilian, [selectRandom CivMenArray], true] call _fnc_spawnUnit;
};

// Spawn guerrillas based on reputation
if (_REPSCORE > 10 || _REPSCORE < 7) then {
    for "_i" from 1 to 5 do {
        [selectRandom _allPositions, independent, [selectRandom GuerMenArray, selectRandom GuerMenArray]] call _fnc_spawnUnit;
    };
};

if (_REPSCORE > 12 || _REPSCORE < 5) then {
    for "_i" from 1 to 5 do {
        [selectRandom _allPositions, independent, [selectRandom GuerMenArray, selectRandom GuerMenArray]] call _fnc_spawnUnit;
    };
};

// Setup IEDs and building lights
[_triggerPos, _REPSCORE] call _fnc_setupIEDs;
[_triggerPos] call _fnc_setupBuildingLights;
call _fnc_handleDayNightCycle;

sleep 5;
execVM "Scripts\Civ_Relations.sqf";