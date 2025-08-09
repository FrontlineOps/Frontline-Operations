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

["VIRTUALIZATION", 3, format["Activating virtual group %1", _groupId]] call FLO_fnc_log;

// Extract data from group
private _position = _groupData get "position";
private _groupType = _groupData get "groupType";
private _side = _groupData get "side";
private _groupCfg = _groupData getOrDefault ["groupCfg", objNull];
private _waypoints = _groupData getOrDefault ["waypoints", []];
private _comp = _groupData getOrDefault ["comp", []];
private _realGroup = grpNull;

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

    // If we have a valid group config, use it to create the group
    case (_groupCfg isEqualType [] && {count _groupCfg > 0}): {
        private _selectedCfg = selectRandom _groupCfg;
        _realGroup = [_position, _side, _selectedCfg] call BIS_fnc_spawnGroup;
    };
    
    // Infantry based on East_Units array
    case (_groupType isEqualTo "infantry"): {
        _realGroup = createGroup [east, true];
        private _tempEastGroup = createGroup [east, true];

        // Create all units in temp group first
        for "_i" from 1 to _unitCount do {
            private _unitType = selectRandom East_Units;
            private _spawnPos = [_position, 5, 20, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;
            private _unit = _tempEastGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
        };

        // Transfer all units to the real group
        {
            [_x] joinSilent _realGroup;
        } forEach units _tempEastGroup;

        // Clean up temporary group
        deleteGroup _tempEastGroup;
    };
    
    // Civilian group
    case (_groupType isEqualTo "civilian"): {
        _realGroup = createGroup [civilian, true];
        private _civUnits = [];
        private _objective = _groupData getOrDefault ["objective", ""];
        if (_objective isEqualTo "civ_building") then {
            // Find nearest building(s) to _position
            private _buildings = nearestObjects [_position, ["House", "Building"], 50];
            private _buildingPositions = [];
            {
                private _bldg = _x;
                {
                    _buildingPositions pushBack _x;
                } forEach (_bldg buildingPos -1);
            } forEach _buildings;
            // Place civilians in available building positions
            _buildingPositions = _buildingPositions call BIS_fnc_arrayShuffle;
            for "_i" from 1 to _unitCount do {
                private _unitType = selectRandom CivMenArray;
                private _spawnPos = if (count _buildingPositions > 0) then {
                    _buildingPositions deleteAt 0
                } else {
                    [_position, 5, 20, 1, 0, 0.5, 0] call BIS_fnc_findSafePos
                };
                private _unit = _realGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
                _civUnits pushBack _unit;
                _usedPositions = _usedPositions + 1;
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
            
            // Find safe position for vehicle
            private _spawnPos = [_position, 5 + (10 * _i), 50, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
            
            // Create vehicle and crew
            private _veh = [_spawnPos, random 360, _vehicleType, _side] call BIS_fnc_spawnVehicle;
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
            
            // Find safe position for artillery, spread them out
            private _spawnPos = [_position, 10 + (15 * _i), 50, 5, 0, 0.5, 0] call BIS_fnc_findSafePos;
            
            // Create vehicle and crew
            private _veh = [_spawnPos, random 360, _artilleryType, _side] call BIS_fnc_spawnVehicle;
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
    
    // Civilian vehicle group
    case (_groupType isEqualTo "civilianVehicle"): {
        _realGroup = createGroup [civilian, true];
        private _vehicleType = selectRandom CivVehArray;
        private _spawnPos = _position;
        private _vehicle = createVehicle [_vehicleType, _spawnPos, [], 0, "NONE"];
        _vehicle setDir (random 360);
        _vehicle lock 0; // Unlocked
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
            private _unit = _realGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
            (_unit) moveInDriver _vehicle;
        };
        // Randomly fill 0-2 passengers if available
        private _numPassengers = (count _cargoPos) min (floor random 3);
        for "_i" from 0 to (_numPassengers - 1) do {
            if (_i < count _cargoPos) then {
                private _unitType = selectRandom CivMenArray;
                private _unit = _realGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
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

// Update debug marker if needed
if (FLO_virtualGroups get "_debugMode") then {
    [_groupId, _groupData] call FLO_fnc_createVirtualGroupMarker;
};

["VIRTUALIZATION", 3, format["Activated virtual group: %1", _groupId]] call FLO_fnc_log;

// Return success
true 