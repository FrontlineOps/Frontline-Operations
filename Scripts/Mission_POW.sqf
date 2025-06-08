private _thisPOWTrigger = _this select 0;

// Get aggression score from marker
private _AGGRSCORE = FLO_DifficultyHandle get "value";

// Wait for barracks to spawn
sleep 15;
waitUntil {
    count (nearestObjects [_thisPOWTrigger, [
        "Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F",
        "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F",
        "Land_vn_barracks_01_camo_f", "Land_Barracks_01_camo_F"
    ], 400]) > 0
};

_Position = nearestObjects [_thisPOWTrigger, [
    "Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F",
    "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F",
    "Land_vn_barracks_01_camo_f", "Land_Barracks_01_camo_F"
], 400] select 0;

// Spawn officer with intel action
_Pos = selectRandom (_Position buildingPos -1);
G = [_Pos, East, [selectRandom East_Units_Officers]] call BIS_fnc_spawnGroup;
_OFC = (units G) select 0;
_OFC disableAI "PATH";

[
    _OFC,
    "Search Officer",
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa",
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa",
    "(_this distance _target)<2",
    "(_this distance _target)<2",
    {playSound3D ["a3\missions_f_oldman\data\sound\intel_body\1sec\intel_body_1sec_02.wss", (_this select 0)]},
    {},
    {[] call FLO_fnc_militaryIntel},
    {},
    [],
    3,
    0,
    true,
    false
] remoteExec ["BIS_fnc_holdActionAdd", 0, _OFC];

// Spawn garrison units
private _spawnGarrison = {
    params ["_pos", "_disablePath"];
    G = [_pos, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
    if (_disablePath) then {((units G) select 0) disableAI "PATH"};
    G deleteGroupWhenEmpty true;
};

// Garrison
[selectRandom (_Position buildingPos -1), true] call _spawnGarrison;
[selectRandom (_Position buildingPos -1), false] call _spawnGarrison;
if (_AGGRSCORE > 5) then {
    [selectRandom (_Position buildingPos -1), true] call _spawnGarrison;
    [selectRandom (_Position buildingPos -1), false] call _spawnGarrison;
};
if (_AGGRSCORE > 10) then {
    [selectRandom (_Position buildingPos -1), true] call _spawnGarrison;
    [selectRandom (_Position buildingPos -1), false] call _spawnGarrison;
};

// Spawn guards in buildings
private _allBuildings = nearestObjects [(getpos _thisPOWTrigger), [
    "House", "Land_MilOffices_V1_F", "Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V2_F",
    "Land_Cargo_Tower_V1_F", "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V1_F",
    "Land_Cargo_House_V3_F", "Land_Cargo_House_V1_F"
], 300];

_allPositions = [];
_allBuildings apply {_allPositions append (_x buildingPos -1)};

// Spawn intel
["Intel_01", selectRandom _allPositions, [0,0,0], _dir, false, false, true] call LARs_fnc_spawnComp;

// Spawn building guards
private _spawnBuildingGuard = {
    params ["_disablePath"];
    G = [selectRandom _allPositions, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
    if (_disablePath) then {((units G) select 0) disableAI "PATH"};
    G deleteGroupWhenEmpty true;
};

// Building guards
for "_i" from 1 to 4 do {
    [_i % 2 == 0] call _spawnBuildingGuard;
};
if (_AGGRSCORE > 5) then {
    for "_i" from 1 to 2 do {
        [_i % 2 == 0] call _spawnBuildingGuard;
    };
};
if (_AGGRSCORE > 10) then {
    for "_i" from 1 to 2 do {
        [_i % 2 == 0] call _spawnBuildingGuard;
    };
};

// Spawn patrol groups
private _spawnPatrol = {
    params ["_angle", "_radius"];
    PRL = [(getPos _thisPOWTrigger) getPos [_radius, _angle], East, [
        selectRandom East_Units, selectRandom East_Units, selectRandom East_Units,
        selectRandom East_Units, selectRandom East_Units, selectRandom East_Units
    ]] call BIS_fnc_spawnGroup;
    [PRL, getpos _thisPOWTrigger, _radius] call BIS_fnc_taskPatrol;
    PRL deleteGroupWhenEmpty true;
};

// Patrols
[50, 50] call _spawnPatrol;
[50, 100] call _spawnPatrol;
if (_AGGRSCORE > 5) then {
    [180, 200] call _spawnPatrol;
};
if (_AGGRSCORE > 10) then {
    [270, 200] call _spawnPatrol;
};

// Spawn vehicles
private _spawnVehicle = {
    if (count [(getpos _thisPOWTrigger) nearRoads 70] > 0) then {
        _nearRoad = selectRandom ((getpos _thisPOWTrigger) nearRoads 70);
        _V = createVehicle [selectRandom East_Ground_Vehicles_Ambient, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"];
        _nextRoad = (roadsConnectedTo _nearRoad) select 0;
        _V setDir (_nearRoad getDir _nextRoad);
    };
};

// Vehicles
[] call _spawnVehicle;
if (_AGGRSCORE > 5) then {[] call _spawnVehicle};

// Spawn intel items
[_thisPOWTrigger, 200] execVM "Scripts\INTLitems.sqf";