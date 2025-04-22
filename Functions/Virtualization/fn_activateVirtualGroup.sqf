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
        _realGroup = createGroup [_side, true];
        
        for "_i" from 1 to _unitCount do {
            private _unitType = selectRandom East_Units;
            private _spawnPos = [_position, 5, 20, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;
            private _unit = _realGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
        };
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
    
    // Default case if we don't recognize the group type
    default {
        ["VIRTUALIZATION", 1, format["Unknown group type %1 for virtual group %2", _groupType, _groupId]] call FLO_fnc_log;
        _realGroup = createGroup [_side, true];
        private _unitType = selectRandom East_Units;
        private _unit = _realGroup createUnit [_unitType, _position, [], 0, "NONE"];
    };
};

// Set the real group in the group data
_groupData set ["realGroup", _realGroup];
_groupData set ["isActive", true];
_groupData set ["lastStateChangeTime", diag_tickTime];

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