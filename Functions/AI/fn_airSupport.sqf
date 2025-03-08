/*
    Function: FLO_fnc_airSupport
    
    Description:
    Manages air support operations including CAS and strike missions.
    Uses OOP-like approach with hashMapObjects for advanced aircraft behavior and mission execution.
    Requires OPFOR resources for initial aircraft deployment.
    
    Parameters:
    _targetPos - Target position for air support [Array]
    _missionType - Type of mission ("CAS" or "STRIKE") [String]
    _aircraftType - Optional specific aircraft type to spawn [String]
    _altitude - Optional operating altitude [Number]
    
    Returns:
    HashMap - Air support object with methods and state
*/

params [
    ["_targetPos", [0,0,0], [[]], [3]],
    ["_missionType", "CAS", [""]],
    ["_aircraftType", "", [""]],
    ["_altitude", 1000, [0]]
];

// Resource costs for initial deployment
private _AIRCRAFT_COSTS = createHashMapFromArray [
    ["CAS_HELI", 40],     // Attack helicopter
    ["CAS_JET", 60],      // CAS jet
    ["STRIKE", 80]        // Strike aircraft
];

// Initialize air support system if not exists
if (isNil "FLO_airSupport") then {
    FLO_airSupport = createHashMapObject [[
        ["activeUnits", createHashMap],
        ["getHeliStandoffRange", {
            params ["_heliType"];
            // Default standoff ranges for helicopters
            private _ranges = switch (_heliType) do {
                case "I_Heli_Attack_03_F": {[3500, 6000]};
                case "I_Heli_Light_01_dynamicLoadout_F": {[800, 1500]};
                case "I_Heli_light_03_dynamicLoadout_F": {[1000, 2500]};
                case "Aegis_I_Raven_Heli_Attack_04_F": {[2000, 4000]};
                default {[3000, 5000]};
            };
            _ranges
        }],
        ["createAircraft", {
            params ["_type", "_pos", "_alt", "_missionType"];
            
            // Calculate cost based on aircraft type and mission
            private _cost = if (_type isKindOf "Helicopter") then {
                _AIRCRAFT_COSTS get "CAS_HELI"
            } else {
                if (_missionType == "CAS") then {
                    _AIRCRAFT_COSTS get "CAS_JET"
                } else {
                    _AIRCRAFT_COSTS get "STRIKE"
                }
            };
            
            // Check if we have enough resources
            if (!FLO_OPFOR_Resources call ["spendResources", [_cost]]) exitWith {
                diag_log "[FLO][AirSupport] Insufficient resources for new aircraft";
                objNull
            };
            
            private _spawnPos = [_pos, 8000, 10000, 100, 0] call BIS_fnc_findSafePos;
            _spawnPos set [2, _alt];
            
            private _aircraft = createVehicle [_type, _spawnPos, [], 0, "FLY"];
            
            // Configure pylons for long-range weapons
            private _pylonMags = [
                "PylonRack_4Rnd_LG_scalpel",  // SCALPEL missiles
                "PylonRack_4Rnd_ACE_Hellfire_AGM114K",  // AGM-114K Hellfire
                "PylonRack_4Rnd_ACE_Hellfire_AGM114N",  // AGM-114N Hellfire
                "PylonRack_12Rnd_ACE_DAGR", // DAGR missiles 12x
                "PylonRack_24Rnd_ACE_DAGR", // DAGR missiles 24x
                "ace_hot_3_PylonRack_3Rnd", // HOT missiles 3x
                "ace_hot_3_PylonRack_4Rnd" // HOT missiles 4x
            ];
            
            // Get all pylon indices and set loadouts
            if (_aircraft isKindOf "Helicopter") then {
                private _pylonIndices = getAllPylonsInfo _aircraft apply {_x select 0};
                {
                    private _selectedMag = selectRandom _pylonMags;
                    [_aircraft, [_x, _selectedMag, true]] remoteExec ["setPylonLoadout", _aircraft];
                } forEach _pylonIndices;
            };

            // Create crew and group
            private _group = createGroup [east, true];
            createVehicleCrew _aircraft;
            (crew _aircraft) joinSilent _group;
            
            _aircraft
        }],
        ["getAircraftById", {
            params ["_id"];
            _self get "activeUnits" get _id
        }]
    ]];
};

// Create air support object type definition with methods
private _airSupportTypeDef = [
    ["vehicle", objNull],
    ["group", grpNull],
    ["type", ""],
    ["missionType", ""],
    ["state", "READY"],
    ["lastEngaged", time],
    ["currentTarget", objNull],
    ["weaponLoadout", []],
    ["altitude", _altitude],
    ["approachRadius", 4000],
    ["engagementRange", 6000],
    ["cooldownTime", 10],
    ["currentLaser", objNull],
    ["standoffRange", []],
    ["updateHandle", scriptNull],
    
    // Methods
    ["#create", {
        params ["_type", "_pos", "_alt", "_missionType", "_standoffRange"];
        private _aircraft = FLO_airSupport call ["createAircraft", [_type, _pos, _alt, _missionType]];
        
        if (isNull _aircraft) exitWith {
            diag_log "[FLO][AirSupport] Failed to create aircraft due to insufficient resources";
        };
        
        _self set ["vehicle", _aircraft];
        _self set ["group", group _aircraft];
        _self set ["type", _type];
        _self set ["missionType", _missionType];
        _self set ["standoffRange", _standoffRange];
        
        // Setup
        _aircraft flyInHeight _alt;
        
        private _pylonMags = getPylonMagazines _aircraft;
        _self set ["weaponLoadout", _pylonMags];
        
        private _group = _self get "group";
        _group setCombatBehaviour "COMBAT";
        _group setCombatMode "GREEN";
        {
            _x setBehaviourStrong "COMBAT";
            _x setUnitCombatMode "GREEN";
        } forEach units _group;
        
        _self call ["setupApproach", [_pos]];
        _self call ["startUpdateLoop"];
    }],
    
    ["setupApproach", {
        params ["_pos"];
        private _group = _self get "group";
        private _alt = _self get "altitude";
        private _radius = _self get "approachRadius";
        private _aircraft = _self get "vehicle";
        private _missionType = _self get "missionType";
        private _standoffRange = _self get "standoffRange";
        
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        
        // Different approach patterns for CAS vs STRIKE
        switch (_missionType) do {
            case "CAS": {
                private _holdPos = _pos;
                if (_aircraft isKindOf "Helicopter" && {count _standoffRange > 1}) then {
                    // Helicopter with standoff position
                    private _minRange = _standoffRange select 0;
                    private _maxRange = _standoffRange select 1;
                    _holdPos = _pos getPos [_minRange + (random (_maxRange - _minRange)), 270 + random 90];
                };
                _holdPos set [2, _alt];
                    
                private _wp = _group addWaypoint [_holdPos, 0];
                _wp setWaypointType "HOLD";
                _wp setWaypointBehaviour "COMBAT";
                _wp setWaypointCombatMode "GREEN";
                
                if (_aircraft isKindOf "Helicopter") then {
                    _wp setWaypointSpeed "LIMITED";
                };
            };
            case "STRIKE": {
                // Strike uses attack run pattern
                private _dir = random 360;
                private _attackPos = _pos getPos [_radius, _dir];
                _attackPos set [2, _alt];
                
                private _wp1 = _group addWaypoint [_attackPos, 0];
                _wp1 setWaypointType "MOVE";
                _wp1 setWaypointBehaviour "COMBAT";
                _wp1 setWaypointCombatMode "GREEN";
                
                private _wp2 = _group addWaypoint [_pos, 0];
                _wp2 setWaypointType "CYCLE";
                _wp2 setWaypointBehaviour "COMBAT";
                _wp2 setWaypointCombatMode "GREEN";
            };
        };
        
        _self set ["state", "APPROACHING"];
    }],
    
    ["executeStrike", {
        params ["_target"];
        private _aircraft = _self get "vehicle";
        private _pilot = driver _aircraft;
        private _gunner = gunner _aircraft;

        if (!isNull _gunner) then {
            _pilot disableAI "TARGET";
        };
        
        if (!alive _aircraft || !alive _target) exitWith {false};
        
        if ((_self get "state") == "ENGAGING" || 
            (time - (_self get "lastEngaged")) < (_self get "cooldownTime")) exitWith {false};
        
        _self set ["state", "ENGAGING"];
        _self set ["currentTarget", _target];
        
        // Create laser designation
        private _laserTarget = createVehicle ["LaserTargetW", getPos _target, [], 0, "CAN_COLLIDE"];
        _laserTarget attachTo [_target, [0,0,1]];
        _self set ["currentLaser", _laserTarget];
        
        // Select weapon and engage
        private _weapon = selectRandom (weapons (vehicle _aircraft));
        if (!isNull _gunner) then {
            _gunner reveal [_target, 4];
            _gunner doTarget _target;
            _gunner fireAtTarget [_target, _weapon];
        } else {
            _pilot reveal [_target, 4];
            _pilot fireAtTarget [_target, _weapon];
        };
        
        _self set ["lastEngaged", time];
        true
    }],
    
    ["cleanupLaser", {
        private _laser = _self get "currentLaser";
        if (!isNull _laser) then {
            deleteVehicle _laser;
            _self set ["currentLaser", objNull];
        };
    }],
    
    ["scanForTargets", {
        private _aircraft = _self get "vehicle";
        if (!alive _aircraft) exitWith {[]};
        
        private _range = _self get "engagementRange";
        private _targets = _aircraft targets [true, _range];
        _targets select {side _x != side _aircraft && alive _x}
    }],
    
    ["startUpdateLoop", {
        if (!isNull (_self get "updateHandle")) exitWith {
            diag_log "[FLO][AirSupport] Update loop already running";
        };
        
        private _handle = [_self] spawn {
            params ["_obj"];
            while {true} do {
                if !(_obj call ["update"]) exitWith {
                    diag_log "[FLO][AirSupport] Update loop terminated due to condition";
                };
                sleep 1; // Adjust this value based on performance needs
            };
            _obj set ["updateHandle", scriptNull];
        };
        _self set ["updateHandle", _handle];
    }],
    
    ["stopUpdateLoop", {
        private _handle = _self get "updateHandle";
        if (!isNull _handle) then {
            terminate _handle;
            _self set ["updateHandle", scriptNull];
            diag_log "[FLO][AirSupport] Update loop stopped";
        };
    }],
    
    ["update", {
        private _aircraft = _self get "vehicle";
        if (!alive _aircraft) exitWith {
            _self call ["cleanupLaser"];
            _self call ["stopUpdateLoop"];
            false
        };
        
        private _state = _self get "state";
        private _missionType = _self get "missionType";
        
        switch (_state) do {
            case "APPROACHING": {
                if (_missionType == "CAS") then {
                    private _targets = _self call ["scanForTargets"];
                    if (count _targets > 0) then {
                        private _target = selectRandom _targets;
                        if (_self call ["executeStrike", [_target]]) then {
                            _self set ["state", "ENGAGING"];
                        };
                    };
                };
            };
            case "ENGAGING": {
                private _currentTarget = _self get "currentTarget";
                private _timeSinceLastEngagement = time - (_self get "lastEngaged");
                //diag_log format ["[FLO][AirSupport] Engaging - Current target: %1, Time since last engagement: %2s", _currentTarget, _timeSinceLastEngagement];
                
                if (!alive _currentTarget || _timeSinceLastEngagement > (_self get "cooldownTime")) then {
                    // diag_log format ["[FLO][AirSupport] Ending engagement - Target alive: %1, Cooldown exceeded: %2", 
                    //     alive _currentTarget, 
                    //     _timeSinceLastEngagement > (_self get "cooldownTime")
                    // ];
                    _self call ["cleanupLaser"];
                    _self set ["state", "APPROACHING"];
                    _self set ["currentTarget", objNull];
                };
            };
        };
        true
    }]
];

// Initialize air support
private _aircraftType = if (_aircraftType != "") then {
    _aircraftType
} else {
    if (_missionType == "CAS") then {
        selectRandom East_Air_Heli
    } else {
        selectRandom East_Air_Jet
    };
};

// Get standoff range if it's a helicopter
private _standoffRange = [];
if (_aircraftType isKindOf "Helicopter") then {
    _standoffRange = FLO_airSupport call ["getHeliStandoffRange", [_aircraftType]];
};

// Create the air support object with proper parameter array syntax
private _airSupport = createHashMapObject [_airSupportTypeDef, [_aircraftType, _targetPos, _altitude, _missionType, _standoffRange]];

// Add to active units if creation was successful
if (!isNull (_airSupport get "vehicle")) then {
    FLO_airSupport get "activeUnits" set [str _airSupport, _airSupport];
    
    // Notify about air support based on mission type
    private _notificationText = switch (_missionType) do {
        case "CAS": {
            if (_aircraftType isKindOf "Helicopter") then {
                "Enemy attack helicopters providing close air support!"
            } else {
                "Enemy CAS aircraft providing air support!"
            };
        };
        case "STRIKE": {"Enemy strike aircraft inbound!"};
        default {"Enemy aircraft detected!"};
    };
    
    ["showNotification", ["! WARNING !", _notificationText, "warning"]] call FLO_fnc_intelSystem;
};

_airSupport