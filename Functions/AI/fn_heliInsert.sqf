/*
    Function: FLO_fnc_heliInsert
    
    Description:
    Handles helicopter insertion of QRF forces.
    
    Parameters:
    _targetPos - Target position for the QRF [Array]
    _spawnPos - Position to spawn the helicopter [Array]
    _qrfPos - Position for QRF to move to after landing [Array]
    
    Returns:
    Array - [heliGroup, qrfGroup]
*/

params [
    ["_targetPos", [0,0,0], [[]], [3]],
    ["_spawnPos", [0,0,0], [[]], [3]],
    ["_qrfPos", _targetPos, [[]], [3]]
];

if (true) then {
    // Transport helicopter setup
    private _randomDir = random 360;
    private _landingPos = _qrfPos getPos [1000 + (random 250), _randomDir];
    _landingPos = [_landingPos, 0, 200, 10, 0, 0.2, 0, [], [_landingPos, _landingPos]] call BIS_fnc_findSafePos;
    
    private _spawnPosAir = _spawnPos vectorAdd [0, 0, 100];
    
    private _heli = createVehicle [
        selectRandom (FLO_configCache get "vehicles" select 5), 
        _spawnPosAir, [], 100, "FLY"
    ];
    
    // Create and setup helicopter crew
    private _heliCrew = createVehicleCrew _heli;
    private _pilotGroup = createGroup [east, true];
    (units _heliCrew) joinSilent _pilotGroup;
    
    // Create and setup QRF team
    private _qrfGroup = createGroup [east, true];
    private _maxCargo = [(typeOf _heli), true] call BIS_fnc_crewCount;
    private _cargoCount = _maxCargo - (count units _pilotGroup) - 1;
    
    for "_i" from 1 to _cargoCount do {
        private _unitType = selectRandom (FLO_configCache get "units");
        private _unit = _qrfGroup createUnit [_unitType, _spawnPosAir, [], 0, "NONE"];
        [_unit] joinSilent _qrfGroup;
    };

    _qrfGroup deleteGroupWhenEmpty true;
    _pilotGroup deleteGroupWhenEmpty true;
    
    // Distribute intel items
    private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
    private _selectedUnits = (units _qrfGroup) call BIS_fnc_arrayShuffle;
    _selectedUnits resize floor(count _selectedUnits / 2);
    
    {
        _x addItem selectRandom _intelItems;
    } forEach _selectedUnits;
    
    // Setup helicopter waypoints
    private _wpDrop = _pilotGroup addWaypoint [_landingPos, 0];
    _wpDrop setWaypointType "MOVE";
    _wpDrop setWaypointBehaviour "CARELESS";
    _wpDrop setWaypointForceBehaviour true;
    _wpDrop setWaypointStatements [
        "true",
        "(vehicle this) land 'GET OUT'; _qrfGroup leaveVehicle (vehicle this);"
    ];
    _wpDrop setWaypointSpeed "FULL";
    
    private _wpRTB = _pilotGroup addWaypoint [_spawnPos, 0];
    _wpRTB setWaypointType "MOVE";
    _wpRTB setWaypointSpeed "FULL";
    _wpRTB setWaypointStatements ["true", "deleteVehicle (vehicle this); {deleteVehicle _x} forEach units group this; deleteGroup group this;"];
    
    // Setup QRF waypoints
    private _wpDisembark = _qrfGroup addWaypoint [_landingPos, 0];
    _wpDisembark setWaypointType "GETOUT";
    _wpDisembark setWaypointBehaviour "COMBAT";
    _wpDisembark setWaypointCompletionRadius 100;
    
    private _wpAssault = _qrfGroup addWaypoint [_qrfPos, 0];
    _wpAssault setWaypointType "SAD";
    _wpAssault setWaypointBehaviour "COMBAT";
    
    // Load QRF into helicopter
    {_x moveInCargo _heli} forEach units _qrfGroup;
    
    // Setup helicopter lights
    (driver _heli) disableAI "LIGHTS";
    {_heli setPilotLight true} forEach [true];
    _heli setCollisionLight true;
    
    // Create signal flare
    private _flare = createVehicle ["F_20mm_Red", 
        [_qrfPos select 0, _qrfPos select 1, 120],
        [], 0, "CAN_COLLIDE"
    ];
    _flare setVelocity [0, 0, -0.1];
    
    // Return the groups
    [_pilotGroup, _qrfGroup]
} else {
    [grpNull, grpNull]
}; 