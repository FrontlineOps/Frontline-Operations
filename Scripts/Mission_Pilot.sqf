params [["_thisPilotsTrigger", objNull]];

// Get aggression score
private _AGGRSCORE = FLO_DifficultyHandle get "value";

// Initialize configuration
private _config = createHashMapFromArray [
    ["patrolRadius", 300],
    ["patrolRadiusLarge", 1000],
    ["guardRadius", [30, 50]],
    ["houseSearchRadius", 7000],
    ["exclusionRadius", 400],
    ["animations", [
        "Acts_AidlPsitMstpSsurWnonDnon01",
        "Acts_AidlPsitMstpSsurWnonDnon02", 
        "Acts_AidlPsitMstpSsurWnonDnon03",
        "Acts_AidlPsitMstpSsurWnonDnon04",
        "Acts_AidlPsitMstpSsurWnonDnon05"
    ]]
];

// Helper function to spawn patrol group
private _fnc_spawnPatrol = {
    params ["_pos", "_radius", "_unitCount"];
    private _units = [];
    for "_i" from 1 to _unitCount do {
        _units pushBack (selectRandom East_Units);
    };
    private _group = [_pos, East, _units] call BIS_fnc_spawnGroup;
    [_group, _pos, _radius] call BIS_fnc_taskPatrol;
    _group deleteGroupWhenEmpty true;
    _group
};

// Helper function to spawn guard
private _fnc_spawnGuard = {
    params ["_pos", "_disablePath"];
    private _safePos = [_pos, _config get "guardRadius" select 0, _config get "guardRadius" select 1, 5, 1, 0] call BIS_fnc_findSafePos;
    private _group = [_safePos, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
    if (_disablePath) then {
        ((units _group) select 0) disableAI "PATH";
    };
    _group deleteGroupWhenEmpty true;
    _group
};

// Find suitable house
private _excludedHouses = [];
{
    private _houses = nearestObjects [getMarkerPos _x, ["HOUSE"], _config get "exclusionRadius"];
    _excludedHouses append _houses;
} forEach (allMapMarkers select {
    markerType _x in ["b_installation", "o_installation", "n_installation", "o_support", "n_support", "loc_Power", "loc_Ruin"]
});

private _suitableHouses = (nearestObjects [_thisPilotsTrigger, ["HOUSE"], _config get "houseSearchRadius"] select {
    count (_x buildingPos -1) > 2
}) - _excludedHouses;

private _HQB = _suitableHouses select 0;
private _dir = getDirVisual _HQB;

// Spawn initial setup
["Intel_CS_01", selectRandom (_HQB buildingPos -1), [0,0,0], _dir, false, false, true] call LARs_fnc_spawnComp;

// Spawn initial guards
for "_i" from 1 to 4 do {
    private _group = [selectRandom (_HQB buildingPos -1), East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
    if (_i <= 2) then {
        ((units _group) select 0) disableAI "PATH";
    };
    _group deleteGroupWhenEmpty true;
};

// Spawn main patrol
[getPos _HQB, _config get "patrolRadius", 4] call _fnc_spawnPatrol;

// Spawn additional patrols based on aggression
if (_AGGRSCORE > 10) then {
    [getPos _HQB, _config get "patrolRadius", 2] call _fnc_spawnPatrol;
};

// Spawn guards
[getPos _HQB, true] call _fnc_spawnGuard;
[getPos _HQB, false] call _fnc_spawnGuard;

if (_AGGRSCORE > 5) then {
    [getPos _HQB, true] call _fnc_spawnGuard;
};

if (_AGGRSCORE > 10) then {
    [getPos _HQB, false] call _fnc_spawnGuard;
};

// Spawn additional patrols
if (_AGGRSCORE > 5) then {
    private _patrolPos = _HQB getPos [300 + random 1000, random 360];
    [_patrolPos, _config get "patrolRadius", 2] call _fnc_spawnPatrol;
};

if (_AGGRSCORE > 10) then {
    private _patrolPos = _HQB getPos [300 + random 1000, random 360];
    [_patrolPos, _config get "patrolRadiusLarge", 2] call _fnc_spawnPatrol;
};

sleep 2;