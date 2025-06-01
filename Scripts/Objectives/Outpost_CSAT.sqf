private _thisOutpostTrigger = _this select 0;
private _AGGRSCORE = FLO_DifficultyHandle get "value";  

[_thisOutpostTrigger] execVM "Scripts\HMGspawn.sqf" ; 

// Create Static Helicopter in Outpost
if (count (nearestObjects [getPos _thisOutpostTrigger, FLO_configCache get "helipads", 100]) > 0) then {
    private _HPAD = nearestObjects [getPos _thisOutpostTrigger, FLO_configCache get "helipads", 100] select 0;
    private _V = createVehicle [selectRandom (FLO_configCache get "vehicles" select 5), getPos _HPAD, [], 0, "NONE"];
    _V setVehicleLock "LOCKED";
    private _dir = getDir _HPAD;
    _V setDir _dir;

    _V addEventHandler ["Killed", {
        ["ScoreAdded", ["Enemy Aircraft Sabotaged", 20]] remoteExec ["BIS_fnc_showNotification", 0];
        [20] call FLO_fnc_addReward;
        playMusic "EventTrack01_F_Curator";
        execVM 'Scripts\HeliDis.sqf';
    }];
};

// Create Transport in Outpost
if (count (nearestObjects [getPos _thisOutpostTrigger, FLO_configCache get "tyres", 100]) > 0) then {
    private _objectLoc = nearestObjects [getPos _thisOutpostTrigger, FLO_configCache get "tyres", 100];

    {
        _x hideObject true;
        sleep 1;

        private _dir = getDirVisual _x;
        private _pos = position _x;

        private _NewVeh = createVehicle [selectRandom (FLO_configCache get "vehicles" select 3), [0,0, (500 + random 2000)], [], 0, "CAN_COLLIDE"];
        _NewVeh setDir _dir;
        _NewVeh setVehicleLock "LOCKED";

        deleteVehicle _x;   

        _NewVeh setVehiclePosition [[_pos select 0, _pos select 1, (_pos select 2) + 2], [], 0, "CAN_COLLIDE"];

        sleep 1;
        _NewVeh addEventHandler ["Killed", {
            ["ScoreAdded", ["Enemy Armor Sabotaged", 30]] remoteExec ["BIS_fnc_showNotification", 0];
            [30] call FLO_fnc_addReward;
            playMusic "EventTrack01_F_Curator";
            execVM 'Scripts\LogisDis.sqf';
        }];
    } forEach _objectLoc;
};

// Create Ambient Enemy Vehicle
_poss = [(getpos _thisOutpostTrigger), 10, 20, 4, 0.1 , 0] call BIS_fnc_findSafePos;
_VLAMP = createVehicle [ "Land_LampAirport_F", _poss, [], 5, "NONE"];

// Create Intel
// Reason it's like this is because we want intel to be in different buildings
_allBuildings = nearestObjects [(getpos _thisOutpostTrigger), (FLO_configCache get "buildings"), 300];  

private _intelCount = 3 + (if (_AGGRSCORE > 10) then {2} else {if (_AGGRSCORE > 5) then {1} else {0}});
private _usedBuildings = [];

for "_i" from 1 to _intelCount do {
    private _building = selectRandom (_allBuildings - _usedBuildings);
    _usedBuildings pushBack _building;
    
    private _dir = getDirVisual _building;
    private _pos = selectRandom (_building buildingPos -1);
    
    ["Intel_01", _pos, [0,0,0], _dir, false, false, true] call LARs_fnc_spawnComp;
};

// Note: convert this to be compatible with Faction Definitions in /Factions Folder
private _HeavGuns =  nearestObjects [(getpos _thisOutpostTrigger), ["O_G_HMG_02_high_F", "O_G_Mortar_01_F"], 200];

{
    private _CrewGroup = createVehicleCrew _x; 
    {_x setUnitLoadout (selectRandom (FLO_configCache get "units"))} forEach units _CrewGroup;
} forEach _HeavGuns;
  
  
private _trg = createTrigger ["EmptyDetector", getPos _thisOutpostTrigger, false];
_trg setTriggerArea [120, 120, 0, false, 200];
_trg setTriggerTimeout [10, 10, 10, true];
_trg setTriggerActivation ["WEST SEIZED", "PRESENT", true];
_trg setTriggerStatements [
    "this",
    "
        [parseText '<t color=""#1AA3FF"" font=""PuristaBold"" align = ""right"" shadow = ""1"" size=""2"">SITREP</t><br /><t color=""#959393"" align = ""right"" shadow = ""1"" size=""0.8"">Friendly Forces Dominating the Battle,</t><br /><t color=""#959393"" align = ""right"" shadow = ""1"" size=""0.8"">Keep Up the Fight, We will Capture and Secure the Outpost,</t>', [0, 0.5, 1, 1], nil, 5, 1.7, 0] remoteExec ['BIS_fnc_textTiles', 0];
        _allMarks = allMapMarkers select {markerType _x == 'o_support'};
        _FOBMrk = [_allMarks, thisTrigger] call BIS_fnc_nearestPosition;
        _FOBMrk setMarkerColor 'ColorGrey';
        _attackingAtGrid = mapGridPosition getMarkerPos _FOBMrk;
        [[west,'HQ'], 'Friendly Forces Dominating the Battle at grid ' + _attackingAtGrid] remoteExec ['sideChat', 0];
        [thisTrigger] execVM 'Scripts\Objectives\Outpost_CSAT_CAPTURE_West.sqf';
    ",
    "
        _allMarks = allMapMarkers select {markerType _x == 'o_support'};
        _FOBMrk = [_allMarks, thisTrigger] call BIS_fnc_nearestPosition;
        _FOBMrk setMarkerColor 'colorOPFOR';
    "
];

// Create Intel
[thisOutpostTrigger, 200] execVM "Scripts\INTLitems.sqf";