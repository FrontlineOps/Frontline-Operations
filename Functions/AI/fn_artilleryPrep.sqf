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

// Define artillery magazines
private _artilleryMagazines = [
    "32Rnd_155mm_Mo_shells_O",
    "2Rnd_155mm_Mo_Cluster_O"
];

// Create new batteries if under cap and resources available
if (_newBatteriesCount > 0) then {
    ["showNotification", ["! WARNING !", "Enemy artillery batteries detected deploying!", "warning"]] call FLO_fnc_intelSystem;
    for "_i" from 1 to _newBatteriesCount do {
        // Find position far from target but with good firing position
        private _artPos = [_targetPos, 5000, 10000, 10, 0] call BIS_fnc_findSafePos;
        private _arty = createVehicle [_artilleryTypes, _artPos, [], 0, "NONE"];
        
        // Set vehicle variables
        _arty setVariable ["acex_headless_blacklist", true, true];
        
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
    private _selectedMagazine = selectRandom _artilleryMagazines;
    
    if (alive _arty && _targetPos inRangeOfArtillery [[_arty], _selectedMagazine]) then {
        private _ammoLevel = _batteryInfo get "ammoLevel";
        private _state = _batteryInfo get "state";
        
        // Check if battery is reloading
        if (_state == "RELOADING") then {
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
        if (_state == "READY" && _ammoLevel > _AMMO_THRESHOLD) then {
            [_arty, _targetPos, _selectedMagazine, _batteryInfo, _AMMO_THRESHOLD] spawn {
                params ["_arty", "_targetPos", "_selectedMagazine", "_batteryInfo", "_AMMO_THRESHOLD"];
                
                // Set battery to watch target
                _arty doWatch (_targetPos getPos [0,0]);
                
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
                                _rdy = _rdy && (unitReady _x);
                            } forEach [
                                commander _x,
                                gunner _x,
                                driver _x
                            ];

                            if(_rdy) then {
                                _readys = _readys + 1;
                            };
                        } forEach [_arty];

                        _readys == (count [_arty]);
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
