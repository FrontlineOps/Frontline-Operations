/*
    Function: FLO_fnc_vehicleGarrison
    
    Description:
    Specialized function for spawning and managing vehicle garrisons.
    Handles vehicle patrols, static defensive vehicles, and more.
    
    Parameters:
    _mode - The function mode to execute ["spawn", "patrol", "defend"] (String)
    _params - Parameters based on mode (Array)
        spawn: [_marker, _vehicleTypes, _count] - Spawn vehicles at marker
        patrol: [_marker, _radius, _vehicleType] - Create a vehicle patrol
        defend: [_marker, _vehicleType] - Position a vehicle for defense
    
    Returns:
    Based on mode:
        spawn: Array - The spawned vehicles
        patrol: Group - The patrol group
        defend: Object - The defensive vehicle
*/

if (!isServer) exitWith {};

params [
    ["_mode", "spawn", [""]],
    ["_params", [], [[]]]
];

// Execute the requested mode
private _result = switch (_mode) do {
    // Spawn multiple vehicles at a marker
    case "spawn": {
        _params params [
            ["_marker", "", [""]],
            ["_vehicleTypes", [], [[]]],
            ["_count", 1, [0]]
        ];
        
        if (_marker == "") exitWith {
            diag_log "[FLO][VehicleGarrison] Error: Empty marker name";
            []
        };
        
        private _pos = getMarkerPos _marker;
        if (_pos isEqualTo [0,0,0]) exitWith {
            diag_log format ["[FLO][VehicleGarrison] Error: Invalid marker position for %1", _marker];
            []
        };
        
        // If no specific vehicle types provided, determine based on marker type
        if (count _vehicleTypes == 0) then {
            private _markerType = markerType _marker;
            
            switch (_markerType) do {
                case "o_service": {
                    // For service areas, include transport and repair vehicles
                    _vehicleTypes = East_Ground_Transport;
                };
                case "loc_Power": {
                    // For power plants, use heavy vehicles for protection
                    if (count East_Ground_Vehicles_Heavy > 0) then {
                        _vehicleTypes = East_Ground_Vehicles_Heavy;
                    } else {
                        _vehicleTypes = East_Ground_Vehicles_Light;
                    };
                };
                default {
                    // Default vehicle types
                    _vehicleTypes = East_Ground_Vehicles_Light;
                };
            };
        };
        
        private _spawnedVehicles = [];
        
        for "_i" from 1 to _count do {
            private _vehType = selectRandom _vehicleTypes;
            private _vehPos = [_pos, 10, 100, 5, 0, 0.5, 0, [], [_pos, _pos]] call BIS_fnc_findSafePos;
            
            private _veh = createVehicle [_vehType, _vehPos, [], 0, "NONE"];
            createVehicleCrew _veh;
            
            _spawnedVehicles pushBack _veh;
        };
        
        _spawnedVehicles
    };
    
    // Create a vehicle patrol around a marker
    case "patrol": {
        _params params [
            ["_marker", "", [""]],
            ["_radius", 500, [0]],
            ["_vehicleType", "", [""]]
        ];
        
        if (_marker == "") exitWith {
            diag_log "[FLO][VehicleGarrison] Error: Empty marker name for patrol";
            grpNull
        };
        
        private _pos = getMarkerPos _marker;
        if (_pos isEqualTo [0,0,0]) exitWith {
            diag_log format ["[FLO][VehicleGarrison] Error: Invalid marker position for patrol %1", _marker];
            grpNull
        };
        
        // If no specific vehicle type provided, determine based on marker type
        if (_vehicleType == "") then {
            private _markerType = markerType _marker;
            
            switch (_markerType) do {
                case "o_recon": {
                    // For recon positions, use lighter, faster vehicles
                    _vehicleType = selectRandom East_Ground_Vehicles_Light;
                };
                default {
                    _vehicleType = selectRandom East_Ground_Vehicles_Light;
                };
            };
        };
        
        // Create vehicle and crew
        private _vehPos = [_pos, 10, 100, 5, 0, 0.5, 0, [], [_pos, _pos]] call BIS_fnc_findSafePos;
        private _veh = createVehicle [_vehicleType, _vehPos, [], 0, "NONE"];
        createVehicleCrew _veh;
        
        private _group = group driver _veh;
        
        // Ensure group is properly set to EAST
        if (side _group != east) then {
            private _eastGroup = createGroup [east, true];
            {
                [_x] joinSilent _eastGroup;
            } forEach units _group;
            _group = _eastGroup;
        };
        
        // Configure patrol behavior
        [_group, _pos, _radius] call BIS_fnc_taskPatrol;
        
        // Set group behavior
        _group setCombatMode "RED";
        _group setBehaviour "AWARE";
        _group setSpeedMode "LIMITED";
        
        // Return the patrol group
        _group
    };
    
    // Position a vehicle for defense
    case "defend": {
        _params params [
            ["_marker", "", [""]],
            ["_vehicleType", "", [""]]
        ];
        
        if (_marker == "") exitWith {
            diag_log "[FLO][VehicleGarrison] Error: Empty marker name for defense";
            objNull
        };
        
        private _pos = getMarkerPos _marker;
        if (_pos isEqualTo [0,0,0]) exitWith {
            diag_log format ["[FLO][VehicleGarrison] Error: Invalid marker position for defense %1", _marker];
            objNull
        };
        
        // If no specific vehicle type provided, determine based on marker type
        if (_vehicleType == "") then {
            private _markerType = markerType _marker;
            
            switch (_markerType) do {
                case "loc_Ruin": {
                    // For ruins, use ambient vehicles that might be abandoned
                    if (count East_Ground_Vehicles_Ambient > 0) then {
                        _vehicleType = selectRandom East_Ground_Vehicles_Ambient;
                    } else {
                        _vehicleType = selectRandom East_Ground_Vehicles_Light;
                    };
                };
                case "loc_Power": {
                    // For power plants, use heavy vehicles
                    if (count East_Ground_Vehicles_Heavy > 0) then {
                        _vehicleType = selectRandom East_Ground_Vehicles_Heavy;
                    } else {
                        _vehicleType = selectRandom East_Ground_Vehicles_Light;
                    };
                };
                default {
                    // For defensive positions, prefer heavier vehicles when available
                    if (count East_Ground_Vehicles_Heavy > 0) then {
                        _vehicleType = selectRandom East_Ground_Vehicles_Heavy;
                    } else {
                        _vehicleType = selectRandom East_Ground_Vehicles_Light;
                    };
                };
            };
        };
        
        // Find a good defensive position
        private _roadPos = _pos nearRoads 100;
        private _defensivePos = _pos;
        
        if (count _roadPos > 0) then {
            // Try to find a road position that overlooks the area
            private _bestElevation = 0;
            private _bestRoad = _roadPos select 0;
            
            {
                private _roadElevation = getTerrainHeightASL (getPos _x);
                if (_roadElevation > _bestElevation) then {
                    _bestElevation = _roadElevation;
                    _bestRoad = _x;
                };
            } forEach _roadPos;
            
            _defensivePos = getPos _bestRoad;
        } else {
            // No roads, try to find a position with elevation
            private _positions = [];
            for "_i" from 0 to 359 step 45 do {
                private _checkPos = _pos getPos [100, _i];
                private _elevation = getTerrainHeightASL _checkPos;
                _positions pushBack [_checkPos, _elevation];
            };
            
            // Sort by elevation
            _positions sort false;
            
            // Use position with highest elevation if it's higher than original
            if (count _positions > 0) then {
                private _highPos = (_positions select 0) select 0;
                private _highElev = (_positions select 0) select 1;
                private _originalElev = getTerrainHeightASL _pos;
                
                if (_highElev > _originalElev) then {
                    _defensivePos = _highPos;
                };
            };
        };
        
        // Create the vehicle in defensive position
        private _veh = createVehicle [_vehicleType, _defensivePos, [], 0, "NONE"];
        createVehicleCrew _veh;
        
        // Configure defensive behavior
        private _group = group driver _veh;
        
        // Ensure group is properly set to EAST
        if (side _group != east) then {
            private _eastGroup = createGroup [east, true];
            {
                [_x] joinSilent _eastGroup;
            } forEach units _group;
            _group = _eastGroup;
        };
        
        _group setCombatMode "RED";
        _group setBehaviour "COMBAT";
        
        // Set vehicle in a defensive position
        _veh setDir ([_veh, _pos] call BIS_fnc_dirTo);
        
        // Return the defensive vehicle
        _veh
    };
};

_result 