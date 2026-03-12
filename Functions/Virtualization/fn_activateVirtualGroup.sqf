/*
 * Function: FLO_fnc_activateVirtualGroup
 * Author: Frontline Operations Development Group
 * Description:
 * Activates a virtual group by spawning it in the game world.
 *
 * Arguments:
 * 0: Group ID <STRING> - Unique identifier for the virtual group
 * 1: Group Data <HASHMAP> - HashMap containing group data
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * ["vgroup_1", _groupData] call FLO_fnc_activateVirtualGroup;
 */

params ["_groupId", "_groupData"];

// Ensure we're running on the server
if (!isServer) exitWith {false};

// Check if this group is attached to a transport
private _attachedTo = _groupData get "attachedTo"; 
if (_attachedTo != "") then {
    ["VIRTUALIZATION", 2, format["WARNING: Activating group %1 which claims to be attached to %2. This implies logic failure upstream.", _groupId, _attachedTo]] call FLO_fnc_log;
};

["VIRTUALIZATION", 3, format["Activating virtual group %1", _groupId]] call FLO_fnc_log;

// Extract data from group
private _position = _groupData get "position";
private _groupType = _groupData get "groupType";
private _side = _groupData get "side";
private _groupCfg = _groupData get "groupCfg";
private _allWaypoints = _groupData get "waypoints";  
private _currentWpIdx = _groupData get "currentWaypointIndex";
private _comp = _groupData get "comp";
private _realGroup = grpNull;

private _sideCtx = [_side] call FLO_fnc_gtnSideContext;
private _sideKey = _sideCtx get "sideKey";
private _catalog = if (!isNil "FLO_FactionCatalog") then {
    FLO_FactionCatalog getOrDefault [_sideKey, createHashMap]
} else {
    createHashMap
};

private _poolGroups = _catalog getOrDefault ["groups", if (!isNil "East_Groups") then { East_Groups } else { [] }];
private _poolUnits = _catalog getOrDefault ["units", if (!isNil "East_Units") then { East_Units } else { [] }];
private _poolGroundLight = _catalog getOrDefault ["groundLight", if (!isNil "East_Ground_Vehicles_Light") then { East_Ground_Vehicles_Light } else { [] }];
private _poolGroundHeavy = _catalog getOrDefault ["groundHeavy", if (!isNil "East_Ground_Vehicles_Heavy") then { East_Ground_Vehicles_Heavy } else { [] }];
private _poolArty = _catalog getOrDefault ["groundArtillery", if (!isNil "East_Ground_Artillery") then { East_Ground_Artillery } else { [] }];
private _poolHeli = _catalog getOrDefault ["airHeli", if (!isNil "East_Air_Heli") then { East_Air_Heli } else { [] }];
private _poolJet = _catalog getOrDefault ["airJet", if (!isNil "East_Air_Jet") then { East_Air_Jet } else { [] }];
private _poolMobileAA = _catalog getOrDefault ["mobileAA", if (!isNil "East_Mobile_AA") then { East_Mobile_AA } else { [] }];
private _poolStaticAA = _catalog getOrDefault ["staticAA", if (!isNil "East_Static_AA") then { East_Static_AA } else { [] }];
private _poolRadar = _catalog getOrDefault ["radar", if (!isNil "East_Radar") then { East_Radar } else { [] }];

if (count _poolUnits == 0) then { _poolUnits = ["O_Soldier_F"] };
if (count _poolGroundLight == 0) then { _poolGroundLight = ["B_MRAP_01_F"] };
if (count _poolGroundHeavy == 0) then { _poolGroundHeavy = +_poolGroundLight };
if (count _poolArty == 0) then { _poolArty = +_poolGroundHeavy };
if (count _poolHeli == 0) then { _poolHeli = ["B_Heli_Light_01_F"] };
if (count _poolJet == 0) then { _poolJet = +_poolHeli };
if (count _poolMobileAA == 0) then { _poolMobileAA = +_poolGroundHeavy };
if (count _poolStaticAA == 0) then { _poolStaticAA = +_poolMobileAA };

// Check if the group is significantly closer to a later waypoint than the current one.
// This indicates that waypoints were not deleted properly during virtual movement.
if (_currentWpIdx == 0 && count _allWaypoints > 1) then {
    private _nearestDist = 999999;
    private _nearestIdx = -1;
    
    {
        private _wPos = _x select 0;
        private _dist = _wPos distance2D _position;
        if (_dist < _nearestDist) then {
            _nearestDist = _dist;
            _nearestIdx = _forEachIndex;
        };
    } forEach _allWaypoints;

    // If the unit is closer to a later waypoint (index > 0) and the distance difference is significant (e.g. > 100m closer)
    // AND the unit is actually somewhat close to that later waypoint (< 500m)
    if (_nearestIdx > 0) then {
        private _distToFirst = (_allWaypoints select 0 select 0) distance2D _position;
        if (_nearestDist < 500 && _distToFirst > (_nearestDist + 200)) then {
             ["VIRTUALIZATION", 2, format["WARNING: Group %1 activating with potentially stale waypoints! CurrentIdx: 0, NearestIdx: %2 (Dist: %3m vs First: %4m). Root cause: Virtual waypoints likely not deleting.", 
                _groupId, _nearestIdx, round _nearestDist, round _distToFirst]] call FLO_fnc_log;
        };
    };
};

// Only use remaining waypoints from currentWaypointIndex onwards
// This ensures groups that traveled virtually don't re-get completed waypoints
private _waypoints = if (_currentWpIdx > 0 && _currentWpIdx < count _allWaypoints) then {
    _allWaypoints select [_currentWpIdx, count _allWaypoints - _currentWpIdx]
} else {
    _allWaypoints
};

// Reset currentWaypointIndex since we're now using real waypoints
_groupData set ["currentWaypointIndex", 0];

// Check if this is a transport with attached groups
private _isTransport = _groupData get "isTransport";
private _attachedGroups = _groupData get "attachedGroups";

// Ensure we don't spawn on top of players
_position = [_position] call FLO_fnc_getSafeUnvirtualizePos;
_groupData set ["position", _position];

// Get group data
private _unitCount = _groupData get "unitCount";

// Create the actual group based on group type
switch (true) do {    
    // If we have a saved composition, use it to recreate the group exactly
    case (_comp isNotEqualTo []): {
        _realGroup = createGroup [_side, true];
        {
            private _unitType = _x;
            [_realGroup, _unitType, _position, _side, _groupType] call FLO_fnc_activateSavedVirtualGroup;
        } forEach _comp;
    };

    // Infantry - try group configs first, fallback to side unit pool
    case (_groupType isEqualTo "infantry"): {
        // Try group configs if available and valid
        if (_groupCfg isEqualType [] && {count _groupCfg > 0}) then {
            private _selectedCfg = selectRandom _groupCfg;
            if (isClass _selectedCfg) then {
                _realGroup = [_position, _side, _selectedCfg] call BIS_fnc_spawnGroup;
            };
        };

        // Fallback to side unit pool if no group spawned
        if (isNull _realGroup || {count units _realGroup == 0}) then {
            if (!isNull _realGroup) then { deleteGroup _realGroup; };

            _realGroup = createGroup [_side, true];
            private _spawnCount = if (_unitCount > 0) then { _unitCount } else { 6 };

            for "_i" from 1 to _spawnCount do {
                private _unitType = selectRandom _poolUnits;
                private _spawnPos = [_position, 5, 20, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;
                private _unit = _realGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
            };
        };
    };
    
    // Civilian group - delegate to Civilian module
    case (_groupType in ["civilian", "civ_pedestrian", "civ_building"]): {
        _realGroup = [_groupId, _groupData, _position] call FLO_fnc_activateCivilian;
    };
    
    // Vehicle groups
    case (_groupType in ["motorized", "mechanized", "armor"]): {
        _realGroup = createGroup [_side, true];

        for "_i" from 1 to _unitCount do {
            private _vehicleType = "";

            // Select appropriate vehicle type
            switch (_groupType) do {
                case "motorized": { _vehicleType = selectRandom _poolGroundLight; };
                case "mechanized": { _vehicleType = selectRandom _poolGroundHeavy; };
                case "armor": { _vehicleType = selectRandom _poolGroundHeavy; };
                default { _vehicleType = selectRandom _poolGroundLight; };
            };

            // Find safe position for vehicle with larger radius and vehicle-appropriate spacing
            private _minDist = 10 + (20 * _i);
            private _spawnPos = [_position, _minDist, 150, 10, 0, 0.2, 0] call BIS_fnc_findSafePos;

            // Validate spawn position - BIS_fnc_findSafePos can return bad positions
            // Check for: too far away, near map origin, or invalid array
            private _spawnValid = true;
            if (!(_spawnPos isEqualType []) || {count _spawnPos < 2}) then {
                _spawnValid = false;
            } else {
                // Too far from intended position (should be within 150m max radius)
                if (_spawnPos distance2D _position > 200) then { _spawnValid = false; };
                // Near map origin (indicates failure)
                if ((_spawnPos select 0) < 100 && (_spawnPos select 1) < 100) then { _spawnValid = false; };
            };

            // Fallback to simple offset from position
            if (!_spawnValid) then {
                _spawnPos = _position getPos [_minDist, random 360];
                _spawnPos set [2, 0];
                ["VIRTUALIZATION", 2, format["Vehicle spawn fallback used for group %1 - findSafePos failed", _groupId]] call FLO_fnc_log;
            };

            // Create vehicle
            private _vehicle = createVehicle [_vehicleType, _spawnPos, [], 0, "NONE"];
            
            // Ensure vehicle is grounded properly
            _vehicle setPos [getPos _vehicle select 0, getPos _vehicle select 1, 0];
            _vehicle setVectorUp [0,0,1];
            
            // Create crew manually to avoid redundant group creation/deletion (fixes 112/116 errors)
            private _crewType = getText (configFile >> "CfgVehicles" >> _vehicleType >> "crew");
            if (_crewType == "") then { _crewType = selectRandom _poolUnits; };

            // Driver
            private _driver = _realGroup createUnit [_crewType, _spawnPos, [], 0, "NONE"];
            _driver moveInDriver _vehicle;
            
            // Turrets (Gunner, Commander, etc - excluding FFV)
            {
               private _gunner = _realGroup createUnit [_crewType, _spawnPos, [], 0, "NONE"];
               _gunner moveInTurret [_vehicle, _x];
            } forEach (allTurrets [_vehicle, false]);
        };
    };
    
    // Air groups (helicopters and jets)
    case (_groupType in ["helicopter", "jet", "air"]): {
        _realGroup = createGroup [_side, true];
        
        for "_i" from 1 to _unitCount do {
            private _aircraftType = "";
            
            // Select appropriate aircraft type
            switch (_groupType) do {
                case "helicopter": { _aircraftType = selectRandom _poolHeli; };
                case "jet": { _aircraftType = selectRandom _poolJet; };
                case "air": { _aircraftType = selectRandom (_poolHeli + _poolJet); };
                default { _aircraftType = selectRandom _poolHeli; };
            };
            
            // Find appropriate spawn height for air vehicles
            private _spawnHeight = 0;
            if (_groupType isEqualTo "jet") then { _spawnHeight = 500; } else { _spawnHeight = 100; };
            
            // Spread out aircraft spawns
            private _spreadDistance = 50 * _i;
            private _spawnPos = [(_position select 0) + _spreadDistance, (_position select 1), _spawnHeight];
            
            // Direct Spawn (No Temp Group)
            private _vehicle = createVehicle [_aircraftType, _spawnPos, [], 0, "FLY"];
            
            // Create crew manually
            private _crewType = getText (configFile >> "CfgVehicles" >> _aircraftType >> "crew");
            if (_crewType == "") then { _crewType = selectRandom _poolUnits; };

            // Driver/Pilot
            private _driver = _realGroup createUnit [_crewType, [0,0,0], [], 0, "NONE"];
            _driver moveInDriver _vehicle;
            
            // Turrets
            {
               private _gunner = _realGroup createUnit [_crewType, [0,0,0], [], 0, "NONE"];
               _gunner moveInTurret [_vehicle, _x];
            } forEach (allTurrets [_vehicle, false]);
        };
    };
    
    // Artillery groups
    case (_groupType isEqualTo "artillery"): {
        _realGroup = createGroup [_side, true];

        for "_i" from 1 to _unitCount do {
            private _artilleryType = selectRandom _poolArty;

            // Find safe position for artillery with larger spacing (artillery needs more room)
            private _minDist = 15 + (25 * _i);
            private _spawnPos = [_position, _minDist, 150, 12, 0, 0.15, 0] call BIS_fnc_findSafePos;

            // Validate spawn position
            private _spawnValid = true;
            if (!(_spawnPos isEqualType []) || {count _spawnPos < 2}) then {
                _spawnValid = false;
            } else {
                if (_spawnPos distance2D _position > 200) then { _spawnValid = false; };
                if ((_spawnPos select 0) < 100 && (_spawnPos select 1) < 100) then { _spawnValid = false; };
            };

            // Fallback if position search failed
            if (!_spawnValid) then {
                _spawnPos = _position getPos [_minDist, random 360];
                _spawnPos set [2, 0];
                ["VIRTUALIZATION", 2, format["Artillery spawn fallback used for group %1", _groupId]] call FLO_fnc_log;
            };

            // Create vehicle
            private _vehicle = createVehicle [_artilleryType, _spawnPos, [], 0, "NONE"];

            // Ensure artillery is grounded properly
            _vehicle setPos [getPos _vehicle select 0, getPos _vehicle select 1, 0];
            _vehicle setVectorUp [0,0,1];
            
            // Create crew manually
            private _crewType = getText (configFile >> "CfgVehicles" >> _artilleryType >> "crew");
            if (_crewType == "") then { _crewType = selectRandom _poolUnits; };

            // Driver
            private _driver = _realGroup createUnit [_crewType, _spawnPos, [], 0, "NONE"];
            _driver moveInDriver _vehicle;
            
            // Turrets
            {
               private _gunner = _realGroup createUnit [_crewType, _spawnPos, [], 0, "NONE"];
               _gunner moveInTurret [_vehicle, _x];
            } forEach (allTurrets [_vehicle, false]);
        };
    };
    
    // Mobile AA groups
    case (_groupType isEqualTo "mobile_aa"): {
        _realGroup = createGroup [_side, true];
        
        for "_i" from 1 to _unitCount do {
            private _aaType = selectRandom _poolMobileAA;
            
            private _minDist = 10 + (20 * _i);
            private _spawnPos = [_position, _minDist, 100, 8, 0, 0.2, 0] call BIS_fnc_findSafePos;
            
            if (_spawnPos distance2D _position > 150) then {
                _spawnPos = _position getPos [_minDist, random 360];
            };
            
            private _vehicle = createVehicle [_aaType, _spawnPos, [], 0, "NONE"];
            _vehicle setPos [getPos _vehicle select 0, getPos _vehicle select 1, 0];
            _vehicle setVectorUp [0,0,1];
            
            private _crewType = getText (configFile >> "CfgVehicles" >> _aaType >> "crew");
            if (_crewType == "") then { _crewType = selectRandom _poolUnits; };
            
            private _driver = _realGroup createUnit [_crewType, _spawnPos, [], 0, "NONE"];
            _driver moveInDriver _vehicle;
            
            {
               private _gunner = _realGroup createUnit [_crewType, _spawnPos, [], 0, "NONE"];
               _gunner moveInTurret [_vehicle, _x];
            } forEach (allTurrets [_vehicle, false]);
        };
    };
    
    // Static AA groups
    case (_groupType isEqualTo "static_aa"): {
        _realGroup = createGroup [_side, true];
        
        // Find safe open position (avoid buildings)
        private _safePos = [_position, 20, 100, 15, 0, 0.1, 0] call BIS_fnc_findSafePos;
        if (_safePos distance2D _position > 150) then { _safePos = _position; };
        
        // Spawn Radar if available
        if (count _poolRadar > 0) then {
            private _radarType = selectRandom _poolRadar;
            private _radarPos = _safePos getPos [15, random 360];
            private _radar = createVehicle [_radarType, _radarPos, [], 0, "NONE"];
            _radar setPos [getPos _radar select 0, getPos _radar select 1, 0];
            
            // Enable data link: Radar reports targets to side center
            _radar setVehicleReportRemoteTargets true;
            _radar setVehicleRadar 1; // Active radar
            
            // Radar operator (required for data link to function)
            private _crewType = getText (configFile >> "CfgVehicles" >> _radarType >> "crew");
            if (_crewType == "") then { _crewType = selectRandom _poolUnits; };
            private _operator = _realGroup createUnit [_crewType, _radarPos, [], 0, "NONE"];
            _operator moveInAny _radar;
        };
        
        // Spawn SAM Launchers
        for "_i" from 1 to _unitCount do {
            private _samType = selectRandom _poolStaticAA;
            
            private _offset = 25 + (15 * _i);
            private _angle = (360 / _unitCount) * _i;
            private _spawnPos = _safePos getPos [_offset, _angle];
            
            private _launcher = createVehicle [_samType, _spawnPos, [], 0, "NONE"];
            _launcher setPos [getPos _launcher select 0, getPos _launcher select 1, 0];
            _launcher setDir (_angle + 180); // Face outward
            
            // Enable data link: SAM receives targets from radar
            _launcher setVehicleReceiveRemoteTargets true;
            
            // Crew for manned launchers
            private _crewType = getText (configFile >> "CfgVehicles" >> _samType >> "crew");
            if (_crewType != "") then {
                private _gunner = _realGroup createUnit [_crewType, _spawnPos, [], 0, "NONE"];
                _gunner moveInGunner _launcher;
            };
        };
        
        // Mark as static defense - no waypoints, no commander movement
        _groupData set ["noWaypoints", true];
    };
    
    // Civilian vehicle group - delegate to Civilian module
    case (_groupType in ["civilianVehicle", "civ_car"]): {
        _realGroup = [_groupId, _groupData, _position] call FLO_fnc_activateCivilian;
    };
    
    // Default case if we don't recognize the group type
    default {
        ["VIRTUALIZATION", 2, format["Unknown group type %1 for virtual group %2", _groupType, _groupId]] call FLO_fnc_log;
        _realGroup = createGroup [_side, true];
        private _unitType = selectRandom _poolUnits;
        private _unit = _realGroup createUnit [_unitType, _position, [], 0, "NONE"];
    };
};

// ========================================================================
// SIDE FIX - Ensure all units are on the correct side
// This handles cases where mission makers use BLUFOR classnames as OPFOR enemies
// The units' classname side doesn't matter - their group side determines allegiance
// ========================================================================
if (!isNull _realGroup && {_side in [east, west, independent]} && {_side != civilian}) then {
    _realGroup = [_realGroup, _side] call FLO_fnc_setSide;
};

// Distribute intel items to non-civilian groups
if !(_groupType in ["civilian", "civilianVehicle"]) then {
    private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
    private _units = units _realGroup;
    if (count _units > 0) then {
        private _selectedUnits = _units call BIS_fnc_arrayShuffle;
        _selectedUnits resize (floor (count _selectedUnits / 2) max 1);
        {
            if (random 1 < 0.3) then { // 30% chance per selected unit
                _x addItem selectRandom _intelItems;
            };
        } forEach _selectedUnits;
    };
};

// Set the real group in the group data
_groupData set ["realGroup", _realGroup];
_groupData set ["isActive", true];
_groupData set ["lastStateChangeTime", diag_tickTime];

// ========================================================================
// TRANSPORT PASSENGER LOADING
// If this is a transport with attached groups, spawn passengers and load them
// ========================================================================
if (_isTransport && count _attachedGroups > 0) then {
    ["VIRTUALIZATION", 3, format["Transport %1 spawning with %2 attached groups", _groupId, count _attachedGroups]] call FLO_fnc_log;

    // Get the transport vehicle(s)
    private _transportVehicles = (units _realGroup) select {vehicle _x != _x};
    _transportVehicles = _transportVehicles apply {vehicle _x};
    _transportVehicles = _transportVehicles arrayIntersect _transportVehicles; // Remove duplicates

    // If no vehicles found, get vehicles from group
    if (count _transportVehicles == 0) then {
        _transportVehicles = [];
        {
            private _veh = vehicle _x;
            if (_veh != _x && !(_veh in _transportVehicles)) then {
                _transportVehicles pushBack _veh;
            };
        } forEach units _realGroup;
    };

    private _groups = FLO_virtualGroups get "_groups";

    // Spawn and load each attached infantry group
    {
        private _attachedId = _x;
        private _attachedData = _groups get _attachedId;

        if (!isNil "_attachedData") then {
            private _infSide = _attachedData get "side";
            private _infComp = _attachedData get "comp";
            private _infUnitCount = _attachedData get "unitCount";
            private _infGroup = createGroup [_infSide, true];

            // Create infantry units
            if (_infComp isNotEqualTo []) then {
                {
                    private _unitType = _x;
                    private _unit = _infGroup createUnit [_unitType, _position, [], 0, "NONE"];
                } forEach _infComp;
            } else {
                for "_i" from 1 to _infUnitCount do {
                    private _unitType = selectRandom _poolUnits;
                    private _unit = _infGroup createUnit [_unitType, _position, [], 0, "NONE"];
                };
            };

            // Load infantry into transport vehicles
            if (count _transportVehicles > 0) then {
                private _vehicleIndex = 0;
                {
                    private _unit = _x;
                    private _vehicle = _transportVehicles select _vehicleIndex;

                    // Check if vehicle has cargo space
                    private _emptySeats = _vehicle emptyPositions "cargo";
                    if (_emptySeats > 0) then {
                        _unit moveInCargo _vehicle;
                    } else {
                        // Try next vehicle
                        _vehicleIndex = (_vehicleIndex + 1) mod (count _transportVehicles);
                        private _nextVeh = _transportVehicles select _vehicleIndex;
                        if (_nextVeh emptyPositions "cargo" > 0) then {
                            _unit moveInCargo _nextVeh;
                        };
                    };
                } forEach units _infGroup;
            };

            // Mark attached group as active with its own real group
            _attachedData set ["realGroup", _infGroup];
            _attachedData set ["isActive", true];
            _attachedData set ["lastStateChangeTime", diag_tickTime];
            _attachedData set ["mountedIn", _groupId]; // Track that they're mounted

            ["VIRTUALIZATION", 3, format["Loaded attached group %1 (%2 units) into transport %3",
                _attachedId, count units _infGroup, _groupId]] call FLO_fnc_log;
        };
    } forEach _attachedGroups;
};

// Disable AI pathfinding if objective is civ_building
private _objective = _groupData get "objective";
if (_objective isEqualTo "civ_building") then {
    {
        _x disableAI "PATH";
        _x disableAI "MOVE";
    } forEach units _realGroup;
};

// Check if group has patrol config - use taskPatrol instead of CYCLE waypoints
private _patrolConfig = _groupData getOrDefault ["patrolConfig", []];
if (_patrolConfig isNotEqualTo []) then {
    // Use taskPatrol for looping patrols - avoids CYCLE waypoint bugs
    _patrolConfig params ["_patrolCenter", "_patrolRadius", "_wpCount", "_behavior", "_speed"];
    [_realGroup, _patrolCenter, _patrolRadius, _wpCount, _behavior, _speed] call FLO_fnc_taskPatrol;
    ["VIRTUALIZATION", 3, format["Group %1: Applied taskPatrol (center %2, radius %3)", _groupId, _patrolCenter, _patrolRadius]] call FLO_fnc_log;
} else {
    // Apply waypoints if any
    // NOTE: SAD, DESTROY, and GUARD waypoints NEVER complete in Arma's waypoint system
    // We convert these to MOVE + aggressive combat settings so groups reach destination
    // Skip if group is marked as static defense (noWaypoints)
    private _noWaypoints = _groupData getOrDefault ["noWaypoints", false];
    if (!_noWaypoints && {count _waypoints > 0}) then {
        // Safety check: if first waypoint is CYCLE, that's invalid for Arma
        private _firstWpType = (_waypoints select 0) select 1;
        if (_firstWpType == "CYCLE" && count _waypoints == 1) then {
            ["VIRTUALIZATION", 2, format["Group %1 has only CYCLE waypoint - skipping", _groupId]] call FLO_fnc_log;
        } else {
            // Check if original waypoints included a CYCLE (meaning group should loop)
            private _hadCycle = (_waypoints findIf { (_x select 1) == "CYCLE" }) != -1;

            // Filter out CYCLE waypoints - they cause bugs and we use setCurrentWaypoint for loops
            private _filteredWaypoints = _waypoints select { (_x select 1) != "CYCLE" };

            {
                private _wpPos = _x select 0;
                private _wpType = _x select 1;
                private _wpBehavior = _x select 2;
                private _wpSpeed = _x select 3;
                private _wpFormation = _x select 4;
                private _wpMode = _x select 5;
                private _wpCompletionRadius = _x param [6, 20];

                // Convert non-completing waypoint types to MOVE
                private _effectiveType = switch (_wpType) do {
                    case "SAD": { _wpBehavior = "COMBAT"; _wpMode = "RED"; "MOVE" };
                    case "DESTROY": { _wpBehavior = "COMBAT"; _wpMode = "RED"; "MOVE" };
                    case "GUARD": { _wpBehavior = "COMBAT"; _wpMode = "RED"; "HOLD" };
                    default { _wpType };
                };

                private _wp = _realGroup addWaypoint [_wpPos, 0];
                _wp setWaypointType _effectiveType;
                _wp setWaypointBehaviour _wpBehavior;
                _wp setWaypointSpeed _wpSpeed;
                _wp setWaypointFormation _wpFormation;
                _wp setWaypointCombatMode _wpMode;
                _wp setWaypointCompletionRadius _wpCompletionRadius;

                if (_wpType != _effectiveType) then {
                    ["VIRTUALIZATION", 4, format["Group %1: Converted %2 to %3", _groupId, _wpType, _effectiveType]] call FLO_fnc_log;
                };
            } forEach _filteredWaypoints;

            // If we filtered out a CYCLE, make the last waypoint loop back to first
            // This allows pedestrians/civilians to continuously walk their routes
            if (_hadCycle && count waypoints _realGroup > 1) then {
                private _lastWp = [_realGroup, (count waypoints _realGroup) - 1];
                _lastWp setWaypointStatements [
                    "true",
                    format ["(group this) setCurrentWaypoint [(group this), %1];", 1]
                ];
                ["VIRTUALIZATION", 4, format["Group %1: Added loop statement to last waypoint (replacing filtered CYCLE)", _groupId]] call FLO_fnc_log;
            };
        };
    };
};

// Fire activation event for GTN/AI Commander integration
["FLO_Virtualization_GroupActivated", [_groupId, _groupData, _realGroup]] call CBA_fnc_localEvent;

["VIRTUALIZATION", 3, format["Activated virtual group: %1 with %2 units", _groupId, count units _realGroup]] call FLO_fnc_log;

// Return success
true
