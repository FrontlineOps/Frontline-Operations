private _thisBaseTrigger = _this select 0;
private _AGGRSCORE = FLO_DifficultyHandle get "value";  

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
sleep 15; 

[_thisBaseTrigger] execVM "Scripts\HMGspawn.sqf" ; 

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _helipads = FLO_configCache get "helipads";
private _nearbyHelipads = nearestObjects [getPos _thisBaseTrigger, _helipads, 500];

if (count _nearbyHelipads > 0) then {
    private _helipad = _nearbyHelipads select 0;
    private _helipadPos = getPos _helipad;
    private _helipadDir = getDir _helipad;
    
    private _heli = createVehicle [
        selectRandom (FLO_configCache get "vehicles" select 5),
        _helipadPos,
        [],
        0,
        "NONE"
    ];
    _heli setVehicleLock "LOCKED";
    _heli setDir _helipadDir;
    
    _heli addEventHandler ["Killed", {
        ["ScoreAdded", ["Enemy Aircraft Sabotaged", 20]] remoteExec ["BIS_fnc_showNotification", 0];
        [20] call FLO_fnc_addReward;
        playMusic "EventTrack01_F_Curator";
        execVM 'Scripts\HeliDis.sqf';
    }];
};

private _hangarTypes = ["Land_Ss_hangar", "Land_Ss_hangard", "Land_Mil_hangar_EP1", "Land_Airport_01_hangar_F", "Land_TentHangar_V1_F", "Land_Hangar_F"];
private _hangars = nearestObjects [getPos _thisBaseTrigger, _hangarTypes, 500];

if (count _hangars > 0) then {
    private _hangar = _hangars select 0;
    private _hangarPos = getPos _hangar;
    private _hangarDir = getDir _hangar;
    
    // Spawn jet
    private _jet = createVehicle [
        selectRandom (FLO_configCache get "vehicles" select 6),
        [0, 0, 100],
        [],
        0,
        "NONE"
    ];
    _jet setVehicleLock "LOCKED";
    _jet setDir _hangarDir;
    _jet setPos _hangarPos;
    
    // Spawn patrol group
    private _patrolPos = _hangarPos getPos [15 + random 15, random 360];
    private _patrolGroup = [
        _patrolPos,
        East,
        [
            selectRandom (FLO_configCache get "units"),
            selectRandom (FLO_configCache get "units"),
            selectRandom (FLO_configCache get "units")
        ]
    ] call BIS_fnc_spawnGroup;
    
    [_patrolGroup, _patrolPos, 50] call BIS_fnc_taskPatrol;
    
    // Add kill handler
    _jet addEventHandler ["Killed", {
        ["ScoreAdded", ["Enemy Aircraft Sabotaged", 20]] remoteExec ["BIS_fnc_showNotification", 0];
        [20] call FLO_fnc_addReward;
        playMusic "EventTrack01_F_Curator";
    }];
};

private _basePos = getPos _thisBaseTrigger;
private _nearbyRoads = _basePos nearRoads 300;
private _vehicleCount = 4;

for "_i" from 1 to _vehicleCount do {
    private _road = selectRandom _nearbyRoads;
    private _connectedRoads = roadsConnectedTo _road;
    
    if (count _connectedRoads > 0) then {
        private _nextRoad = _connectedRoads select 0;
        private _dir = _road getDir _nextRoad;
        private _pos = _road getRelPos [0, 0];
        
        private _vehicle = createVehicle [
            selectRandom East_Ground_Vehicles_Ambient,
            _pos,
            [],
            4,
            "NONE"
        ];
        _vehicle setDir _dir;
    };
};

private _poss = [(getpos _thisBaseTrigger), 10, 20, 4, 0.1 , 0] call BIS_fnc_findSafePos;
private _VLAMP = createVehicle [ "Land_LampAirport_F", _poss, [], 5, "NONE"];

private _allBuildings = nearestObjects [(getpos _thisBaseTrigger), (FLO_configCache get "buildings"), 300];
private _baseIntelCount = 6 + (if (_AGGRSCORE > 5) then {2} else {0}) + (if (_AGGRSCORE > 10) then {2} else {0});

for "_i" from 1 to _baseIntelCount do {
    private _building = selectRandom _allBuildings;
    private _pos = selectRandom (_building buildingPos -1);
    private _dir = getDirVisual _building;
    
    ["Intel_01", _pos, [0,0,0], _dir, false, false, true] call LARs_fnc_spawnComp;
};

private _heavyGuns = nearestObjects [getPos _thisBaseTrigger, ["O_G_HMG_02_high_F", "O_G_Mortar_01_F"], 300];

{
    private _crewGroup = createVehicleCrew _x;
    private _vehicleGroup = createGroup [East, true];
    (units _crewGroup) joinSilent _vehicleGroup;
    {
        _x setUnitLoadout (selectRandom East_Units);
    } forEach units _vehicleGroup;
} forEach _heavyGuns;

sleep 10;
 
private _trg = createTrigger ["EmptyDetector", getPos _thisBaseTrigger, false];
_trg setTriggerArea [220, 220, 0, false, 200];
_trg setTriggerTimeout [10, 10, 10, true];
_trg setTriggerActivation ["WEST SEIZED", "PRESENT", true];
_trg setTriggerStatements [
    "this",
    "
        [parseText '<t color=""#1AA3FF"" font=""PuristaBold"" align = ""right"" shadow = ""1"" size=""2"">SITREP</t><br /><t color=""#959393"" align = ""right"" shadow = ""1"" size=""0.8"">Friendly Forces Dominating the Battle,</t><br /><t color=""#959393"" align = ""right"" shadow = ""1"" size=""0.8"">Keep Up the Fight, We will Capture and Secure the Outpost,</t>', [0, 0.5, 1, 1], nil, 5, 1.7, 0] remoteExec ['BIS_fnc_textTiles', 0];
        _allMarks = allMapMarkers select {markerType _x == 'n_support'};
        _FOBMrk = [_allMarks, thisTrigger] call BIS_fnc_nearestPosition;
        _FOBMrk setMarkerColor 'ColorGrey';
        _attackingAtGrid = mapGridPosition getMarkerPos _FOBMrk;
        [[west,'HQ'], 'Friendly Forces Dominating the Battle at grid ' + _attackingAtGrid] remoteExec ['sideChat', 0];
        [thisTrigger] execVM 'Scripts\Objectives\Outpost_CSAT_CAPTURE_West.sqf';
    ",
    "
        _allMarks = allMapMarkers select {markerType _x == 'n_support'};
        _FOBMrk = [_allMarks, thisTrigger] call BIS_fnc_nearestPosition;
        _FOBMrk setMarkerColor 'colorOPFOR';
    "
];

[_thisBaseTrigger, 300] execVM "Scripts\INTLitems.sqf";