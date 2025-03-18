/*
    Function: FLO_fnc_artilleryPrep
    
    Description:
    Manages the preparation of artillery batteries for a fire mission.
    Uses a HashMapArray to track and manage artillery units and their states.
    Now requires OPFOR resources for deployment and ammo resupply.
    
    Parameters:
    _targetPos - Target position for artillery fire [Array]
    _intensity - Intensity of the fire mission [Number]
    
    Returns:
    HashMap - Tracking object for artillery batteries
*/

params ["_targetPos", "_intensity"];

// Resource costs
private _BATTERY_COST = 30;    // Cost to deploy a new battery
private _RELOAD_COST = 15;     // Cost to reload a battery

// Initialize global artillery tracking if not exists
if (isNil "FLO_artilleryBatteries") then {
    FLO_artilleryBatteries = createHashMap;
};

// Define constants for ammo management
private _AMMO_THRESHOLD = 0.3; // 30% ammo threshold
private _RELOAD_TIME = 180; // 3 minutes reload time

private _artilleryTypes = selectRandom ((FLO_configCache get "vehicles") select 7);
private _maxBatteries = 4 + (floor random 6); // Random between 4 and 10 batteries
private _currentBatteries = count FLO_artilleryBatteries;
private _newBatteriesCount = (1 + floor(_intensity/3)) min (_maxBatteries - _currentBatteries);

// Check resources for new batteries
private _totalBatteryCost = _BATTERY_COST * _newBatteriesCount;
if !(["spend", [_totalBatteryCost]] call FLO_fnc_opforResources) exitWith {
    diag_log "[FLO][Artillery] Insufficient resources for new artillery batteries";
    false
};

// Fallback artillery magazines in case no magazines are found on the vehicle
private _fallbackArtilleryMagazines = [
    "rhs_mag_3of56_35",
    "rhs_mag_bk13_5"
];

// Create new batteries if under cap and resources available
if (_newBatteriesCount > 0) then {
    ["showNotification", ["! WARNING !", "Enemy artillery batteries detected deploying!", "warning"]] call FLO_fnc_intelSystem;
    
    // Find all OPFOR objective markers
    private _opforMarkers = allMapMarkers select {
        markerColor _x in ["colorOPFOR", "ColorEAST"] && 
        markerAlpha _x > 0 &&
        !((markerType _x) in ["Empty", ""])
    };
    
    if (count _opforMarkers isEqualTo 0) then {
        // Fallback in case no OPFOR markers found
        diag_log "[FLO][Artillery] No OPFOR objectives found for artillery placement, using fallback method";
        _opforMarkers = [[_targetPos, 5000, 10000, 10, 0] call BIS_fnc_findSafePos];
    };
    
    // Sort by distance from target (prioritize objectives farther from the action)
    _opforMarkers = [_opforMarkers, [], {getMarkerPos _x distance _targetPos}, "DESCEND"] call BIS_fnc_sortBy;
    
    // Create a group for the artillery units
    // private _artGroup = createGroup [east, true];
    
    for "_i" from 1 to _newBatteriesCount do {
        // Select a random OPFOR objective from the nearest 60% of objectives
        private _maxIndex = floor((count _opforMarkers) * 0.6) max 1;
        private _selectedMarkerIndex = floor(random _maxIndex);
        private _selectedMarker = _opforMarkers select (_selectedMarkerIndex min ((count _opforMarkers) - 1));
        
        // Get position from marker, then find nearby position that's suitable
        private _objectivePos = getMarkerPos _selectedMarker;
        
        // Find position 300-800m from the objective
        private _direction = random 360;
        private _distance = 300 + random 500; // 300-800m from objective
        private _rawPos = _objectivePos getPos [_distance, _direction];
        
        // Ensure it's a valid position
        private _artPos = [_rawPos, 0, 200, 10, 0, 0.3, 0, [], [_rawPos, _rawPos]] call BIS_fnc_findSafePos;
        
        // If position finding failed, use marker position directly
        if (_artPos isEqualTo [_rawPos, _rawPos]) then {
            _artPos = [_objectivePos, 0, 400, 10, 0] call BIS_fnc_findSafePos;
        };
        
        diag_log format ["[FLO][Artillery] Placed artillery battery near OPFOR objective at %1", _artPos];
        
        private _arty = createVehicle [_artilleryTypes, _artPos, [], 0, "NONE"];
        
        // Set vehicle variables
        _arty setVariable ["acex_headless_blacklist", true, true];
        
        // Determine if this is rocket artillery based on weapon and ammo configuration data
        private _isRocketArtillery = [_arty] call {
            params ["_vehicle"];
            
            // Check for MLRS by examining turret's nameSound property
            private _gunner = gunner _vehicle;
            if (isNull _gunner) exitWith {false}; // No gunner found
            
            private _assignedRoles = assignedVehicleRole _gunner;
            if ((count _assignedRoles) < 2) exitWith {false}; // Gunner doesn't have proper turret
            
            private _turretPath = _assignedRoles select 1;
            private _weaponsInTurret = _vehicle weaponsTurret _turretPath;
            private _turret = _weaponsInTurret select 0;
            private _nameSound = getText (configFile >> "CfgWeapons" >> _turret >> "nameSound");
            
            (_nameSound isEqualTo "rockets")
        };
        
        // Store the artillery type in the vehicle for later use
        _arty setVariable ["FLO_isRocketArtillery", _isRocketArtillery, true];
        
        // Create and setup crew
        private _crew = units (east createVehicleCrew _arty);
        _crew joinSilent _artGroup;
        _arty disableAI "FSM";
        _arty disableAI "AUTOTARGET";
        {
            _x setUnitCombatMode "BLUE";
			_x disableAI "FSM";
			_x disableAI "AUTOTARGET";
			_x setVariable ["acex_headless_blacklist", true, true];
        } forEach _crew;
        
        // Create fortifications around battery
        private _fortTypes = ["Land_BagBunker_Small_F", "Land_BagFence_Long_F", "Land_BagFence_Round_F"];
        private _forts = [];
        for "_j" from 0 to 5 do {
            private _fortPos = _arty getPos [10, _j * 60];
            private _fort = createVehicle [selectRandom _fortTypes, _fortPos, [], 0, "NONE"];
            _fort setDir (_fort getDir _arty);
            _forts pushBack _fort;
        };
        
        // Add to tracking
        FLO_artilleryBatteries set [netId _arty, createHashMapFromArray [
            ["vehicle", _arty],
            ["group", _artGroup],
            ["forts", _forts],
            ["lastFired", time],
            ["position", getPosASL _arty],
            ["state", "READY"],
            ["ammoLevel", 1],
            ["reloadStartTime", 0]
        ]];
    };
};

// Execute fire mission for each battery
{
    private _batteryInfo = _y;
    private _arty = _batteryInfo get "vehicle";
    
    // Get a random magazine from the artillery vehicle using our new function
    private _selectedMagazine = [_arty] call FLO_fnc_getRandomMagazine;
    
    // If no magazines found, use a fallback option
    if (_selectedMagazine isEqualTo "") then {
        _selectedMagazine = selectRandom _fallbackArtilleryMagazines;
        diag_log format ["[FLO][Artillery] No magazines found on %1, using fallback magazine: %2", _arty, _selectedMagazine];
    };
    
    if (alive _arty && _targetPos inRangeOfArtillery [[_arty], _selectedMagazine]) then {
        private _ammoLevel = _batteryInfo get "ammoLevel";
        private _state = _batteryInfo get "state";
        
        // Check if battery is reloading
        if (_state isEqualTo "RELOADING") then {
            private _reloadStartTime = _batteryInfo get "reloadStartTime";
            if ((time - _reloadStartTime) >= _RELOAD_TIME) then {
                // Check resources for reload
                if (["spend", [_RELOAD_COST]] call FLO_fnc_opforResources) then {
                    _batteryInfo set ["state", "READY"];
                    _batteryInfo set ["ammoLevel", 1];
                    [_arty, 1] remoteExec ["setVehicleAmmo", _arty];
                } else {
                    diag_log "[FLO][Artillery] Insufficient resources to reload artillery battery";
                };
            };
        };
        
        // Only proceed if battery is ready and has enough ammo
        if (_state isEqualTo "READY" && _ammoLevel > _AMMO_THRESHOLD) then {
            [_arty, _targetPos, _selectedMagazine, _batteryInfo, _AMMO_THRESHOLD] spawn {
                params ["_arty", "_targetPos", "_selectedMagazine", "_batteryInfo", "_AMMO_THRESHOLD"];
                
                // Set battery to watch target
                _arty doWatch (_targetPos getPos [0,0]);
                
                // Check if this is rocket artillery
                private _isRocketArtillery = _arty getVariable ["FLO_isRocketArtillery", false];
                
                // Different behavior based on artillery type
                if (_isRocketArtillery) then {
                    // ---- Rocket Artillery Barrage Logic ----
                    private _rocketCount = 8 + round(random 4); // More rockets for MLRS systems
                    private _minDispersion = 70;
                    private _maxDispersion = 200; // Wider dispersion for rockets
                    
                    _batteryInfo set ["state", "IN MISSION"];
                    
                    // Fire rockets directly in the loop
                    for "_i" from 1 to _rocketCount do {
                        private _inRange = false;
                        private _attempts = 0;
                        private _finalPos = _targetPos;
                        
                        // Find valid firing position with dispersion
                        while {!_inRange && _attempts < 25} do {
                            private _dispersedPos = _targetPos getPos [_minDispersion + (random (_maxDispersion - _minDispersion)), random 360];
                            if (_dispersedPos inRangeOfArtillery [[_arty], _selectedMagazine]) then {
                                _inRange = true;
                                _finalPos = _dispersedPos;
                            };
                            _attempts = _attempts + 1;
                        };
                        
                        if (_inRange) then {
                            _arty commandArtilleryFire [_finalPos, _selectedMagazine, _rocketCount];
                        };
                        
                        // Wait for crew to be ready before next shot
                        waitUntil {
                            sleep 1;
                            private _readys = 0;

                            {
                                private _rdy = true;
                                {
                                    // Check if crew position exists before checking if ready
                                    if (!isNull _x) then {
                                        _rdy = _rdy && (unitReady _x);
                                    };
                                } forEach [
                                    commander _x,
                                    gunner _x,
                                    driver _x
                                ];

                                if(_rdy) then {
                                    _readys = _readys + 1;
                                };
                            } forEach [_arty];

                            _readys isEqualTo (count [_arty]);
                        };
                    };
                    
                    // Update ammo level after firing barrage
                    private _currentAmmo = _batteryInfo get "ammoLevel";
                    private _newAmmo = _currentAmmo - ((1 / 10) * _rocketCount); // Each rocket uses 10% ammo
                    _batteryInfo set ["ammoLevel", _newAmmo];
                    
                    // Check if ammo is below threshold
                    if (_newAmmo <= _AMMO_THRESHOLD) then {
                        _batteryInfo set ["state", "RELOADING"];
                        _batteryInfo set ["reloadStartTime", time];
                    } else {
                        _batteryInfo set ["state", "READY"];
                    };
                    
                    _batteryInfo set ["lastFired", time];
                } else {
                    // ---- Standard Tube Artillery Logic ----
                    private _shellCount = 3 + round(random 3);
                    private _minDispersion = 50;
                    private _maxDispersion = 150;
                    
                    _batteryInfo set ["state", "IN MISSION"];
                    
                    for "_i" from 1 to _shellCount do {
                        private _inRange = false;
                        private _attempts = 0;
                        private _finalPos = _targetPos;
                        
                        // Find valid firing position with dispersion
                        while {!_inRange && _attempts < 25} do {
                            private _dispersedPos = _targetPos getPos [_minDispersion + (random (_maxDispersion - _minDispersion)), random 360];
                            if (_dispersedPos inRangeOfArtillery [[_arty], _selectedMagazine]) then {
                                _inRange = true;
                                _finalPos = _dispersedPos;
                            };
                            _attempts = _attempts + 1;
                        };
                        
                        if (_inRange) then {
                            _arty commandArtilleryFire [_finalPos, _selectedMagazine, 1];
                        };

                        // Wait for crew to be ready before next shot
                        waitUntil {
                            sleep 1;
                            private _readys = 0;

                            {
                                private _rdy = true;
                                {
                                    // Check if crew position exists before checking if ready
                                    if (!isNull _x) then {
                                        _rdy = _rdy && (unitReady _x);
                                    };
                                } forEach [
                                    commander _x,
                                    gunner _x,
                                    driver _x
                                ];

                                if(_rdy) then {
                                    _readys = _readys + 1;
                                };
                            } forEach [_arty];

                            _readys isEqualTo (count [_arty]);
                        };
                    };
                    
                    // Update ammo level after firing
                    private _currentAmmo = _batteryInfo get "ammoLevel";
                    private _newAmmo = _currentAmmo - ((1 / 20) * _shellCount); // Each volley uses 5% ammo
                    _batteryInfo set ["ammoLevel", _newAmmo];
                    
                    // Check if ammo is below threshold
                    if (_newAmmo <= _AMMO_THRESHOLD) then {
                        _batteryInfo set ["state", "RELOADING"];
                        _batteryInfo set ["reloadStartTime", time];
                    } else {
                        _batteryInfo set ["state", "READY"];
                    };
                    
                    _batteryInfo set ["lastFired", time];
                };
            };
        };
    };
} forEach FLO_artilleryBatteries;

// Clean up destroyed batteries from tracking
private _toRemove = [];
{
    private _batteryInfo = _y;
    private _arty = _batteryInfo get "vehicle";
    private _group = _batteryInfo get "group";
    private _forts = _batteryInfo get "forts";
    
    if (!alive _arty) then {
        if (!isNull _group) then {
            {deleteVehicle _x} forEach units _group;
            deleteGroup _group;
        };
        {deleteVehicle _x} forEach _forts;
        _toRemove pushBack _x;
    };
} forEach FLO_artilleryBatteries;

{FLO_artilleryBatteries deleteAt _x} forEach _toRemove;
