/*
    Function: FLO_fnc_garrisonManager
    
    Description:
    Manages garrison spawning and maintenance for objectives.
    Uses OOP approach with HashMapObject for better organization and state management.
    
    Parameters:
    _mode - The function mode to execute ["init", "spawn", "reinforce", "maintain", "checkAndSpawn", "saveGarrisonSizes", "loadGarrisonSizes", "isGarrisonGroup"] (String)
    _params - Parameters based on mode (Array)
        init: [] - No parameters needed
        spawn: [_marker, _size, _withVehicles] - Create a new garrison at marker
        reinforce: [_marker, _amount] - Add units to existing garrison
        maintain: [] - Run maintenance on all garrisons
        checkAndSpawn: [_activationDistance] - Check all markers and spawn garrisons near players
        saveGarrisonSizes: [] - Save current garrison sizes to profileNamespace
        loadGarrisonSizes: [] - Load garrison sizes from profileNamespace
        isGarrisonGroup: [_group] - Check if a group is from a garrison
    
    Returns:
    Based on mode:
        init: HashMapObject - The garrison manager object
        spawn: Array - The spawned garrison units
        reinforce: Boolean - Success of reinforcement
        maintain: Nothing
        checkAndSpawn: Number - Count of newly spawned garrisons
        saveGarrisonSizes: Boolean - Success of save operation
        loadGarrisonSizes: Boolean - Success of load operation
        isGarrisonGroup: Boolean - Success of check operation
*/

if (!isServer) exitWith {};

params [
    ["_mode", "", [""]],
    ["_params", [], [[]]]
];

private _result = false;

// Initialize the Garrison Manager object if it doesn't exist
if (isNil "FLO_Garrison_Manager") then {
    // Define the Garrison Manager class with its methods and properties
    private _garrisonManagerClass = [
        // Class identifier
        ["#type", "GarrisonManager"],
        
        // Properties
        ["garrisons", createHashMap],
        ["lastUpdate", time],
        ["totalUnits", 0],
        ["processedMarkers", []],
        ["markerSizeLimits", createHashMap], // New property to store min/max sizes for marker types
        ["garrisonSizes", createHashMap],    // New property to store saved garrison sizes
        
        // Constructor - Called when object is created
        ["#create", {
            _self set ["garrisons", createHashMap];
            _self set ["lastUpdate", time];
            _self set ["totalUnits", 0];
            _self set ["processedMarkers", []];
            _self set ["garrisonSizes", createHashMap];
            
            // Define size limits for each marker type [baseSize, maxSize]
            private _sizeLimits = createHashMap;
            _sizeLimits set ["n_installation", [12, 125]];
            _sizeLimits set ["o_installation", [8, 100]];
            _sizeLimits set ["n_support", [16, 75]];
            _sizeLimits set ["o_support", [8, 50]];
            _sizeLimits set ["loc_Power", [6, 32]];
            _sizeLimits set ["o_recon", [2, 6]];
            _sizeLimits set ["o_service", [6, 12]];
            _sizeLimits set ["o_antiair", [8, 16]];
            _sizeLimits set ["loc_Ruin", [12, 32]];
            _sizeLimits set ["default", [4, 8]];
            
            _self set ["markerSizeLimits", _sizeLimits];
            
            diag_log "[FLO][Garrison] Manager initialized with size limits";
        }],
        
        // Get size limits for marker type
        ["getSizeLimits", {
            params ["_markerType"];
            
            private _sizeLimits = _self get "markerSizeLimits";
            if (_markerType in keys _sizeLimits) then {
                _sizeLimits get _markerType
            } else {
                _sizeLimits get "default"
            }
        }],
        
        // Initialize garrison system and start maintenance loop
        ["initialize", {
            // Load saved garrison sizes if available
            _self call ["loadGarrisonSizes", []];
            
            // Start the maintenance loop
            [] spawn {
                while {true} do {
                    // Run maintenance every 5 minutes
                    ["maintain", []] call FLO_fnc_garrisonManager;
                    sleep 300;
                    
                    // Check for new garrisons to spawn every 30 seconds
                    ["checkAndSpawn", [1500]] call FLO_fnc_garrisonManager;
                    sleep 30;
                };
            };
        }],
        
        // Save garrison sizes to profileNamespace
        ["saveGarrisonSizes", {
            private _missionTag = missionName;
            _missionTag = [_missionTag] call BIS_fnc_filterString;
            private _garrisonSizesDataName = _missionTag + "_garrisonSizes";
            
            private _garrisonSizes = createHashMap;
            private _garrisons = _self get "garrisons";
            
            // For tracking statistics
            private _markerTypeCount = createHashMap;
            private _totalSize = 0;
            
            // For each garrison, store its current size
            {
                private _marker = _x;
                private _garrisonData = _garrisons get _marker;
                
                if (!isNil "_garrisonData") then {
                    // The structure of garrisonData is [_units, _group, _vehicles, _garrison, _size, _queuedReinforcements]
                    private _size = _garrisonData param [4, 0];
                    
                    // Only save if size is greater than 0
                    if (_size > 0) then {
                        _garrisonSizes set [_marker, _size];
                        _totalSize = _totalSize + _size;
                        
                        // Track marker type statistics
                        private _markerType = markerType _marker;
                        if (_markerType != "") then {
                            private _count = _markerTypeCount getOrDefault [_markerType, 0];
                            _markerTypeCount set [_markerType, _count + 1];
                        };
                    };
                };
            } forEach keys _garrisons;
            
            // Save to profileNamespace
            profileNamespace setVariable [_garrisonSizesDataName, _garrisonSizes];
            saveProfileNamespace;
            
            // Store in object for quick access
            _self set ["garrisonSizes", _garrisonSizes];
            
            // Detailed logging
            private _markerTypes = keys _markerTypeCount;
            private _logDetails = "";
            {
                private _count = _markerTypeCount get _x;
                _logDetails = _logDetails + format ["%1: %2, ", _x, _count];
            } forEach _markerTypes;
            
            if (_logDetails != "") then {
                // Remove trailing comma and space
                _logDetails = _logDetails select [0, count _logDetails - 2];
                diag_log format ["[FLO][Garrison] Saved sizes for %1 garrisons with %2 total units. Breakdown by type: %3", 
                    count keys _garrisonSizes, _totalSize, _logDetails];
            } else {
                diag_log format ["[FLO][Garrison] Saved sizes for %1 garrisons with %2 total units.", 
                    count keys _garrisonSizes, _totalSize];
            };
            
            true
        }],
        
        // Load garrison sizes from profileNamespace
        ["loadGarrisonSizes", {
            private _missionTag = missionName;
            _missionTag = [_missionTag] call BIS_fnc_filterString;
            private _garrisonSizesDataName = _missionTag + "_garrisonSizes";
            
            private _savedGarrisonSizes = profileNamespace getVariable [_garrisonSizesDataName, createHashMap];
            
            if (count keys _savedGarrisonSizes > 0) then {
                // Track statistics
                private _markerTypeCount = createHashMap;
                private _totalSize = 0;
                
                // Check each saved garrison and collect stats
                {
                    private _marker = _x;
                    private _size = _savedGarrisonSizes get _marker;
                    _totalSize = _totalSize + _size;
                    
                    // Track marker type statistics if marker still exists
                    if (markerShape _marker != "") then {
                        private _markerType = markerType _marker;
                        if (_markerType != "") then {
                            private _count = _markerTypeCount getOrDefault [_markerType, 0];
                            _markerTypeCount set [_markerType, _count + 1];
                        };
                    };
                } forEach keys _savedGarrisonSizes;
                
                _self set ["garrisonSizes", _savedGarrisonSizes];
                
                // Detailed logging
                private _markerTypes = keys _markerTypeCount;
                private _logDetails = "";
                {
                    private _count = _markerTypeCount get _x;
                    _logDetails = _logDetails + format ["%1: %2, ", _x, _count];
                } forEach _markerTypes;
                
                if (_logDetails != "") then {
                    // Remove trailing comma and space
                    _logDetails = _logDetails select [0, count _logDetails - 2];
                    diag_log format ["[FLO][Garrison] Loaded sizes for %1 garrisons with %2 total units. Breakdown by type: %3", 
                        count keys _savedGarrisonSizes, _totalSize, _logDetails];
                } else {
                    diag_log format ["[FLO][Garrison] Loaded sizes for %1 garrisons with %2 total units.", 
                        count keys _savedGarrisonSizes, _totalSize];
                };
                
                true
            } else {
                diag_log "[FLO][Garrison] No saved garrison sizes found";
                false
            };
        }],
        
        // Check for markers near players and spawn garrisons if needed
        ["checkNearbyGarrisons", {
            params ["_activationDistance"];
            
            private _spawnCount = 0;
            private _processedMarkers = _self get "processedMarkers";
            private _garrisons = _self get "garrisons";
            private _garrisonSizes = _self get "garrisonSizes";
            
            // Get all players (except headless clients)
            private _allPlayers = allPlayers - entities "HeadlessClient_F";
            if (count _allPlayers == 0) exitWith {0}; // No players, exit
            
            // Get all OPFOR markers that aren't already processed
            private _opforMarkers = allMapMarkers select {
                markerColor _x in ["colorOPFOR", "ColorEAST"] && 
                markerType _x in ["o_support", "n_support", "n_installation", "o_installation", "loc_Ruin", "loc_Power", "o_recon", "o_service", "o_antiair"] &&
                !(_x in _processedMarkers) &&
                !(_x in keys _garrisons)
            };
            
            {
                private _marker = _x;
                private _markerPos = getMarkerPos _marker;
                private _markerType = markerType _marker;
                private _nearPlayers = false;
                
                // Check if any player is near this marker
                {
                    if (_x distance _markerPos < _activationDistance) exitWith {
                        _nearPlayers = true;
                    };
                } forEach _allPlayers;
                
                // If players are nearby and marker not already processed, spawn garrison
                if (_nearPlayers) then {
                    // Check if there's an unactivated garrison with queued reinforcements
                    private _queuedGarrison = false;
                    private _additionalUnits = 0;
                    
                    if (_marker in keys _garrisons) then {
                        private _garrisonData = _garrisons get _marker;
                        
                        // Check if this garrison has no active units but queued reinforcements
                        if (count (_garrisonData select 0) == 0) then {
                            _queuedGarrison = true;
                            
                            // Get any queued reinforcements to include in spawn
                            _additionalUnits = _garrisonData param [5, 0];
                            
                            // Remove the inactive garrison entry
                            _garrisons deleteAt _marker;
                            
                            diag_log format ["[FLO][Garrison] Found queued garrison at %1 with %2 additional units", _marker, _additionalUnits];
                        };
                    };
                    
                    // Get size limits for this marker type
                    private _sizeLimits = _self call ["getSizeLimits", [_markerType]];
                    private _baseSize = _sizeLimits select 0;
                    private _maxSize = _sizeLimits select 1;
                    
                    // Set size to base size for this marker type
                    private _size = _baseSize;
                    private _withVehicles = false;
                    
                    // Check if we have a saved size for this garrison
                    if (_marker in keys _garrisonSizes) then {
                        _size = (_garrisonSizes get _marker) min _maxSize;
                        diag_log format ["[FLO][Garrison] Using saved size for garrison at %1: %2 (base: %3, max: %4)", 
                            _marker, _size, _baseSize, _maxSize];
                    };
                    
                    // Determine vehicle presence based on marker type
                    switch (_markerType) do {
                        case "n_installation": { _withVehicles = true; };
                        case "o_installation": { _withVehicles = true; };
                        case "loc_Power": { _withVehicles = true; };
                        case "o_service": { _withVehicles = true; };
                        case "o_antiair": { _withVehicles = true; };
                        default { _withVehicles = false; };
                    };
                    
                    // Add queued reinforcements, but limit to max size
                    if (_additionalUnits > 0) then {
                        _size = (_size + _additionalUnits) min _maxSize;
                        if (_size == _maxSize && _additionalUnits > (_maxSize - _baseSize)) then {
                            diag_log format ["[FLO][Garrison] Garrison at %1 reached maximum size (%2), capping reinforcements", _marker, _maxSize];
                        };
                        diag_log format ["[FLO][Garrison] Adjusted garrison size at %1 from %2 to %3 including reinforcements (max: %4)", 
                            _marker, _baseSize, _size, _maxSize];
                    };
                    
                    if (_size > 0) then {
                        // Spawn garrison
                        _self call ["spawnGarrison", [_marker, _size, _withVehicles, _baseSize, _maxSize]];
                        
                        // Add defensive vehicle at installations with vehicles
                        if (_withVehicles) then {
                            private _defenseVehicle = "";
                            
                            // Defense vehicle selection - simplified
                            if (count East_Ground_Vehicles_Heavy > 0) then {
                                _defenseVehicle = selectRandom East_Ground_Vehicles_Heavy;
                            } else {
                                _defenseVehicle = selectRandom East_Ground_Vehicles_Light;
                            };
                            
                            ["defend", [_marker, _defenseVehicle]] call FLO_fnc_vehicleGarrison;
                            
                            // Add patrol for larger installations
                            if (_markerType in ["n_installation", "o_installation"]) then {
                                ["patrol", [_marker, 800, selectRandom East_Ground_Vehicles_Light]] call FLO_fnc_vehicleGarrison;
                            };
                        };
                        
                        _spawnCount = _spawnCount + 1;
                    };
                    
                    // Add to processed markers
                    _processedMarkers pushBack _marker;
                };
            } forEach _opforMarkers;
            
            // Update processed markers
            _self set ["processedMarkers", _processedMarkers];
            
            // Return count of spawned garrisons
            _spawnCount
        }],
        
        // Create a new garrison at a marker
        ["spawnGarrison", {
            params ["_marker", "_size", "_withVehicles", ["_baseSize", 0], ["_maxSize", 0]];
            
            if (_marker == "") exitWith {
                diag_log "[FLO][Garrison] Error: Empty marker name";
                []
            };
            
            private _pos = getMarkerPos _marker;
            if (_pos isEqualTo [0,0,0]) exitWith {
                diag_log format ["[FLO][Garrison] Error: Invalid marker position for %1", _marker];
                []
            };
            
            // If base and max size weren't provided, get them from marker type
            if (_baseSize == 0 || _maxSize == 0) then {
                private _markerType = markerType _marker;
                private _sizeLimits = _self call ["getSizeLimits", [_markerType]];
                _baseSize = _sizeLimits select 0;
                _maxSize = _sizeLimits select 1;
            };
            
            // Ensure size is within limits
            _size = _size max _baseSize min _maxSize;
            
            // Default composition based on size using East_Units
            private _composition = [];
            
            // Get available unit types from global variables
            private _availableUnits = East_Units;
            private _officerUnits = East_Units_Officers;
            
            // Generate compositions based on size
            switch (true) do {
                case (_size <= 4): { 
                    for "_i" from 1 to 4 do {
                        _composition pushBack [selectRandom _availableUnits, 1];
                    };
                };
                case (_size <= 8): {
                    for "_i" from 1 to 8 do {
                        _composition pushBack [selectRandom _availableUnits, 1];
                    };
                };
                default {
                    for "_i" from 1 to (_size min 13) do {
                        _composition pushBack [selectRandom _availableUnits, 1];
                    };
                };
            };
            
            // Add vehicles if requested
            private _vehicles = [];
            if (_withVehicles) then {
                // Use vehicle types from global variables
                private _lightVehicles = East_Ground_Vehicles_Light;
                private _heavyVehicles = East_Ground_Vehicles_Heavy;
                
                _vehicles = switch (true) do {
                    case (_size <= 4): { 
                        [
                            [selectRandom _lightVehicles, 1]
                        ]
                    };
                    case (_size <= 8): {
                        [
                            [selectRandom _lightVehicles, 1],
                            [selectRandom _lightVehicles, 1]
                        ]
                    };
                    default {
                        [
                            [selectRandom _lightVehicles, 1],
                            [selectRandom _lightVehicles, 1],
                            [selectRandom _heavyVehicles, 1]
                        ]
                    };
                };
            };
            
            // Spawn units
            private _spawnedUnits = [];
            private _group = createGroup [east, true];
            
            {
                _x params ["_type", "_count"];
                for "_i" from 1 to _count do {
                    // Create the unit with explicit EAST side
                    private _unit = _group createUnit [_type, _pos, [], 50, "NONE"];
                    
                    // Force side to EAST if needed
                    if (side _unit != east) then {
                        private _newUnit = createGroup [east, true] createUnit [_type, _pos, [], 50, "NONE"];
                        deleteVehicle _unit;
                        _unit = _newUnit;
                        [_unit] joinSilent _group;
                    };
                    
                    // Store the marker on the unit for QRF reference
                    _unit setVariable ["FLO_Garrison_Marker", _marker, false];
                    
                    // Random chance to add QRF trigger EventHandler
                    // Officers always have QRF ability, regular units have a random chance
                    private _isOfficer = (_officerUnits findIf {_type == _x}) >= 0;
                    if (_isOfficer || (random 1 < 0.25)) then { // 25% chance for regular units
                        _unit addEventHandler ["Killed", {
                            params ["_unit", "_killer"];
                            
                            // Only trigger QRF if killed by BLUFOR
                            if (side _killer == west) then {
                                private _unitPos = getPos _unit;
                                private _markerData = _unit getVariable ["FLO_Garrison_Marker", ""];
                                
                                // Random chance to actually call QRF based on unit type
                                private _isOfficer = _unit getVariable ["FLO_IsOfficer", false];
                                private _qrfChance = if (_isOfficer) then {0.8} else {0.4}; // 80% for officers, 40% for others
                                
                                if (_markerData != "" && random 1 < _qrfChance) then {
                                    diag_log format ["[FLO][Garrison] Unit killed at %1 triggered QRF request (officer: %2)", _markerData, _isOfficer];
                                    [_unitPos, 500] call FLO_fnc_requestQRF;
                                };
                            };
                        }];
                        
                        // Store officer status for QRF chance calculation
                        _unit setVariable ["FLO_IsOfficer", _isOfficer, false];
                        
                        if (_isOfficer) then {
                            diag_log format ["[FLO][Garrison] Officer unit %1 assigned QRF trigger capability", _unit];
                        };
                    };
                    
                    _spawnedUnits pushBack _unit;
                };
            } forEach _composition;
            
            // Verify that all units are properly assigned to EAST
            if (side _group != east) then {
                diag_log "[FLO][Garrison] WARNING: Group side is not EAST after creation. Creating new EAST group...";
                private _eastGroup = createGroup [east, true];
                {
                    [_x] joinSilent _eastGroup;
                    // Double-check individual unit sides
                    if (side _x != east) then {
                        diag_log format ["[FLO][Garrison] WARNING: Unit %1 is not EAST after joining group", _x];
                        // Alternative: create a new unit and delete the old one
                        private _pos = getPosATL _x;
                        private _type = typeOf _x;
                        deleteVehicle _x;
                        private _newUnit = _eastGroup createUnit [_type, _pos, [], 0, "NONE"];
                        _spawnedUnits set [_forEachIndex, _newUnit];
                    };
                } forEach units _group;
                _group = _eastGroup;
            };
            
            // Spawn vehicles
            private _spawnedVehicles = [];
            {
                _x params ["_type", "_count"];
                for "_i" from 1 to _count do {
                    private _vehPos = [_pos, 10, 100, 5, 0, 0.5, 0, [], [_pos, _pos]] call BIS_fnc_findSafePos;
                    private _veh = createVehicle [_type, _vehPos, [], 0, "NONE"];
                    
                    // Create crew with explicit EAST side
                    private _vehGroup = createGroup [east, true];
                    createVehicleCrew _veh;
                    
                    // Transfer crew to our controlled EAST group
                    private _crew = crew _veh;
                    {
                        // Check if crew member is not EAST
                        if (side _x != east) then {
                            // Replace with a new EAST unit
                            private _role = assignedVehicleRole _x;
                            private _type = typeOf _x;
                            unassignVehicle _x;
                            deleteVehicle _x;
                            
                            // Create new crew member of correct side
                            private _newUnit = _vehGroup createUnit [_type, [0,0,0], [], 0, "NONE"];
                            _newUnit assignAsDriver _veh;
                            _newUnit moveInDriver _veh;
                            _crew set [_forEachIndex, _newUnit];
                        } else {
                            // Just transfer the unit to our group
                            [_x] joinSilent _vehGroup;
                        }
                    } forEach _crew;
                    
                    // Join the vehicle group to the main group
                    (units _vehGroup) joinSilent _group;
                    
                    // Update our units and vehicles tracking
                    _spawnedUnits append (crew _veh);
                    _spawnedVehicles pushBack _veh;
                    
                    // Add QRF EventHandler to vehicle crew with higher chance
                    {
                        // Store the marker on the crew member for QRF reference
                        _x setVariable ["FLO_Garrison_Marker", _marker, false];
                        
                        // Vehicle crews have higher chance to call QRF (35%)
                        if (random 1 < 0.35) then {
                            // Store crew status for QRF chance calculation - vehicle crews are treated as semi-officers
                            _x setVariable ["FLO_IsOfficer", true, false];
                            
                            _x addEventHandler ["Killed", {
                                params ["_unit", "_killer"];
                                
                                // Only trigger QRF if killed by BLUFOR
                                if (side _killer == west) then {
                                    private _unitPos = getPos _unit;
                                    private _markerData = _unit getVariable ["FLO_Garrison_Marker", ""];
                                    
                                    // 60% chance for vehicle crew to actually call QRF (higher than regular infantry)
                                    if (_markerData != "" && random 1 < 0.6) then {
                                        diag_log format ["[FLO][Garrison] Vehicle crew killed at %1 triggered QRF request", _markerData];
                                        [_unitPos, 500] call FLO_fnc_requestQRF;
                                    };
                                };
                            }];
                        };
                    } forEach (crew _veh);
                    
                    // Verify crew is EAST
                    {
                        if (side _x != east) then {
                            diag_log format ["[FLO][Garrison] WARNING: Vehicle crew member %1 is not EAST after creation", _x];
                        };
                    } forEach (crew _veh);
                };
            } forEach _vehicles;
            
            // Enhanced garrison behavior - find buildings and suitable positions
            private _nearBuildings = _pos nearObjects ["Building", 150];
            private _buildingPositions = [];
            
            // Collect all valid building positions
            {
                private _positions = _x buildingPos -1;
                if (count _positions > 0) then {
                    _buildingPositions append _positions;
                };
            } forEach _nearBuildings;
            
            // Only keep a reasonable number of positions
            if (count _buildingPositions > 30) then {
                _buildingPositions resize 30;
            };
            
            // Split the group based on buildings available and garrison size
            if (count _buildingPositions > 3 && count _spawnedUnits > 3) then {
                // Garrison units - 2/3 of units go to buildings
                private _garrisonUnits = floor ((count _spawnedUnits) * 0.6);
                private _garrisonGroup = createGroup [east, true];
                
                for "_i" from 1 to (_garrisonUnits min count _buildingPositions) do {
                    if (count _spawnedUnits > 0) then {
                        private _unit = _spawnedUnits deleteAt 0;
                        [_unit] joinSilent _garrisonGroup;
                        
                        // Verify unit is EAST after joining garrison group
                        if (side _unit != east) then {
                            diag_log format ["[FLO][Garrison] WARNING: Unit %1 lost EAST side after joining garrison group", _unit];
                            // Force the unit back to EAST if needed
                            [_unit] joinSilent createGroup [east, true];
                        };
                        
                        // Move to building position
                        private _bPos = selectRandom _buildingPositions;
                        _buildingPositions = _buildingPositions - [_bPos];
                        _unit doMove _bPos;
                        _unit setPos _bPos;
                        
                        // Set unit behavior for garrison
                        _unit disableAI "PATH";
                        _unit setUnitPos (selectRandom ["UP", "MIDDLE"]);
                    };
                };
                
                // Set garrison group behavior
                _garrisonGroup setCombatMode "RED";
                _garrisonGroup setBehaviour "AWARE";
                
                // Create patrol group with remaining units
                if (count _spawnedUnits > 0) then {
                    private _patrolGroup = createGroup [east, true];
                    
                    {
                        [_x] joinSilent _patrolGroup;
                        
                        // Verify unit is EAST after joining patrol group
                        if (side _x != east) then {
                            diag_log format ["[FLO][Garrison] WARNING: Unit %1 lost EAST side after joining patrol group", _x];
                            // Force the unit back to EAST if needed
                            [_x] joinSilent createGroup [east, true];
                            [_x] joinSilent _patrolGroup;
                        };
                    } forEach _spawnedUnits;
                    
                    // Set patrol path
                    [_patrolGroup, _pos, 150] call BIS_fnc_taskPatrol;
                    
                    // Set patrol behavior
                    _patrolGroup setCombatMode "RED";
                    _patrolGroup setBehaviour "AWARE";
                    _patrolGroup setSpeedMode "LIMITED";
                };
            } else {
                // Fall back to standard defensive behavior if not enough buildings
                [_group, _pos, 100, 2, 0.2, 0.3] call BIS_fnc_taskDefend;
            };
            
            // Final verification that all units are EAST
            {
                if (side _x != east) then {
                    diag_log format ["[FLO][Garrison] FINAL CHECK: Unit %1 is not EAST after all processing", _x];
                };
            } forEach (_spawnedUnits select {alive _x});
            
            // Store in garrisons hashmap
            private _garrisons = _self get "garrisons";
            
            // Extended garrison data structure:
            // [units, vehicles, group, timestamp, virtualStrength, queuedReinforcements, baseSize, maxSize, currentSize]
            _garrisons set [_marker, [
                _spawnedUnits,                // Actual spawned units
                _spawnedVehicles,             // Spawned vehicles
                _group,                       // Main group
                time,                         // Creation timestamp
                0,                            // Virtual strength (reinforcements available but not yet spawned)
                0,                            // Queued reinforcements (for inactive garrisons)
                _baseSize,                    // Base size from marker type
                _maxSize,                     // Maximum allowed size
                _size                         // Current intended size
            ]];
            
            // Update total units count
            _self set ["totalUnits", (_self get "totalUnits") + count _spawnedUnits];
            
            diag_log format ["[FLO][Garrison] Created garrison at %1 with %2 units and %3 vehicles (Size: %4/%5)", 
                _marker, count _spawnedUnits, count _spawnedVehicles, _size, _maxSize];
            
            // Return spawned units
            _spawnedUnits
        }],
        
        // Reinforce an existing garrison - ONLY UPDATES TRACKED COUNT, NEVER SPAWNS UNITS
        ["reinforceGarrison", {
            params ["_marker", "_amount"];
            
            private _garrisons = _self get "garrisons";
            
            // Check if garrison exists
            if (!(_marker in keys _garrisons)) then {
                // Garrison doesn't exist yet - create a placeholder entry if the marker exists
                if (markerShape _marker != "") then {
                    diag_log format ["[FLO][Garrison] Creating placeholder for non-activated garrison at %1", _marker];
                    
                    // Get the marker type to determine size limits
                    private _markerType = markerType _marker;
                    private _sizeLimits = _self call ["getSizeLimits", [_markerType]];
                    private _baseSize = _sizeLimits select 0;
                    private _maxSize = _sizeLimits select 1;
                    
                    // Create an empty garrison entry with queued reinforcements
                    _garrisons set [_marker, [
                        [], // No units
                        [], // No vehicles
                        grpNull, // No group
                        time, // Creation timestamp
                        0, // No virtual strength
                        _amount, // Queued reinforcements
                        _baseSize, // Base size
                        _maxSize, // Max size
                        _amount // Current size is just the reinforcements for now
                    ]];
                    
                    // Update total units count for tracking
                    _self set ["totalUnits", (_self get "totalUnits") + _amount];
                    
                    diag_log format ["[FLO][Garrison] Created placeholder garrison at %1 with %2 queued reinforcements", 
                        _marker, _amount];
                    
                    // Update saved garrison size for persistence
                    private _garrisonSizes = _self get "garrisonSizes";
                    private _currentSize = _garrisonSizes getOrDefault [_marker, 0];
                    _garrisonSizes set [_marker, (_currentSize + _amount) min _maxSize];
                    _self set ["garrisonSizes", _garrisonSizes];
                    
                    _result = true;
                } else {
                    diag_log format ["[FLO][Garrison] Error: Invalid marker '%1' for reinforcement", _marker];
                    _result = false;
                };
            } else {
                private _garrisonData = _garrisons get _marker;
                _garrisonData params ["_units", "_vehicles", "_group", "_timestamp", "_virtualStrength", "_queuedReinforcements"];
                
                // Get the size limits
                private _baseSize = _garrisonData param [6, 4]; // Default base size of 4 if not stored
                private _maxSize = _garrisonData param [7, 8];  // Default max size of 8 if not stored
                private _currentSize = _garrisonData param [8, count (_units select {alive _x})]; // Current size
                
                // Check if we've already reached max size
                if (_currentSize >= _maxSize) then {
                    diag_log format ["[FLO][Garrison] Garrison at %1 already at maximum size (%2), reinforcement rejected", _marker, _maxSize];
                    _result = false;
                } else {
                    // Calculate how many reinforcements can be added before reaching max
                    private _availableSpace = _maxSize - _currentSize;
                    private _reinforcementCount = _amount min _availableSpace;
                    
                    // Log if we're capping reinforcements
                    if (_reinforcementCount < _amount) then {
                        diag_log format ["[FLO][Garrison] Reinforcement for %1 limited from %2 to %3 units due to size cap (%4/%5)", 
                            _marker, _amount, _reinforcementCount, _currentSize, _maxSize];
                    };
                    
                    // Check if this garrison is active (has spawned units)
                    private _isActive = count (_units select {alive _x}) > 0;
                    
                    // Update the appropriate counter
                    if (_isActive) then {
                        // Garrison is active - track reinforcements virtually
                        diag_log format ["[FLO][Garrison] Reinforcement available for active garrison at %1: +%2 units (tracked only)", 
                            _marker, _reinforcementCount];
                        
                        // Update virtual strength
                        _virtualStrength = _virtualStrength + _reinforcementCount;
                        _garrisonData set [4, _virtualStrength];
                        
                        // Update current size
                        _currentSize = _currentSize + _reinforcementCount;
                        _garrisonData set [8, _currentSize];
                        
                    } else {
                        // Garrison is not active - queue reinforcements for later
                        diag_log format ["[FLO][Garrison] Reinforcement queued for inactive garrison at %1: +%2 units", 
                            _marker, _reinforcementCount];
                        
                        // Update queued reinforcements
                        _queuedReinforcements = _queuedReinforcements + _reinforcementCount;
                        _garrisonData set [5, _queuedReinforcements];
                        
                        // Update current size
                        _currentSize = _currentSize + _reinforcementCount;
                        _garrisonData set [8, _currentSize];
                    };
                    
                    // Save updated garrison data
                    _garrisons set [_marker, _garrisonData];
                    
                    // Update total units count (only for tracking purposes)
                    _self set ["totalUnits", (_self get "totalUnits") + _reinforcementCount];
                    
                    // Update saved garrison size for persistence
                    private _garrisonSizes = _self get "garrisonSizes";
                    _garrisonSizes set [_marker, _currentSize min _maxSize];
                    _self set ["garrisonSizes", _garrisonSizes];
                    
                    _result = true;
                };
            };
            
            _result
        }],
        
        // Maintain all garrisons
        ["maintainGarrisons", {
            private _garrisons = _self get "garrisons";
            private _totalCount = 0;
            
            // Process each garrison
            {
                private _marker = _x;
                private _data = _garrisons get _marker;
                _data params ["_units", "_vehicles", "_group", "_timestamp", "_virtualStrength", "_queuedReinforcements"];
                
                // Get size data
                private _baseSize = _data param [6, 4]; 
                private _maxSize = _data param [7, 8];
                private _currentSize = _data param [8, count _units];
                
                // Check for virtualized state for this marker's garrison
                private _wasVirtualized = false;
                private _markerPos = getMarkerPos _marker;
                private _allVirtualizedKeys = [];
                
                // Check if we are using the virtualization system
                if (!isNil "VS_VirtualizedGroups") then {
                    // Look for virtualized groups that belong to this garrison
                    _allVirtualizedKeys = keys VS_VirtualizedGroups;
                    
                    {
                        private _vsKey = _x;
                        private _vsData = VS_VirtualizedGroups get _vsKey;
                        if (!isNil "_vsData") then {
                            private _vsPos = _vsData select 1;
                            
                            // If position is within 50m of marker, likely this garrison was virtualized
                            if (_vsPos distance2D _markerPos < 50) then {
                                _wasVirtualized = true;
                                
                                // Get data from the virtualized group
                                private _vsSide = _vsData select 0;
                                
                                // Only process EAST (OPFOR) virtualized groups
                                if (_vsSide == east) then {
                                    diag_log format ["[FLO][Garrison] Found virtualized garrison for marker %1", _marker];
                                    
                                    // We don't delete from VS_VirtualizedGroups - the virtualization system will handle that
                                    // But we update our tracking to know this was virtualized
                                    _data set [9, true]; // Mark as virtualized
                                };
                            };
                        };
                    } forEach _allVirtualizedKeys;
                };
                
                // Handle normal (non-virtualized) garrisons
                if (!_wasVirtualized) then {
                    // Check if this was previously virtualized but now restored
                    if (_data param [9, false]) then {
                        // This garrison was previously virtualized, now it's restored
                        // We need to find the newly created units near this marker
                        
                        private _nearUnits = _markerPos nearEntities ["CAManBase", 100] select {side _x == east};
                        private _nearVehicles = _markerPos nearEntities ["LandVehicle", 100] select {side _x == east};
                        
                        if (count _nearUnits > 0) then {
                            diag_log format ["[FLO][Garrison] Found %1 restored units for previously virtualized garrison at %2", 
                                count _nearUnits, _marker];
                            
                            // Update our tracking with the restored units
                            private _newGroup = group (_nearUnits select 0);
                            _data set [0, _nearUnits];
                            _data set [1, _nearVehicles];
                            _data set [2, _newGroup];
                            _data set [9, false]; // No longer virtualized
                            
                            // Set actual size to match current units (preserve virtual and queued counts)
                            private _actualSize = count _nearUnits;
                            _currentSize = _actualSize + _virtualStrength + _queuedReinforcements;
                            _data set [8, _currentSize];
                        } else {
                            // Was virtualized but now no units found - treat as dead
                            _data set [0, []];
                            _data set [1, []];
                            _data set [9, false];
                        };
                    } else {
                        // Normal non-virtualized garrison processing
                
                        // Check for alive units
                        private _aliveUnits = _units select {alive _x};
                        private _aliveVehicles = _vehicles select {alive _x};
                        
                        // Check for any units that aren't EAST and fix them
                        private _nonEastUnits = _aliveUnits select {side _x != east};
                        if (count _nonEastUnits > 0) then {
                            diag_log format ["[FLO][Garrison] Found %1 non-EAST units in garrison at %2, attempting to fix", count _nonEastUnits, _marker];
                            
                            private _eastGroup = createGroup [east, true];
                            {
                                [_x] joinSilent _eastGroup;
                                if (side _x != east) then {
                                    // If still not EAST, recreate the unit
                                    private _pos = getPosATL _x;
                                    private _type = typeOf _x;
                                    deleteVehicle _x;
                                    private _newUnit = _eastGroup createUnit [_type, _pos, [], 0, "NONE"];
                                    _aliveUnits set [_aliveUnits find _x, _newUnit];
                                };
                            } forEach _nonEastUnits;
                        };
                        
                        // Update actual vs intended size
                        private _actualSize = count _aliveUnits;
                        if (_actualSize != _currentSize - _virtualStrength - _queuedReinforcements) then {
                            // There's a discrepancy between actual units and tracked size
                            // This means some units died but haven't been accounted for
                            private _lostUnits = _currentSize - _virtualStrength - _queuedReinforcements - _actualSize;
                            if (_lostUnits > 0) then {
                                diag_log format ["[FLO][Garrison] Garrison at %1 lost %2 units, adjusting tracked size", _marker, _lostUnits];
                                // Reduce the current size by the number of lost units
                                _currentSize = _currentSize - _lostUnits;
                                _data set [8, _currentSize];
                            };
                        };
                        
                        // Update garrison data with alive units only
                        _data set [0, _aliveUnits];
                        _data set [1, _aliveVehicles];
                    };
                };
                
                // Check if garrison is completely gone (0 active units, 0 virtual strength, 0 queued units)
                if ((count (_data select 0) == 0) && _virtualStrength == 0 && _queuedReinforcements == 0 && !(_data param [9, false])) then {
                    // All units dead and no reinforcements queued, clean up
                    {deleteVehicle _x} forEach (_data select 1);
                    _garrisons deleteAt _marker;
                    diag_log format ["[FLO][Garrison] Garrison at %1 wiped out, removed", _marker];
                } else {
                    // Update garrison data timestamp
                    _data set [3, time]; // Update timestamp
                    _garrisons set [_marker, _data];
                    
                    // Count both physical and virtual units for total
                    private _physicalUnits = count (_data select 0);
                    _totalCount = _totalCount + _physicalUnits + _virtualStrength + _queuedReinforcements;
                    
                    // Don't log during virtualization (it's not useful)
                    if (!(_data param [9, false])) then {
                        // Log info about garrison status
                        diag_log format ["[FLO][Garrison] Garrison at %1: %2 active units, %3 virtual, %4 queued (%5/%6 capacity)", 
                            _marker, _physicalUnits, _virtualStrength, _queuedReinforcements, _currentSize, _maxSize];
                    };
                };
            } forEach keys _garrisons;
            
            // Update total count
            _self set ["totalUnits", _totalCount];
            _self set ["lastUpdate", time];
            
            diag_log format ["[FLO][Garrison] Maintenance complete. Total units: %1", _totalCount];
        }],
        
        // Get garrison info for a marker
        ["getGarrisonInfo", {
            params ["_marker"];
            
            private _garrisons = _self get "garrisons";
            if (!(_marker in keys _garrisons)) exitWith {
                []
            };
            
            private _data = _garrisons get _marker;
            _data params ["_units", "_vehicles", "_group", "_timestamp", "_virtualStrength", "_queuedReinforcements"];
            private _baseSize = _data param [6, 4];
            private _maxSize = _data param [7, 8];
            private _currentSize = _data param [8, count _units];
            
            private _aliveUnits = _units select {alive _x};
            private _aliveVehicles = _vehicles select {alive _x};
            
            [count _aliveUnits, count _aliveVehicles, _timestamp, _virtualStrength, _queuedReinforcements, _baseSize, _maxSize, _currentSize]
        }],
        
        // Check if a group is from a garrison
        ["isGarrisonGroup", {
            params ["_checkGroup"];
            
            private _isGarrisonGroup = false;
            private _marker = "";
            
            if (isNull _checkGroup) exitWith {[false, ""]};
            
            private _garrisons = _self get "garrisons";
            
            {
                private _garrisonMarker = _x;
                private _garrisonData = _garrisons get _garrisonMarker;
                private _garrisonGroup = _garrisonData param [2, grpNull];
                
                if (_checkGroup isEqualTo _garrisonGroup) exitWith {
                    _isGarrisonGroup = true;
                    _marker = _garrisonMarker;
                };
            } forEach keys _garrisons;
            
            [_isGarrisonGroup, _marker]
        }]
    ];
    
    // Create the garrison manager object
    FLO_Garrison_Manager = createHashMapObject [_garrisonManagerClass];
};

// Execute the requested mode
switch (_mode) do {
    // Initialize the garrison system
    case "init": {
        FLO_Garrison_Manager call ["initialize", []];
        _result = FLO_Garrison_Manager;
    };
    
    // Spawn a new garrison
    case "spawn": {
        _params params [
            ["_marker", "", [""]],
            ["_size", 8, [0]],
            ["_withVehicles", false, [false]]
        ];
        
        _result = FLO_Garrison_Manager call ["spawnGarrison", [_marker, _size, _withVehicles]];
    };
    
    // Reinforce an existing garrison
    case "reinforce": {
        _params params [
            ["_marker", "", [""]],
            ["_amount", 4, [0]]
        ];
        
        _result = FLO_Garrison_Manager call ["reinforceGarrison", [_marker, _amount]];
    };
    
    // Maintain all garrisons
    case "maintain": {
        FLO_Garrison_Manager call ["maintainGarrisons", []];
        _result = true;
    };
    
    // Check markers near players and spawn garrisons if needed
    case "checkAndSpawn": {
        _params params [
            ["_activationDistance", 1500, [0]]
        ];
        
        _result = FLO_Garrison_Manager call ["checkNearbyGarrisons", [_activationDistance]];
    };
    
    // Save garrison sizes to profileNamespace
    case "saveGarrisonSizes": {
        _result = FLO_Garrison_Manager call ["saveGarrisonSizes", []];
    };
    
    // Load garrison sizes from profileNamespace
    case "loadGarrisonSizes": {
        _result = FLO_Garrison_Manager call ["loadGarrisonSizes", []];
    };
    
    // Check if a group is from a garrison
    case "isGarrisonGroup": {
        _params params [
            ["_group", grpNull, [grpNull]]
        ];
        
        _result = FLO_Garrison_Manager call ["isGarrisonGroup", [_group]];
    };
    
    default {
        diag_log format ["[FLO][Garrison] Error: Unknown mode '%1'", _mode];
        _result = false;
    };
};

_result 