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
    ["_altitude", 150, [0]]
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
                case "I_Heli_Attack_03_F": {[1500, 2000]};
                case "I_Heli_Light_01_dynamicLoadout_F": {[800, 1500]};
                case "I_Heli_light_03_dynamicLoadout_F": {[2000, 2500]};
                case "Aegis_I_Raven_Heli_Attack_04_F": {[2000, 2500]};
                default {[1500, 2000]};
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
            if !(["spend", [_cost]] call FLO_fnc_opforResources) exitWith {
                diag_log "[FLO][AirSupport] Insufficient resources for new aircraft";
                objNull
            };
            
            // Find all OPFOR objective markers
            private _opforMarkers = allMapMarkers select {
                markerColor _x in ["colorOPFOR", "ColorEAST"] && 
                markerAlpha _x > 0 &&
                !((markerType _x) in ["Empty", ""])
            };
            
            private _spawnPos = [];
            
            if (count _opforMarkers > 0) then {
                // Sort by distance from target (prioritize objectives farther from the action)
                _opforMarkers = [_opforMarkers, [], {getMarkerPos _x distance _pos}, "DESCEND"] call BIS_fnc_sortBy;
                
                // Select a random marker from the farthest 40% of markers
                private _markerCount = count _opforMarkers;
                private _startIndex = 0;
                private _endIndex = floor(_markerCount * 0.4) max 1;
                private _selectedIndex = floor(random [_startIndex, _startIndex + (_endIndex - _startIndex) / 2, _endIndex]);
                private _selectedMarker = _opforMarkers select (_selectedIndex min (_markerCount - 1));
                
                // Get marker position and add some randomization
                private _markerPos = getMarkerPos _selectedMarker;
                private _spawnOffset = [random [-500, 0, 500], random [-500, 0, 500], 0];
                _spawnPos = _markerPos vectorAdd _spawnOffset;
                
                diag_log format ["[FLO][AirSupport] Spawning %1 at OPFOR objective %2", _type, _selectedMarker];
            } else {
                // Fallback to original method if no OPFOR markers found
                _spawnPos = [_pos, 8000, 10000, 100, 0] call BIS_fnc_findSafePos;
                diag_log "[FLO][AirSupport] No OPFOR objectives found, using fallback spawn position";
            };
            
            _spawnPos set [2, _alt];
            
            private _aircraft = createVehicle [_type, _spawnPos, [], 0, "FLY"];

            // Create crew and group
            private _group = createGroup [east, true];
            createVehicleCrew _aircraft;
            (crew _aircraft) joinSilent _group;
            
            // Configure weapon systems and categorize them
            private _weaponSystems = [];
            
            // First check for pylon-mounted weapons which might not show up in the regular weapons array
            private _pylonMags = getPylonMagazines _aircraft;
            private _pylonWeapons = [];
            
            {
                private _magConfig = configFile >> "CfgMagazines" >> _x;
                if (isClass _magConfig) then {
                    private _pylonWeapon = getText (_magConfig >> "pylonWeapon");
                    if (_pylonWeapon != "") then {
                        _pylonWeapons pushBackUnique _pylonWeapon;
                    };
                };
            } forEach _pylonMags;
            
            // Combine regular weapons with pylon weapons to ensure we don't miss anything
            private _allWeapons = weapons _aircraft;
            {
                if !(_x in _allWeapons) then {
                    _allWeapons pushBack _x;
                };
            } forEach _pylonWeapons;
            
            // Now process all weapons including both regular and pylon-mounted ones
            // We need to put this into it's own function as it's a bit complex
            {
                private _weapon = _x;
                private _config = configFile >> "CfgWeapons" >> _weapon;
                private _magazines = getArray (_config >> "magazines");
                private _displayName = getText (_config >> "displayName");
                private _weaponType = "UNKNOWN";
                
                // Special handling for specific Russian weapons like S-8 rockets
                if (toLower _weapon find "s-8" > -1 || toLower _weapon find "s8" > -1 || 
                    toLower _weapon find "s_8" > -1 || toLower _weapon find "s5" > -1 || 
                    toLower _weapon find "s-5" > -1 || toLower _weapon find "s13" > -1 || 
                    toLower _weapon find "s-13" > -1) then {
                    _weaponType = "ROCKET";
                } else {
                    // Check for bombs in weapon name
                    if (toLower _weapon find "bomb" > -1 || toLower _weapon find "fab" > -1 || 
                        toLower _weapon find "kab" > -1 || toLower _weapon find "ofab" > -1) then {
                        _weaponType = "BOMB";
                    } else {
                        // Improved weapon classification based on config properties
                        private _ammoNames = [];
                        {
                            private _magConfig = configFile >> "CfgMagazines" >> _x;
                            if (isClass _magConfig) then {
                                private _ammoName = getText (_magConfig >> "ammo");
                                _ammoNames pushBack _ammoName;
                                
                                // Check magazine name for rocket patterns
                                if (toLower _x find "s_8" > -1 || toLower _x find "s-8" > -1 || 
                                    toLower _x find "s8" > -1 || toLower _x find "rocket" > -1 || 
                                    toLower _x find "b8" > -1 || toLower _x find "b_8" > -1 || 
                                    toLower _x find "b-8" > -1) then {
                                    _weaponType = "ROCKET";
                                };
                                
                                // Check magazine name for bomb patterns
                                if (toLower _x find "bomb" > -1 || toLower _x find "fab" > -1 || 
                                    toLower _x find "kab" > -1 || toLower _x find "ofab" > -1 || 
                                    toLower _x find "250kg" > -1 || toLower _x find "500kg" > -1) then {
                                    _weaponType = "BOMB";
                                };
                            };
                        } forEach _magazines;
                        
                        // Check if any ammo types are missiles or rockets
                        private _hasMissiles = false;
                        private _hasRockets = false;
                        private _hasCannon = false;
                        private _hasBombs = false;
                        
                        // Additional checks for cannons - specific to RHS and other mods
                        // Check weapon class name for known cannon designations
                        if (toLower _weapon find "2a42" > -1 || toLower _weapon find "cannon" > -1 || 
                            toLower _weapon find "30mm" > -1 || toLower _weapon find "23mm" > -1 || 
                            toLower _weapon find "25mm" > -1 || toLower _weapon find "autocannon" > -1) then {
                            _hasCannon = true;
                        };
                        
                        // Add check for rotatable turret cannon systems
                        private _isRotatableCannon = false;
                        if (_hasCannon && _aircraft isKindOf "Helicopter") then {
                            // Check for typical rotatable cannon systems on attack helicopters
                            if (toLower _weapon find "2a42" > -1 || // Mi-28 cannon
                                toLower _weapon find "m230" > -1 || // Apache M230 Chain Gun
                                toLower _weapon find "shipka" > -1 || // Ka-50/52 cannon
                                toLower _weapon find "gsh" > -1 || // Various Russian heli cannons
                                toLower _weapon find "30mm" > -1) then {
                                
                                // Additional check - these weapons typically have multiple firing modes
                                private _modes = getArray (_config >> "modes");
                                if (count _modes > 1) then {
                                    _isRotatableCannon = true;
                                    // Mark this as a special weapon category
                                    _aircraft setVariable ["FLO_hasRotatableCannon", true];
                                };
                            };
                        };
                        
                        // Check weapon parent classes for cannon-related inheritance
                        private _parentClasses = [_config, true] call BIS_fnc_returnParents;
                        if (count _parentClasses > 0) then {
                            {
                                if (toLower _x find "cannon" > -1) exitWith {
                                    _hasCannon = true;
                                };
                            } forEach _parentClasses;
                        };
                        
                        // Check weapon modes for high rates of fire - typical of cannons
                        private _modes = getArray (_config >> "modes");
                        if (count _modes > 0) then {
                            private _primaryMode = if (_modes select 0 == "this") then {_config} else {_config >> (_modes select 0)};
                            if (isClass _primaryMode) then {
                                private _reloadTime = getNumber (_primaryMode >> "reloadTime");
                                // Cannons typically have fast reload times (high rate of fire)
                                if (_reloadTime > 0 && _reloadTime < 0.2) then {
                                    _hasCannon = true;
                                };
                            };
                        };
                        
                        {
                            private _ammoConfig = configFile >> "CfgAmmo" >> _x;
                            if (isClass _ammoConfig) then {
                                // Check simulation type which is more reliable
                                private _simulation = toLower (getText (_ammoConfig >> "simulation"));
                                
                                if (_simulation == "shotmissile" || _simulation == "missilecore" || 
                                    _simulation == "missilex" || (getNumber (_ammoConfig >> "manualControl") > 0)) then {
                                    _hasMissiles = true;
                                } else {
                                    if (_simulation == "shotRocket" || _simulation == "shotRocketSpeed" || 
                                        _simulation == "shotSubmunitions" || // Common for cluster rocket systems
                                        toLower _x find "rocket" > -1 || toLower _x find "s5" > -1 || 
                                        toLower _x find "s8" > -1 || toLower _x find "s_8" > -1 || 
                                        toLower _x find "s-8" > -1 || toLower _x find "s13" > -1) then {
                                        _hasRockets = true;
                                    } else {
                                        if (_simulation == "shotBullet" || _simulation == "shotShell") then {
                                            _hasCannon = true;
                                        } else {
                                            if (_simulation == "shotBomb" || _simulation == "bomb" || 
                                                _simulation == "shotMine") then {
                                                _hasBombs = true;
                                            };
                                        };
                                    };
                                };
                                
                                // Additional check for shell caliber - autocannons are typically 20mm-57mm
                                private _hit = getNumber (_ammoConfig >> "hit");
                                private _explosive = getNumber (_ammoConfig >> "explosive");
                                
                                // Large caliber shells have higher damage and often explosive
                                if (_hit > 50 && _explosive > 0) then {
                                    _hasCannon = true;
                                };
                                
                                // Check for typical S-8/S-13 rocket characteristics 
                                private _caliber = getNumber (_ammoConfig >> "caliber");
                                if (_caliber > 0.06 && _caliber < 0.15 && _explosive > 0) then {
                                    // S-8 are ~80mm, S-13 are ~122mm caliber
                                    _hasRockets = true;
                                };
                                
                                // Check for typical bomb characteristics - large explosive power
                                if (_explosive > 0) then {
                                    private _indirectHit = getNumber (_ammoConfig >> "indirectHit");
                                    private _indirectHitRange = getNumber (_ammoConfig >> "indirectHitRange");
                                    
                                    // Bombs typically have large explosion radius and high indirect damage
                                    if (_indirectHit > 200 || _indirectHitRange > 5) then {
                                        _hasBombs = true;
                                    };
                                };
                            };
                        } forEach _ammoNames;
                        
                        // Determine final weapon type
                        if (_hasMissiles) then {
                            _weaponType = "MISSILE";
                        } else {
                            if (_hasBombs) then {
                                _weaponType = "BOMB";
                            } else {
                                if (_hasRockets) then {
                                    _weaponType = "ROCKET";
                                } else {
                                    if (_hasCannon) then {
                                        // Check if this is a special rotatable cannon
                                        if (_isRotatableCannon) then {
                                            _weaponType = "ROTATABLE_CANNON";
                                        } else {
                                            _weaponType = "CANNON";
                                        }
                                    } else {
                                        // Fallback to name-based classification if needed
                if (toLower _displayName find "cannon" > -1) then {
                    _weaponType = "CANNON";
                } else {
                    if (toLower _displayName find "rocket" > -1) then {
                        _weaponType = "ROCKET";
                    } else {
                        if (toLower _displayName find "missile" > -1 || toLower _displayName find "guided" > -1) then {
                            _weaponType = "MISSILE";
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
                
                _weaponSystems pushBack [_weapon, _weaponType, _magazines];
            } forEach _allWeapons;
            
            diag_log format ["[FLO][AirSupport] Aircraft weapon systems: %1", _weaponSystems];
            
            _aircraft setVariable ["FLO_weaponSystems", _weaponSystems];
            
            // Initialize threat state variables
            _aircraft setVariable ["FLO_isUnderThreat", false];
            _aircraft setVariable ["FLO_lastCountermeasureTime", 0];
            _aircraft setVariable ["FLO_originalAlt", _alt];
            
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
    ["lastScanTime", 0],
    ["lastScanTargets", []],
    ["lastInfantryCheck", 0],
    ["FLO_lastKnowledgeCheckTime", 0],
    ["FLO_lastWeaponCheckTime", 0],
    ["FLO_directAttackMode", false],
    ["currentTarget", objNull],
    ["weaponLoadout", []],
    ["altitude", _altitude],
    ["approachRadius", 4000],
    ["engagementRange", 6000],
    ["cooldownTime", 5],
    ["currentLaser", objNull],
    ["standoffRange", []],
    ["updateHandle", scriptNull],
    ["threatResponseHandle", scriptNull],
    ["incomingMissileDetected", false],
    ["evasionMode", false],
    ["evasionStartTime", 0],
    ["evasionDuration", 30], // Time in seconds that evasion mode lasts
    ["lastTargetDetectionTime", time], // Track when the last target was detected
    ["engagementStartTime", time], // Initialize engagement start time
    
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
        
        // Check if this is a helicopter with long range weapons (missiles or rotatable cannons)
        // and adjust the standoff range accordingly
        if (_aircraft isKindOf "Helicopter") then {
            private _weaponSystems = _aircraft getVariable ["FLO_weaponSystems", []];
            private _hasLongRangeWeapons = false;
            
            {
                _x params ["_weapon", "_weaponType"];
                if (_weaponType == "MISSILE" || _weaponType == "ROTATABLE_CANNON") then {
                    _hasLongRangeWeapons = true;
                };
            } forEach _weaponSystems;
            
            // If helicopter has long range weapons, use 3000-4000m standoff range
            if (_hasLongRangeWeapons) then {
                _self set ["standoffRange", [3000, 4000]];
                diag_log format ["[FLO][AirSupport] Helicopter %1 standoff range increased to 3000-4000m due to long range weapons", _type];
            };
        };
        
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
            _x disableAI "AUTOTARGET";  
            _x disableAI "AUTOCOMBAT";
        } forEach units _group;
        
        _self call ["setupApproach", [_pos]];
        _self call ["startUpdateLoop"];
        _self call ["startThreatDetection"];
    }],
    
    ["setupApproach", {
        params ["_pos"];
        private _group = _self get "group";
        private _alt = _self get "altitude";
        private _radius = _self get "approachRadius";
        private _aircraft = _self get "vehicle";
        private _missionType = _self get "missionType";
        private _standoffRange = _self get "standoffRange";
        
        // Store the target position for later reference
        _self set ["lastTargetPos", _pos];
        
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        
        // Different approach patterns for CAS vs STRIKE
        switch (_missionType) do {
            case "CAS": {
                private _holdPos = _pos;
                if (_aircraft isKindOf "Helicopter" && {count _standoffRange > 1}) then {
                    // Find friendly units to support
                    private _friendlyUnits = allUnits select {side _x isEqualTo east && alive _x};
                    private _nearbyFriendlies = [];
                    
                    // Find friendlies that are within reasonable support distance of the target position
                    if (count _friendlyUnits > 0) then {
                        _nearbyFriendlies = _friendlyUnits select {_x distance _pos < 1500};
                    };
                    
                    private _minRange = _standoffRange select 0;
                    private _maxRange = _standoffRange select 1;
                    
                    // Determine ideal hold position
                    if (count _nearbyFriendlies > 0) then {
                        // Use nearest friendly as reference point
                        private _nearestFriendly = [_nearbyFriendlies, _pos] call BIS_fnc_nearestPosition;
                        
                        // Get angle between friendly unit and target
                        private _dirFromFriendlyToTarget = _nearestFriendly getDir _pos;
                        
                        // Position aircraft in front of friendly unit relative to target (friendly's "12 o'clock")
                        // This puts aircraft between friendly units and the target for better engagement angles
                        private _holdDir = _dirFromFriendlyToTarget;
                        // Normalize direction to 0-360 range without using modulus
                        if (_holdDir >= 360) then {
                            _holdDir = _holdDir - 360;
                        };
                        
                        // Place at standoff distance
                        _holdPos = _pos getPos [_minRange + (random (_maxRange - _minRange)), _holdDir];
                        
                        diag_log format ["[FLO][AirSupport] Holding in front of friendly units at %1", _holdPos];
                    } else {
                        // No nearby friendlies, use a position that gives good firing angle
                        // Full 360-degree choice but prioritize higher terrain if possible
                        private _bestElevation = -999;
                        private _bestPos = [];
                        
                        // Sample several positions around target
                        for "_i" from 0 to 7 do {
                            private _testDir = _i * 45; // 0, 45, 90, 135, 180, 225, 270, 315
                            private _testPos = _pos getPos [_minRange + (random (_maxRange - _minRange)), _testDir];
                            private _elevation = getTerrainHeightASL _testPos;
                            
                            if (_elevation > _bestElevation) then {
                                _bestElevation = _elevation;
                                _bestPos = _testPos;
                            };
                        };
                        
                        if (count _bestPos > 0) then {
                            _holdPos = _bestPos;
                        } else {
                            // Fallback to random direction if no position found
                            _holdPos = _pos getPos [_minRange + (random (_maxRange - _minRange)), random 360];
                        };
                        
                        diag_log format ["[FLO][AirSupport] No nearby friendlies, holding at optimal position %1", _holdPos];
                    };
                };
                _holdPos set [2, _alt];
                    
                private _wp = _group addWaypoint [_holdPos, 0];
                _wp setWaypointType "HOLD";
                _wp setWaypointBehaviour "COMBAT";
                _wp setWaypointCombatMode "GREEN";
                
                // Always face aircraft toward the target position after reaching hold position
                private _wpCompletionRadius = 50;
                _wp setWaypointCompletionRadius _wpCompletionRadius;
                
                // Add a trigger to make the aircraft face the target when it reaches the hold position
                [_aircraft, _pos, _holdPos] spawn {
                    params ["_aircraft", "_targetPos", "_holdPos"];
                    waitUntil {sleep 1; ((getPosASL _aircraft) distance _holdPos) < 100 || !alive _aircraft};
                    
                    if (alive _aircraft) then {
                        // Get direction to target
                        waitUntil {sleep 0.5; !isNil "_targetPos" && {count _targetPos > 0}};
                        private _dir = (getPosASL _aircraft) getDir _targetPos;
                        
                        // Store the desired direction for reference
                        _aircraft setVariable ["FLO_targetDirection", _dir];
                        
                        // Start turning toward desired direction
                        private _currentDir = getDir _aircraft;
                        
                        // Calculate direction difference directly using simple math
                        private _dirDiff = (_dir - _currentDir + 180) % 360 - 180;
                        
                        // Determine turn direction based on shortest path
                        if (_dirDiff > 0) then {
                            _aircraft sendSimpleCommand "RIGHT";
                        } else {
                            _aircraft sendSimpleCommand "LEFT";
                        };
                        
                        // Set up a PFH to monitor and stop the turn when reaching desired direction
                        [{
                            params ["_args", "_handle"];
                            _args params ["_aircraft", "_targetDir"];
                            
                            if (isNull _aircraft) exitWith {
                                [_handle] call CBA_fnc_removePerFrameHandler;
                            };
                            
                            private _currentDir = getDir _aircraft;
                            private _diff = abs((_currentDir - _targetDir + 540) % 360 - 180);
                            
                            // When close enough to desired direction, stop turning
                            if (_diff < 5) then {
                                _aircraft sendSimpleCommand "STOPTURNING";
                                [_handle] call CBA_fnc_removePerFrameHandler;
                            };
                        }, 0.1, [_aircraft, _dir]] call CBA_fnc_addPerFrameHandler;
                    };
                };
                
                if (_aircraft isKindOf "Helicopter") then {
                    _wp setWaypointSpeed "LIMITED";
                };
            };
            case "STRIKE": {
                // Strike uses attack run pattern
                // For strike missions, we want to approach from the direction of friendly forces
                private _dir = random 360;
                
                // Find friendly units to determine approach direction
                private _friendlyUnits = allUnits select {side _x isEqualTo east && alive _x};
                if (count _friendlyUnits > 0) then {
                    // Get nearest friendly unit
                    private _nearestFriendly = [_friendlyUnits, _pos] call BIS_fnc_nearestPosition;
                    
                    // Approach from the direction of friendly forces 
                    _dir = _nearestFriendly getDir _pos;
                    diag_log format ["[FLO][AirSupport] Strike approaching from friendly direction: %1 degrees", _dir];
                };
                
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
                
                // Ensure aircraft faces toward target during approach
                [_aircraft, _pos] spawn {
                    params ["_aircraft", "_targetPos"];
                    while {alive _aircraft} do {
                        _aircraft doWatch _targetPos;
                        sleep 5;
                    };
                };
            };
        };
        
        _self set ["state", "APPROACHING"];
    }],
    
    ["startThreatDetection", {
        if (!isNull (_self get "threatResponseHandle")) exitWith {
            diag_log "[FLO][AirSupport] Threat detection already running";
        };
        
        private _aircraft = _self get "vehicle";
        private _handle = [_self] spawn {
            params ["_obj"];
            private _aircraft = _obj get "vehicle";
            private _cooldownTime = 15; // Time between successive countermeasure deployments
            
            while {alive _aircraft} do {
                // Check if aircraft is being targeted by an AA weapon
                private _missileThreat = false;
                private _threatLevel = 0;
                
                // Get all missiles within detection range
                private _nearbyProjectiles = (getPosATL _aircraft) nearObjects ["MissileBase", 2000];
                private _nearbyMANPADS = allUnits select {
                    side _x isNotEqualTo east && 
                    alive _x && 
                    (_x distance _aircraft < 2000) && 
                    (secondaryWeapon _x isNotEqualTo "") &&
                    (getText (configFile >> "CfgWeapons" >> secondaryWeapon _x >> "displayName") find "AA" > -1 ||
                     getText (configFile >> "CfgWeapons" >> secondaryWeapon _x >> "displayName") find "Anti-Air" > -1 ||
                     getText (configFile >> "CfgWeapons" >> secondaryWeapon _x >> "displayName") find "Stinger" > -1 ||
                     getText (configFile >> "CfgWeapons" >> secondaryWeapon _x >> "displayName") find "Igla" > -1 ||
                     getText (configFile >> "CfgWeapons" >> secondaryWeapon _x >> "displayName") find "Javelin" > -1)
                };
                
                // Check for inbound missiles
                {
                    private _missilePos = getPosASL _x;
                    private _missileVel = velocity _x;
                    private _targetPos = _missilePos vectorAdd (_missileVel vectorMultiply 3); // Project missile path
                    private _distance = _aircraft distance _targetPos;
                    
                    // Check if missile is heading toward aircraft
                    if (_distance < 300) then {
                        private _dir1 = (_missilePos getDir _aircraft);
                        private _dir2 = getDir _x;
                        private _angleDiff = abs (_dir1 - _dir2);
                        if (_angleDiff < 30 || _angleDiff > 330) then {
                            _missileThreat = true;
                            _threatLevel = 2; // Highest threat level - active missile
                            diag_log format ["[FLO][AirSupport] MISSILE INBOUND on aircraft %1", _aircraft];
                        };
                    };
                } forEach _nearbyProjectiles;
                
                // If no active missiles, check for potential MANPADS operators
                if (!_missileThreat && count _nearbyMANPADS > 0) then {
                    {
                        // Check if MANPADS operator is facing aircraft and ready to fire
                        private _gunner = _x;
                        private _gunnerDir = getDir _gunner;
                        private _dirToAircraft = _gunner getDir _aircraft;
                        private _angleDiff = abs (_gunnerDir - _dirToAircraft);
                        
                        if (_angleDiff < 45 || _angleDiff > 315) then {
                            // Check LOS to aircraft
                            private _vis = [objNull, "VIEW"] checkVisibility [eyePos _gunner, getPosASL _aircraft];
                            if (_vis > 0.2) then {
                                _missileThreat = true;
                                _threatLevel = 1; // Moderate threat - MANPADS lock likely
                                diag_log format ["[FLO][AirSupport] MANPADS lock detected on aircraft %1 from unit %2", _aircraft, _gunner];
                            };
                        };
                    } forEach _nearbyMANPADS;
                };
                
                // Respond to threats
                if (_missileThreat && !(_obj get "evasionMode")) then {
                    _obj call ["initiateEvasiveAction", [_threatLevel]];
                };
                
                // Check if we need to end evasion mode
                if (_obj get "evasionMode") then {
                    private _currentTime = time;
                    private _evasionStartTime = _obj get "evasionStartTime";
                    private _evasionDuration = _obj get "evasionDuration";
                    
                    if (_currentTime - _evasionStartTime > _evasionDuration) then {
                        _obj call ["endEvasiveAction"];
                    };
                };
                
                sleep 0.5; // Check frequently for threats
            };
            
            _obj set ["threatResponseHandle", scriptNull];
        };
        
        _self set ["threatResponseHandle", _handle];
    }],
    
    ["initiateEvasiveAction", {
        params ["_threatLevel"];
        private _aircraft = _self get "vehicle";
        private _group = _self get "group";
        
        if (!alive _aircraft || (_self get "evasionMode")) exitWith {};
        
        // Set evasion mode flag
        _self set ["evasionMode", true];
        _self set ["evasionStartTime", time];
        
        // Store original altitude for restoration later
        private _originalAlt = _self get "altitude";
        _aircraft setVariable ["FLO_originalAlt", _originalAlt];
        
        // Deploy countermeasures
        [_aircraft] spawn {
            params ["_aircraft"];
            if (!alive _aircraft) exitWith {};
            
            // Find and use countermeasures (flares/chaff)
            private _weapons = weapons _aircraft;
            private _countermeasureWeapon = _weapons select {
                (toLower _x) find "chaff" > -1 || (toLower _x) find "flare" > -1
            };
            
            // Create game logic for firing without animation
            private _logicGroup = createGroup sideLogic;
            private _logic = _logicGroup createUnit ["Logic", [0,0,0], [], 0, "NONE"];
            
            // If countermeasure weapon found, use it
            if (count _countermeasureWeapon > 0) then {
                private _cmWeapon = _countermeasureWeapon select 0;
                private _weaponIndex = _weapons find _cmWeapon;
                
                // Get the unit that will fire (driver or gunner)
                private _shooter = driver _aircraft;
                if (isNull _shooter) then {
                    _shooter = gunner _aircraft;
                };
                
                // Only proceed if we have a shooter
                if (!isNull _shooter) then {
                    // Fire countermeasures multiple times
                    for "_i" from 1 to 3 do {
                        _logic action ["useWeapon", vehicle _aircraft, _shooter, _weaponIndex];
                        sleep 0.5;
                    };
                };
            } else {
                // Fallback: Try to use default countermeasure index (usually 0)
                private _shooter = driver _aircraft;
                if (isNull _shooter) then {
                    _shooter = gunner _aircraft;
                };
                
                if (!isNull _shooter) then {
                    for "_i" from 1 to 3 do {
                        _logic action ["useWeapon", vehicle _aircraft, _shooter, 0];
                        sleep 0.5;
                    };
                };
            };
            
            // Clean up the logic
            deleteVehicle _logic;
            deleteGroup _logicGroup;
        };
        
        // Lower altitude to 10m
        _aircraft flyInHeight 10;
        
        // Clear existing waypoints and set MOVE mode
        while {count waypoints _group > 0} do {
            deleteWaypoint [_group, 0];
        };
        
        // Set combat status to danger and evasive behaviors
        _group setCombatMode "RED";
        _group setBehaviour "COMBAT";
        
        {
            _x setBehaviourStrong "COMBAT";
            _x setUnitCombatMode "RED";
            _x allowFleeing 0;
        } forEach units _group;
        
        // Add evasive waypoint with more erratic movement pattern
        private _currentPos = getPosATL _aircraft;
        
        // Create multiple waypoints in zigzag pattern for more unpredictable evasion
        for "_i" from 1 to 3 do {
            private _escapeDir = (_i * 120) + (random 60); // Create roughly 120° separated directions with randomization
            private _distance = 800 + (random 400); // Varying distances between 800-1200m
            private _escapePos = _currentPos getPos [_distance, _escapeDir];
            _escapePos set [2, 50 + (random 100)]; // Random altitude between 50-150m
            
            private _wp = _group addWaypoint [_escapePos, 0];
            _wp setWaypointType "MOVE";
            _wp setWaypointSpeed "FULL";
            _wp setWaypointCompletionRadius 100; // Larger completion radius for smoother transitions
        }; 
        
        // Final waypoint with more distance to recover
        private _finalEscapePos = _currentPos getPos [2500, random 360];
        _finalEscapePos set [2, 100];
        private _finalWp = _group addWaypoint [_finalEscapePos, 0];
        _finalWp setWaypointType "MOVE";
        _finalWp setWaypointSpeed "NORMAL";
        
        // Notify about evasive action
        diag_log format ["[FLO][AirSupport] Aircraft %1 initiating evasive action", _aircraft];
    }],
    
    ["endEvasiveAction", {
        private _aircraft = _self get "vehicle";
        private _group = _self get "group";
        
        if (!alive _aircraft || !(_self get "evasionMode")) exitWith {};
        
        // Reset evasion mode
        _self set ["evasionMode", false];
        
        // Restore original altitude
        private _originalAlt = _aircraft getVariable ["FLO_originalAlt", _self get "altitude"];
        _aircraft flyInHeight _originalAlt;
        
        // Reset combat status
        _group setCombatMode "GREEN";
        _group setBehaviour "COMBAT";
        
        {
            _x setBehaviourStrong "COMBAT";
            _x setUnitCombatMode "GREEN";
        } forEach units _group;
        
        // Get last known target position or use a safe default
        private _lastTargetPos = _self get "lastTargetPos";
        if (_lastTargetPos isEqualTo [0,0,0]) then {
            // If no last target position, use current position
            _lastTargetPos = getPosASL _aircraft;
        };
        
        // Return to original mission
        _self call ["setupApproach", [_lastTargetPos]];
        
        diag_log format ["[FLO][AirSupport] Aircraft %1 ending evasive action", _aircraft];
    }],
    
    ["executeStrike", {
        params ["_target"];
        private _aircraft = _self get "vehicle";
        private _pilot = driver _aircraft;
        private _gunner = gunner _aircraft;
        private _isTargetInfantry = _target isKindOf "CAManBase";

        if (!isNull _gunner) then {
            _pilot disableAI "TARGET";
        };
        
        if (!alive _aircraft || !alive _target) exitWith {false};
        
        if ((_self get "state") == "ENGAGING" || 
            (time - (_self get "lastEngaged")) < (_self get "cooldownTime")) exitWith {false};
        
        _self set ["state", "ENGAGING"];
        _self set ["currentTarget", _target];
        
        // Special handling for helicopters targeting infantry
        if (_isTargetInfantry && _aircraft isKindOf "Helicopter") then {
            // Enhance crew skills for infantry targeting
            {
                _x setSkill ["aimingAccuracy", 0.8];
                _x setSkill ["aimingSpeed", 0.8];
                _x setSkill ["spotTime", 1];
                _x setSkill ["spotDistance", 1];
            } forEach (crew _aircraft);
            
            // Log that we're targeting infantry
            diag_log format ["[FLO][AirSupport] Helicopter %1 using enhanced infantry targeting profile", _aircraft];
        };
        
        // Store target position for reference - absolutely critical for continued engagement
        private _targetPos = getPosASL _target;
        _self set ["lastTargetPos", _targetPos];
        _self set ["attackInProgress", false]; // Track if an attack run is currently executing

        // Clean up any previous laser target first
        _self call ["cleanupLaser"];
        
        // Get weapon systems
        private _weaponSystems = _aircraft getVariable ["FLO_weaponSystems", []];
        private _selectedWeapon = "";
        private _weaponType = "";
        
        // Get actual distance to target
        private _distance = _aircraft distance _target;
        
        // Function to get weapon range from config
        private _fnc_getWeaponRange = {
            params ["_weapon"];
            private _config = configFile >> "CfgWeapons" >> _weapon;
            private _maxRange = 1000; // Default range
            
            // Try to get range from weapon config
            if (isClass _config) then {
                _maxRange = getNumber (_config >> "maxRange");
                if (_maxRange == 0) then {
                    // Check aiRateOfFire distance as fallback
                    _maxRange = getNumber (_config >> "aiRateOfFireDistance");
                };
                if (_maxRange == 0) then {
                    // Use default ranges based on weapon type
                    private _weaponType = getText (_config >> "simulation");
                    _maxRange = switch (toLower _weaponType) do {
                        case "cannon": { 1500 };
                        case "rockets": { 1200 };
                        case "missilex": { 3000 };
                        case "bomblauncher": { 2000 };
                        default { 1000 };
                    };
                };
            };
            _maxRange
        };
        
        // Prioritize weapon based on target type and range
        private _targetType = typeOf _target;
        private _isArmored = _targetType isKindOf "Tank" || _targetType isKindOf "Wheeled_APC";
        private _isStructure = _targetType isKindOf "Building" || _targetType isKindOf "House";
        private _isGroupTarget = false;
        private _nearbyEnemies = _target nearEntities ["CAManBase", 25];
        if (count (_nearbyEnemies select {side _x != east && alive _x}) > 3) then {
            _isGroupTarget = true;
        };
        
        // Filter weapons based on range first
        _weaponSystems = _weaponSystems select {
            private _weapon = _x select 0;
            private _maxRange = [_weapon] call _fnc_getWeaponRange;
            _distance <= _maxRange
        };
        
        // Choose appropriate weapon based on target type and available weapons
        if (_isArmored && _distance < 3000) then {
            // Use guided missiles against armor if available, or rotatable cannons as second choice
            _weaponSystems = _weaponSystems select {_x select 1 == "MISSILE" || _x select 1 == "ROTATABLE_CANNON"};
            if (count _weaponSystems == 0) then {
                // Allow both fixed-wing and helicopters to use bombs against armor
                _weaponSystems = _aircraft getVariable ["FLO_weaponSystems", []] select {_x select 1 == "BOMB"};
            };
        } else {
            if (_isStructure || _isGroupTarget) then {
                // Use bombs against structures or groups of enemies if available
                _weaponSystems = _weaponSystems select {_x select 1 == "BOMB"};
                if (count _weaponSystems == 0) then {
                    // If no bombs, use rockets for groups or missiles/rotatable cannons for structures
                    if (_isGroupTarget) then {
                        _weaponSystems = _aircraft getVariable ["FLO_weaponSystems", []] select {_x select 1 == "ROCKET"};
                    } else {
                        _weaponSystems = _aircraft getVariable ["FLO_weaponSystems", []] select {_x select 1 == "MISSILE" || _x select 1 == "ROTATABLE_CANNON"};
                    };
                };
            } else {
                if (_distance < 1500) then {
                    // Use cannons/rockets at close range
                    _weaponSystems = _weaponSystems select {_x select 1 == "CANNON" || _x select 1 == "ROCKET" || _x select 1 == "ROTATABLE_CANNON"};
                } else {
                    // Use missiles or rotatable cannons at long range
                    _weaponSystems = _weaponSystems select {_x select 1 == "MISSILE" || _x select 1 == "ROTATABLE_CANNON"};
                    if (count _weaponSystems == 0) then {
                        // Allow both fixed-wing and helicopters to use bombs if no missiles available
                        _weaponSystems = _aircraft getVariable ["FLO_weaponSystems", []] select {_x select 1 == "BOMB"};
                    };
                };
            };
        };
        
        // Fallback to any weapon if no appropriate ones found
        if (count _weaponSystems == 0) then {
            _selectedWeapon = selectRandom (weapons _aircraft);
            _weaponType = "UNKNOWN";
        } else {
            private _selectedSystem = selectRandom _weaponSystems;
            _selectedWeapon = _selectedSystem select 0;
            _weaponType = _selectedSystem select 1;
        };
        
        // Get weapon's actual range from config
        private _weaponRange = [_selectedWeapon] call _fnc_getWeaponRange;
        
        // Create virtual target closer to aircraft if needed
        private _virtualTargetPos = _targetPos;
        private _useVirtualTarget = false;
        
        // For unguided weapons (cannons, rockets), use virtual target to encourage engagement
        if (_weaponType in ["CANNON", "ROCKET", "ROTATABLE_CANNON"]) then {
            if (_distance > _weaponRange) then {
                // Create a virtual target position at 200m like LAMBS
                private _dirToTarget = _aircraft getDir _target;
                _virtualTargetPos = (getPosASL _aircraft) getPos [200, _dirToTarget];
                _virtualTargetPos set [2, (getPosASL _target) select 2];
                _useVirtualTarget = true;
                
                diag_log format ["[FLO][AirSupport] Using virtual target at 200m for weapon with %1m range", round _weaponRange];
            };
        };
        
        // Create or update laser target
        private _laserTarget = createVehicle ["LaserTargetW", ASLToAGL _virtualTargetPos, [], 0, "CAN_COLLIDE"];
        if (_useVirtualTarget) then {
            _laserTarget setPosASL _virtualTargetPos;
        } else {
            _laserTarget attachTo [_target, [0,0,1]];
        };
        _self set ["currentLaser", _laserTarget];
        
        // Always face the aircraft toward the actual target before firing
        _aircraft doWatch _target;
        
        // Special bombing run for aircraft with bombs
        if (_weaponType == "BOMB") then {
            // Keep existing bombing run code
            // Create a bombing run approach
            private _bombingRun = [_self, _target, _selectedWeapon] spawn {
                params ["_obj", "_target", "_weapon"];
                private _aircraft = _obj get "vehicle";
                private _pilot = driver _aircraft;
                private _targetPos = getPosASL _target;
                private _group = group _aircraft;
                
                // Different bombing approaches for helicopters vs. fixed-wing
                if (_aircraft isKindOf "Helicopter") then {
                    // Helicopter bombing parameters - lower altitude
                    private _approachAlt = 100 + (random 50); // Lower altitude for helicopter bombing
                    private _releaseDistance = 400; // Shorter release distance for helicopters
                    private _approachDir = random 360;
                    
                    // Clear waypoints for bombing run
                    while {count waypoints _group > 0} do {
                        deleteWaypoint [_group, 0];
                    };
                    
                    // Try to find approach with clear LOS
                    for "_i" from 0 to 7 do {
                        private _testDir = _i * 45;
                        private _testPos = _targetPos getPos [1000, _testDir];
                        private _vis = terrainIntersectASL [_testPos vectorAdd [0,0,_approachAlt], _targetPos];
                        if (!_vis) exitWith {
                            _approachDir = _testDir;
                        };
                    };
                    
                    // Set up approach position (1km away - shorter for helicopters)
                    private _approachPos = _targetPos getPos [1000, _approachDir + 180];
                    _approachPos set [2, _approachAlt];
                    
                    // Make approach waypoint
                    private _wp1 = _group addWaypoint [_approachPos, 0];
                    _wp1 setWaypointType "MOVE";
                    _wp1 setWaypointSpeed "LIMITED"; // Slower for helicopter precision
                    
                    // Make target waypoint
                    private _flyoverPos = _targetPos getPos [1000, _approachDir];
                    _flyoverPos set [2, _approachAlt];
                    private _wp2 = _group addWaypoint [_flyoverPos, 0];
                    _wp2 setWaypointType "MOVE";
                    
                    // Wait until helicopter is on approach
                    waitUntil {sleep 0.5; _aircraft distance _approachPos < 100 || !alive _aircraft};
                    if (!alive _aircraft) exitWith {};
                    
                    // Stable approach for bombing
                    _aircraft flyInHeight _approachAlt;
                    _aircraft setSpeedMode "LIMITED";
                    _aircraft doWatch _targetPos;
                    
                    // Wait for release point
                    waitUntil {
                        sleep 0.2;
                        private _distToTarget = _aircraft distance _targetPos;
                        (_distToTarget < _releaseDistance) || !alive _aircraft
                    };
                    
                    if (!alive _aircraft) exitWith {};
                    
                    // Release bombs - helicopters typically release one at a time
                    _pilot fireAtTarget [_target, _weapon];
                    
                    // Allow time for bomb impact before continuing
                    sleep 3;
                    if (!alive _aircraft) exitWith {};
                    
                    _obj call ["setupApproach", [_targetPos]];
                    
                    diag_log format ["[FLO][AirSupport] Helicopter bombing run completed at %1", _targetPos];
                } else {
                    // Fixed-wing bombing parameters - same as original code
                    private _approachAlt = 200 + (random 100); // Higher altitude for bombing
                    private _releaseDistance = 600; // Distance before target to release bombs
                    private _approachDir = random 360;
                    
                    // Try to approach from a direction with clear line to target
                    for "_i" from 0 to 7 do {
                        private _testDir = _i * 45;
                        private _testPos = _targetPos getPos [2000, _testDir];
                        private _vis = terrainIntersectASL [_testPos vectorAdd [0,0,_approachAlt], _targetPos];
                        if (!_vis) exitWith {
                            _approachDir = _testDir;
                        };
                    };
                    
                    // Set up approach position (2km away)
                    private _approachPos = _targetPos getPos [2000, _approachDir + 180];
                    _approachPos set [2, _approachAlt];
                    
                    // Clear waypoints for bombing run
                    while {count waypoints _group > 0} do {
                        deleteWaypoint [_group, 0];
                    };
                    
                    // Make approach waypoint
                    private _wp1 = _group addWaypoint [_approachPos, 0];
                    _wp1 setWaypointType "MOVE";
                    _wp1 setWaypointSpeed "NORMAL";
                    
                    // Make target waypoint
                    private _flyoverPos = _targetPos getPos [2000, _approachDir];
                    _flyoverPos set [2, _approachAlt];
                    private _wp2 = _group addWaypoint [_flyoverPos, 0];
                    _wp2 setWaypointType "MOVE";
                    
                    // Wait until aircraft is on approach run
                    waitUntil {sleep 0.5; _aircraft distance _approachPos < 200 || !alive _aircraft};
                    if (!alive _aircraft) exitWith {};
                    
                    // Straight level approach for bombing
                    _aircraft flyInHeight _approachAlt;
                    _aircraft setSpeedMode "NORMAL";
                    _aircraft doWatch _targetPos;
                    
                    // Wait until aircraft is at release point
                    waitUntil {
                        sleep 0.2; 
                        private _distToTarget = _aircraft distance _targetPos;
                        private _velVec = velocity _aircraft;
                        private _speed = vectorMagnitude _velVec;
                        
                        // Calculate release point based on speed and altitude
                        private _releasePoint = _releaseDistance * (_speed / 100);
                        
                        (_distToTarget < _releasePoint || _distToTarget < 400) || !alive _aircraft
                    };
                    
                    if (!alive _aircraft) exitWith {};
                    
                    // Release bombs
                    _pilot fireAtTarget [_target, _weapon];
                    sleep 0.3;
                    _pilot fireAtTarget [_target, _weapon];
                    
                    // Return to normal behavior
                    sleep 5;
                    if (!alive _aircraft) exitWith {};
                    
                    _obj call ["setupApproach", [_targetPos]];
                    
                    diag_log format ["[FLO][AirSupport] Fixed-wing bombing run completed at %1", _targetPos];
                };
            };
        } else {
            // Simplified engagement for cannons, rockets, and missiles
            private _group = group _aircraft;
            
            // Clear existing waypoints
            while {count waypoints _group > 0} do {
                deleteWaypoint [_group, 0];
            };
            
            // Create DESTROY waypoint attached to target
            private _wp = _group addWaypoint [_target, 0];
            _wp setWaypointType "DESTROY";
            _wp synchronizeObjectsAdd _target;
            
            // Fire weapon
            if (!isNull _gunner) then {
                _gunner reveal [_target, 4];
                _gunner doWatch _target;
                _gunner doTarget _target;
                // Wait until aimed at target
                waitUntil {
                    sleep 0.1;
                    if (!alive _aircraft) exitWith {true};
                    private _aimError = if (true) then {
                        _gunner aimedAtTarget [_target]
                    };
                    _aimError > 0.7
                };
                if (!alive _aircraft) exitWith {};
                _gunner fireAtTarget [_target, _selectedWeapon];
            } else {
                _pilot reveal [_target, 4];
                _pilot doWatch _target;
                _pilot doTarget _target;
                // Wait until aimed at target
                waitUntil {
                    sleep 0.1;
                    if (!alive _aircraft) exitWith {true};
                    private _aimError = if (true) then {
                        _pilot aimedAtTarget [_target]
                    };
                    _aimError > 0.7
                };
                if (!alive _aircraft) exitWith {};
                _pilot fireAtTarget [_target, _selectedWeapon];
            };
            
            diag_log format ["[FLO][AirSupport] Direct engagement with %1 against target at %2m", _weaponType, round (_aircraft distance _target)];
        };
        
        _self set ["lastEngaged", time];
        true
    }],
    
    ["cleanupLaser", {
        private _laser = _self get "currentLaser";
        if (!isNull _laser) then {
            detach _laser; // Ensure it's detached before deletion
            deleteVehicle _laser;
            _self set ["currentLaser", objNull];
        };
        
        // Also clean up dummy target if it exists
        private _dummyTarget = _self getOrDefault ["dummyTarget", objNull];
        if (!isNull _dummyTarget) then {
            deleteVehicle _dummyTarget;
            _self set ["dummyTarget", objNull];
        };
    }],
    
    ["scanForTargets", {
        private _aircraft = _self get "vehicle";
        if (!alive _aircraft) exitWith {[]};
        
        private _range = _self get "engagementRange";
        private _missionType = _self get "missionType";
        private _targets = [];
        
        // First try direct target acquisition
        _targets = _aircraft targets [true, _range, [], 0, [west]];
        
        // If no direct targets found, use targetsQuery for enhanced detection
        if (count _targets == 0) then {
            // Parameters for targetsQuery
            private _pos = getPosATL _aircraft;
            private _radius = _range;
            private _angleRange = [0, 360];  // Full circle
            private _typeFilter = ["Car", "Tank", "Man", "Air", "Ship", "StaticWeapon"];
            private _sides = [west];
            
            // Use targetsQuery for enhanced detection
            private _queryResults = _aircraft targetsQuery [
                _pos,           // center position
                _angleRange,    // angle range [min, max]
                _typeFilter,    // target type filter
                _sides,         // target sides
                _radius,        // radius
                0              // max targets (0 = unlimited)
            ];
            
            // Process query results
            {
                _x params ["_target", "_accuracy"];
                if (alive _target && {side _target == west}) then {
                    // Enhance knowledge about target for aircraft and crew
                    {
                        _x reveal [_target, 4];
                        private _currentKnowledge = _x knowsAbout _target;
                        if (_currentKnowledge < 4) then {
                            _x reveal [_target, 4];
                        };
                    } forEach (crew _aircraft);
                    
                    _targets pushBackUnique _target;
                };
            } forEach _queryResults;
        };
        
        // Sort targets by priority and distance
        _targets = [_targets, [], {
            private _target = _x;
            private _distance = _aircraft distance _target;
            private _priority = switch (true) do {
                case (_target isKindOf "Tank" || _target isKindOf "Wheeled_APC"): { 10 };
                case (_target isKindOf "Car" || _target isKindOf "Truck"): { 5 };
                case (_target isKindOf "CAManBase"): { 1 };
                default { 0 };
            };
            (_distance / 100) - (_priority * 10)
        }, "ASCEND"] call BIS_fnc_sortBy;
        
        // Log target detection
        if (count _targets > 0) then {
            diag_log format ["[FLO][AirSupport] Aircraft %1 detected %2 targets using enhanced detection", _aircraft, count _targets];
        };
        
        _targets
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
    
    ["checkRemainingWeapons", {
        private _aircraft = _self get "vehicle";
        if (!alive _aircraft) exitWith {[]};
        
        // Get weapon systems
        private _weaponSystems = _aircraft getVariable ["FLO_weaponSystems", []];
        private _remainingWeapons = [];
        
        // Check each weapon system for remaining ammo
        {
            _x params ["_weapon", "_weaponType", "_magazines"];
            private _hasAmmo = false;
            
            // Check if any of the weapon's magazines have ammo
            {
                if (_aircraft ammo _weapon > 0 || {_aircraft magazineTurretAmmo [_x, [-1]] > 0}) exitWith {
                    _hasAmmo = true;
                };
            } forEach _magazines;
            
            // Add to remaining weapons if it has ammo
            if (_hasAmmo) then {
                _remainingWeapons pushBack [_weapon, _weaponType, _magazines];
            };
        } forEach _weaponSystems;
        
        // Store the result for quick reference
        _aircraft setVariable ["FLO_remainingWeapons", _remainingWeapons];
        _remainingWeapons
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
        
        // Check remaining weapons periodically (every 10 seconds)
        private _lastWeaponCheck = _self get "FLO_lastWeaponCheckTime";
        if (time - _lastWeaponCheck >= 10) then {
            _self set ["FLO_lastWeaponCheckTime", time];
            private _remainingWeapons = _self call ["checkRemainingWeapons"];
            private _bombsRemain = false;
            
            // Check if we have any bombs left
            {
                _x params ["_weapon", "_weaponType"];
                if (_weaponType == "BOMB") exitWith {
                    _bombsRemain = true;
                };
            } forEach _remainingWeapons;
            
            // If we have bombs, adjust altitude for bombing runs
            if (_bombsRemain) then {
                if (_aircraft isKindOf "Helicopter") then {
                    _aircraft flyInHeight 100;
                } else {
                    _aircraft flyInHeight 200;
                };
            } else {
                // If no bombs, use standard altitude
                _aircraft flyInHeight (_self get "altitude");
            };
        };
        
        switch (_state) do {
            case "APPROACHING": {
                private _targets = _self call ["scanForTargets"];
                
                if (count _targets > 0) then {
                    private _target = _targets select 0;
                    _self set ["currentTarget", _target];
                    _self set ["lastTargetPos", getPosASL _target];
                    
                    if (_self call ["executeStrike", [_target]]) then {
                        _self set ["state", "ENGAGING"];
                        _self set ["engagementStartTime", time];
                    };
                };
            };
            case "ENGAGING": {
                private _currentTarget = _self get "currentTarget";
                private _timeSinceLastEngagement = time - (_self get "lastEngaged");
                
                if (!alive _currentTarget || _timeSinceLastEngagement > (_self get "cooldownTime")) then {
                    _self call ["cleanupLaser"];
                    _self set ["state", "APPROACHING"];
                    _self set ["currentTarget", objNull];
                };
            };
        };
        true
    }],
    ["checkKnownEnemies", {
        private _aircraft = _self get "vehicle";
        if (!alive _aircraft) exitWith {[]};
        
        private _knownTargets = [];
        private _maxKnowledgeDistance = 12000;
        
        // Get all nearby OPFOR units that might share knowledge
        private _friendlyUnits = allUnits select {
            side _x == east && 
            alive _x && 
            _x != _aircraft && 
            _x distance _aircraft < _maxKnowledgeDistance
        };
        
        // Use targetsQuery for each friendly unit to get their known targets
        {
            private _unit = _x;
            private _pos = getPosATL _unit;
            private _radius = 5000; // Reasonable detection range for ground units
            
            private _queryResults = _unit targetsQuery [
                _pos,
                [0, 360],
                ["Car", "Tank", "Man", "Air", "Ship", "StaticWeapon"],
                [west],
                _radius,
                0
            ];
            
            // Process results and share knowledge
            {
                _x params ["_target", "_accuracy"];
                if (alive _target && {side _target == west}) then {
                    // Get unit's knowledge of target
                    private _knowledge = _unit knowsAbout _target;
                    
                    if (_knowledge > 1.5) then {
                        // Share knowledge with aircraft crew
                        {
                            _x reveal [_target, (_knowledge min 4)];
                            // Double reveal to ensure knowledge transfer
                            if ((_x knowsAbout _target) < (_knowledge min 4)) then {
                                _x reveal [_target, (_knowledge min 4)];
                            };
                        } forEach (crew _aircraft);
                        
                        _knownTargets pushBackUnique _target;
                    };
                };
            } forEach _queryResults;
        } forEach _friendlyUnits;
        
        // Log knowledge sharing results
        if (count _knownTargets > 0) then {
            diag_log format ["[FLO][AirSupport] Knowledge sharing revealed %1 targets to aircraft %2", 
                count _knownTargets, _aircraft];
        };
        
        _knownTargets
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
        case "CAS": {"STR_FLO_WARNING_ECAS"};
        case "STRIKE": {"STR_FLO_WARNING_ESTRIKE"};
        default {"ESTR_FLO_WARNING_EAIR"};
    };
    
    ["STR_FLO_WARNING_TITLE", _notificationText, "warning"] call FLO_fnc_sendNotification;
};

_airSupport