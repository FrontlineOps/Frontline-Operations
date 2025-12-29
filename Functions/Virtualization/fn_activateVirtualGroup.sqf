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

// Check if this group is attached to a transport - skip activation (transport spawns passengers)
private _attachedTo = _groupData getOrDefault ["attachedTo", ""];
if (_attachedTo != "") exitWith {
    ["VIRTUALIZATION", 3, format["Group %1 is attached to transport %2 - skipping individual activation",
        _groupId, _attachedTo]] call FLO_fnc_log;
    false
};

["VIRTUALIZATION", 3, format["Activating virtual group %1", _groupId]] call FLO_fnc_log;

// Extract data from group
private _position = _groupData get "position";
private _groupType = _groupData get "groupType";
private _side = _groupData get "side";
private _groupCfg = _groupData getOrDefault ["groupCfg", objNull];
private _waypoints = _groupData getOrDefault ["waypoints", []];
private _comp = _groupData getOrDefault ["comp", []];
private _realGroup = grpNull;

// Check if this is a transport with attached groups
private _isTransport = _groupData getOrDefault ["isTransport", false];
private _attachedGroups = _groupData getOrDefault ["attachedGroups", []];

// Validate position - skip activation if position is invalid
if (isNil "_position" || {!(_position isEqualType [])} || {count _position < 2}) exitWith {
    ["VIRTUALIZATION", 1, format["ERROR: Group %1 has invalid position (nil or wrong type) - skipping activation", _groupId]] call FLO_fnc_log;
    false
};

// Check for [0,0,0] or near map origin - this indicates a failed position lookup
if ((_position select 0) < 100 && (_position select 1) < 100) exitWith {
    ["VIRTUALIZATION", 1, format["ERROR: Group %1 has position near origin %2 - skipping activation", _groupId, _position]] call FLO_fnc_log;
    false
};

// Ensure we don't spawn on top of players
_position = [_position] call FLO_fnc_getSafeUnvirtualizePos;
_groupData set ["position", _position];

// Get group data
private _unitCount = _groupData get "unitCount";
if (isNil "_unitCount") then {
    diag_log format ["[VIRTUALIZATION] ERROR: Group %1 has UNDEFINED FUCKING UNIT COUNT. FIX IT! Setting to 1.", _groupId];
    _unitCount = 1;
};

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

    // Infantry - try group configs first, fallback to East_Units
    case (_groupType isEqualTo "infantry"): {
        // Try group configs if available and valid
        if (_groupCfg isEqualType [] && {count _groupCfg > 0}) then {
            private _selectedCfg = selectRandom _groupCfg;
            if (isClass _selectedCfg) then {
                _realGroup = [_position, _side, _selectedCfg] call BIS_fnc_spawnGroup;
            };
        };

        // Fallback to East_Units if no group spawned
        if (isNull _realGroup || {count units _realGroup == 0}) then {
            if (!isNull _realGroup) then { deleteGroup _realGroup; };

            _realGroup = createGroup [_side, true];
            private _tempGroup = createGroup [_side, true];
            private _spawnCount = if (_unitCount > 0) then { _unitCount } else { 6 };

            for "_i" from 1 to _spawnCount do {
                private _unitType = selectRandom East_Units;
                private _spawnPos = [_position, 5, 20, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;
                _tempGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
            };

            { [_x] joinSilent _realGroup; } forEach units _tempGroup;
            deleteGroup _tempGroup;
        };
    };
    
    // Civilian group
    case (_groupType isEqualTo "civilian"): {
        _realGroup = createGroup [civilian, true];
        private _civUnits = [];
        private _objective = _groupData getOrDefault ["objective", ""];
        if (_objective isEqualTo "civ_building") then {
            // civ_building civilians already have their exact building position stored
            // Spawn directly at the stored position (don't re-search for buildings)
            for "_i" from 1 to _unitCount do {
                private _unitType = selectRandom CivMenArray;
                private _unit = _realGroup createUnit [_unitType, _position, [], 0, "NONE"];
                _civUnits pushBack _unit;
            };
        } else {
            for "_i" from 1 to _unitCount do {
                private _unitType = selectRandom CivMenArray;
                private _spawnPos = [_position, 5, 20, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;
                private _unit = _realGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
                _civUnits pushBack _unit;
            };
        };
        // Apply civilian interaction logic to these units
        [_civUnits] call FLO_fnc_civilianRelations;
    };
    
    // Vehicle groups
    case (_groupType in ["motorized", "mechanized", "armor"]): {
        _realGroup = createGroup [_side, true];

        for "_i" from 1 to _unitCount do {
            private _vehicleType = "";

            // Select appropriate vehicle type
            switch (_groupType) do {
                case "motorized": { _vehicleType = selectRandom East_Ground_Vehicles_Light; };
                case "mechanized": { _vehicleType = selectRandom East_Ground_Vehicles_Light; };
                case "armor": { _vehicleType = selectRandom East_Ground_Vehicles_Heavy; };
                default { _vehicleType = selectRandom East_Ground_Vehicles_Light; };
            };

            // Find safe position for vehicle with larger radius and vehicle-appropriate spacing
            private _minDist = 10 + (20 * _i);
            private _spawnPos = [_position, _minDist, 150, 10, 0, 0.2, 0] call BIS_fnc_findSafePos;

            // Fallback if BIS_fnc_findSafePos returns the center position (failure)
            if (_spawnPos distance2D _position > 200) then {
                _spawnPos = _position getPos [_minDist, random 360];
                _spawnPos set [2, 0];
            };

            // Create vehicle and crew
            private _veh = [_spawnPos, random 360, _vehicleType, _side] call BIS_fnc_spawnVehicle;
            private _vehicle = _veh select 0;
            private _crew = _veh select 1;
            private _vehGroup = _veh select 2;

            // Ensure vehicle is grounded properly
            _vehicle setPos [getPos _vehicle select 0, getPos _vehicle select 1, 0];
            _vehicle setVectorUp [0,0,1];

            // Transfer crew to our group and delete empty group
            {
                [_x] joinSilent _realGroup;
            } forEach units _vehGroup;
            deleteGroup _vehGroup;
        };
    };
    
    // Air groups (helicopters and jets)
    case (_groupType in ["helicopter", "jet", "air"]): {
        _realGroup = createGroup [_side, true];
        
        for "_i" from 1 to _unitCount do {
            private _aircraftType = "";
            
            // Select appropriate aircraft type
            switch (_groupType) do {
                case "helicopter": { _aircraftType = selectRandom East_Air_Heli; };
                case "jet": { _aircraftType = selectRandom East_Air_Jet; };
                case "air": { _aircraftType = selectRandom (East_Air_Heli + East_Air_Jet); };
                default { _aircraftType = selectRandom East_Air_Heli; };
            };
            
            // Find appropriate spawn height for air vehicles
            private _spawnHeight = 0;
            if (_groupType isEqualTo "jet") then { _spawnHeight = 500; } else { _spawnHeight = 100; };
            
            // Spread out aircraft spawns
            private _spreadDistance = 50 * _i;
            private _spawnPos = [(_position select 0) + _spreadDistance, (_position select 1), _spawnHeight];
            
            // Create vehicle and crew
            private _veh = [_spawnPos, random 360, _aircraftType, _side] call BIS_fnc_spawnVehicle;
            private _vehicle = _veh select 0;
            private _crew = _veh select 1;
            private _vehGroup = _veh select 2;
            
            // Transfer crew to our group and delete empty group
            {
                [_x] joinSilent _realGroup;
            } forEach units _vehGroup;
            deleteGroup _vehGroup;
        };
    };
    
    // Artillery groups
    case (_groupType isEqualTo "artillery"): {
        _realGroup = createGroup [_side, true];

        for "_i" from 1 to _unitCount do {
            private _artilleryType = selectRandom East_Ground_Artillery;

            // Find safe position for artillery with larger spacing (artillery needs more room)
            private _minDist = 15 + (25 * _i);
            private _spawnPos = [_position, _minDist, 150, 12, 0, 0.15, 0] call BIS_fnc_findSafePos;

            // Fallback if position search failed
            if (_spawnPos distance2D _position > 200) then {
                _spawnPos = _position getPos [_minDist, random 360];
                _spawnPos set [2, 0];
            };

            // Create vehicle and crew
            private _veh = [_spawnPos, random 360, _artilleryType, _side] call BIS_fnc_spawnVehicle;
            private _vehicle = _veh select 0;
            private _crew = _veh select 1;
            private _vehGroup = _veh select 2;

            // Ensure artillery is grounded properly
            _vehicle setPos [getPos _vehicle select 0, getPos _vehicle select 1, 0];
            _vehicle setVectorUp [0,0,1];

            // Transfer crew to our group and delete empty group
            {
                [_x] joinSilent _realGroup;
            } forEach units _vehGroup;
            deleteGroup _vehGroup;
        };
    };
    
    // Civilian vehicle group
    case (_groupType isEqualTo "civilianVehicle"): {
        _realGroup = createGroup [civilian, true];
        private _vehicleType = selectRandom CivVehArray;

        // Find a safe position for the vehicle - check roads first, then open terrain
        private _spawnPos = _position;
        private _roads = _position nearRoads 100;
        if (count _roads > 0) then {
            // Try to spawn on a road
            private _road = selectRandom _roads;
            _spawnPos = getPos _road;
        } else {
            // Find safe position on open terrain (larger search radius, vehicle-safe)
            _spawnPos = [_position, 5, 100, 8, 0, 0.3, 0] call BIS_fnc_findSafePos;
        };

        // Create vehicle with "CAN_COLLIDE" first, then set position properly
        private _vehicle = createVehicle [_vehicleType, _spawnPos, [], 0, "CAN_COLLIDE"];
        _vehicle setPos [_spawnPos select 0, _spawnPos select 1, 0];
        _vehicle setVectorUp [0,0,1]; // Ensure vehicle is upright
        _vehicle setDir (random 360);
        _vehicle lock 0;
        _vehicle setFuel 1;
        _vehicle setDamage 0;
        _vehicle setVehicleLock "UNLOCKED";

        // Fill only the driver and sometimes passengers
        private _crewPositions = fullCrew [_vehicle, "", true];
        private _driverPos = _crewPositions select {(_x select 1) == "driver"};
        private _cargoPos = _crewPositions select {(_x select 1) == "cargo"};

        // Always fill driver
        if (count _driverPos > 0) then {
            private _unitType = selectRandom CivMenArray;
            private _unit = _realGroup createUnit [_unitType, [0,0,0], [], 0, "NONE"];
            _unit moveInDriver _vehicle;
        };

        // Randomly fill 0-2 passengers if available
        private _numPassengers = (count _cargoPos) min (floor random 3);
        for "_i" from 0 to (_numPassengers - 1) do {
            if (_i < count _cargoPos) then {
                private _unitType = selectRandom CivMenArray;
                private _unit = _realGroup createUnit [_unitType, [0,0,0], [], 0, "NONE"];
                _unit moveInCargo _vehicle;
            };
        };
    };
    
    // Default case if we don't recognize the group type
    default {
        ["VIRTUALIZATION", 2, format["Unknown group type %1 for virtual group %2", _groupType, _groupId]] call FLO_fnc_log;
        _realGroup = createGroup [_side, true];
        private _unitType = selectRandom East_Units;
        private _unit = _realGroup createUnit [_unitType, _position, [], 0, "NONE"];
    };
};

// Distribute intel items to non-civilian groups
if !(_groupType in ["civilian", "civilianVehicle"]) then {
    private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
    private _units = units _realGroup;
    if (count _units > 0) then {
        private _selectedUnits = _units call BIS_fnc_arrayShuffle;
        _selectedUnits resize (floor (count _selectedUnits / 2) max 1);
        {
            if (random 1 < 0.2) then { // 20% chance per selected unit
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
        private _attachedData = _groups getOrDefault [_attachedId, nil];

        if (!isNil "_attachedData") then {
            private _infSide = _attachedData get "side";
            private _infComp = _attachedData getOrDefault ["comp", []];
            private _infUnitCount = _attachedData getOrDefault ["unitCount", 4];
            private _infGroup = createGroup [_infSide, true];

            // Create infantry units
            if (_infComp isNotEqualTo []) then {
                {
                    private _unitType = _x;
                    private _unit = _infGroup createUnit [_unitType, _position, [], 0, "NONE"];
                } forEach _infComp;
            } else {
                for "_i" from 1 to _infUnitCount do {
                    private _unitType = selectRandom East_Units;
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
private _objective = _groupData getOrDefault ["objective", ""];
if (_objective isEqualTo "civ_building") then {
    {
        _x disableAI "PATH";
        _x disableAI "MOVE";
    } forEach units _realGroup;
};

// Apply waypoints if any
if (count _waypoints > 0) then {
    // Safety check: if first waypoint is CYCLE, that's invalid for Arma
    // This can happen if waypoints got corrupted. Skip CYCLE-only waypoint lists.
    private _firstWpType = (_waypoints select 0) select 1;
    if (_firstWpType == "CYCLE" && count _waypoints == 1) then {
        ["VIRTUALIZATION", 2, format["Group %1 has only CYCLE waypoint - skipping invalid waypoints", _groupId]] call FLO_fnc_log;
    } else {
        {
            private _wpPos = _x select 0;
            private _wpType = _x select 1;
            private _wpBehavior = _x select 2;
            private _wpSpeed = _x select 3;
            private _wpFormation = _x select 4;
            private _wpMode = _x select 5;

            private _wp = _realGroup addWaypoint [_wpPos, 0];
            _wp setWaypointType _wpType;
            _wp setWaypointBehaviour _wpBehavior;
            _wp setWaypointSpeed _wpSpeed;
            _wp setWaypointFormation _wpFormation;
            _wp setWaypointCombatMode _wpMode;
        } forEach _waypoints;
    };
};

// Update debug marker if needed
if (FLO_virtualGroups get "_debugMode") then {
    [_groupId, _groupData] call FLO_fnc_createVirtualGroupMarker;
};

["VIRTUALIZATION", 3, format["Activated virtual group: %1 with %2 units", _groupId, count units _realGroup]] call FLO_fnc_log;

// Return success
true