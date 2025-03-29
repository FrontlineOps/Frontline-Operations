/*
    Function: FLO_fnc_garrisonManager
    
    Description:
    Manages garrison spawning and maintenance for objectives.
    Uses OOP approach with HashMapObject for better organization and state management.
    Handles vehicle limits and tracking to prevent excessive vehicle spawning.
    
    Parameters:
        Based on calling FLO_Garrison_Manager:
            initialize: [] - No parameters needed
            spawnGarrison: [_marker, _size, _withVehicles] - Create a new garrison at marker
            reinforceGarrison: [_marker, _amount] - Add units to existing garrison
            maintainGarrisons: [] - Run maintenance on all garrisons
            checkNearbyGarrisons: [_activationDistance] - Check all markers and spawn garrisons near players
        saveGarrisonSizes: [] - Save current garrison sizes to profileNamespace
        loadGarrisonSizes: [] - Load garrison sizes from profileNamespace
        isGarrisonGroup: [_group] - Check if a group is from a garrison
            getGarrison: [_marker] - Get garrison data for a marker
            extractUnits: [_marker] - Extract units from a garrison
            returnUnits: [_marker] - Return units to pool
            canAddVehicle: [_marker, _vehicleType] - Check if a marker can accept another vehicle
            addVehicleToCount: [_marker, _vehicleType] - Add a vehicle to the tracking count
            removeVehicleFromCount: [_marker, _vehicleType] - Remove a vehicle from the count
            getVehicleLimits: [_markerType] - Get limit configuration for a marker type
            getSizeLimits: [_markerType] - Get size limit configuration for a marker type
        i.e: FLO_Garrison_Manager call ["spawnGarrison", [_marker, _size, _withVehicles]]
    
    Returns:
        May Return a Boolean or an Array depending on the Method called.
*/

if (!isServer) exitWith {};

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
        ["markerSizeLimits", createHashMap], // Property to store min/max sizes for marker types
        ["vehicleLimits", createHashMap],    // Property to store vehicle limits by marker type
        ["garrisonSizes", createHashMap],    // Property to store saved garrison sizes
        ["vehicleCounts", createHashMap],    // Property to track current vehicles at locations
        
        // Constructor - Called when object is created
        ["#create", {
            _self set ["garrisons", createHashMap];
            _self set ["lastUpdate", time];
            _self set ["totalUnits", 0];
            _self set ["processedMarkers", []];
            _self set ["garrisonSizes", createHashMap];
            _self set ["vehicleCounts", createHashMap];
            
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
            
            // Define vehicle limits for each marker type
            // Format: [lightVehiclesMax, heavyVehiclesMax, totalVehiclesMax]
            private _vehicleLimits = createHashMap;
            _vehicleLimits set ["n_installation", [4, 2, 6]];
            _vehicleLimits set ["o_installation", [3, 1, 4]];
            _vehicleLimits set ["n_support", [3, 1, 4]];
            _vehicleLimits set ["o_support", [2, 1, 3]];
            _vehicleLimits set ["loc_Power", [2, 0, 2]];
            _vehicleLimits set ["o_recon", [1, 0, 1]];
            _vehicleLimits set ["o_service", [2, 0, 2]];
            _vehicleLimits set ["o_antiair", [1, 1, 2]];
            _vehicleLimits set ["loc_Ruin", [2, 0, 2]];
            _vehicleLimits set ["default", [1, 0, 1]];
            
            _self set ["vehicleLimits", _vehicleLimits];
            
            ["Garrison", 3, "Manager initialized with size and vehicle limits"] call FLO_fnc_log;

            // Initialize garrison system and start maintenance loop
            _self call ["initialize", []];
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
        
        // Get vehicle limits for marker type
        ["getVehicleLimits", {
            params ["_markerType"];
            
            private _vehicleLimits = _self get "vehicleLimits";
            if (_markerType in keys _vehicleLimits) then {
                _vehicleLimits get _markerType
            } else {
                _vehicleLimits get "default"
            }
        }],
        
        // Initialize garrison system and start maintenance loop
        ["initialize", {
            // Load saved garrison sizes if available
            _self call ["loadGarrisonSizes", []];
            
            // Initialize default garrison entries for all OPFOR objectives
            _self call ["initializeDefaultGarrisons", []];
            
            // Start the maintenance loop
            [_self] spawn {
                params ["_self"];
                while {true} do {
                    // Run maintenance every 5 minutes
                    _self call ["maintainGarrisons", []];
                    sleep 300;
                };
            };
            
            // Start the spawn check loop
            [_self] spawn {
                params ["_self"];
                while {true} do {
                    // Check for new garrisons to spawn
                    _self call ["checkNearbyGarrisons", [1500]];
                    sleep 30;
                };
            };
        }],
        
        // Initialize default garrison entries for all OPFOR objectives
        ["initializeDefaultGarrisons", {
            private _garrisons = _self get "garrisons";
            
            // Find all OPFOR markers that can have garrisons
            private _opforMarkers = allMapMarkers select {
                markerColor _x in ["colorOPFOR", "ColorEAST"] && 
                markerType _x in ["o_support", "n_support", "n_installation", "o_installation", 
                                "loc_Power", "o_recon", "o_service", "o_antiair", "loc_Ruin"]
            };
            
            // Create a default garrison entry for each marker if it doesn't exist already
            {
                private _marker = _x;
                // Skip if garrison already exists
                if (_marker in keys _garrisons) then {
                    continue;
                };
                
                // Get the marker type to determine size limits
                private _markerType = markerType _marker;
                private _sizeLimits = _self call ["getSizeLimits", [_markerType]];
                private _baseSize = _sizeLimits select 0;
                private _maxSize = _sizeLimits select 1;
                
                // Set initial size to base size
                private _initialSize = _baseSize;
                
                // Get saved garrison size if available
                private _garrisonSizes = _self get "garrisonSizes";
                if (_marker in keys _garrisonSizes) then {
                    _initialSize = (_garrisonSizes get _marker) min _maxSize;
                };
                
                // Create an empty garrison entry
                _garrisons set [_marker, [
                    [], // No units
                    [], // No vehicles
                    grpNull, // No group
                    time, // Creation timestamp
                    _baseSize, // Base size
                    _maxSize, // Max size
                    _initialSize // Current intended size
                ]];
            } forEach _opforMarkers;
            
            ["Garrison", 3, format["Initialized default garrison entries for %1 OPFOR objectives", count _opforMarkers]] call FLO_fnc_log;
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
                    // Get the current intended size from the data
                    private _size = _garrisonData param [6, 0];
                    
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
                ["Garrison", 3, format["Saved sizes for %1 garrisons with %2 total units. Breakdown by type: %3",
                    count keys _garrisonSizes, _totalSize, _logDetails]] call FLO_fnc_log;
            } else {
                ["Garrison", 3, format["Saved sizes for %1 garrisons with %2 total units.", 
                    count keys _garrisonSizes, _totalSize]] call FLO_fnc_log;
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
                    ["Garrison", 3, format["Loaded sizes for %1 garrisons with %2 total units. Breakdown by type: %3", 
                        count keys _savedGarrisonSizes, _totalSize, _logDetails]] call FLO_fnc_log;
                } else {
                    ["Garrison", 3, format["Loaded sizes for %1 garrisons with %2 total units.", 
                        count keys _savedGarrisonSizes, _totalSize]] call FLO_fnc_log;
                };
                
                true
            } else {
                ["Garrison", 3, "No saved garrison sizes found"] call FLO_fnc_log;
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
                // Check if any player is within 750m of the marker
                {
                    private _markerPos = getMarkerPos _x;
                    private _tooClose = false;
                    {
                        if (_x distance _markerPos < 750) exitWith {
                            _tooClose = true;
                        };
                    } forEach _allPlayers;
                    !_tooClose
                }
            };
            
            // Debug log
            ["Garrison", 4, format["Checking %1 OPFOR markers for garrison activation", count _opforMarkers]] call FLO_fnc_log;
            
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
                    // Get current garrison size from garrisonSizes
                    private _additionalUnits = 0;
                    
                    // Check if there are already physical units at this location
                    private _existingUnits = 0;
                    if (_marker in keys _garrisons) then {
                        private _garrisonData = _garrisons get _marker;
                        private _units = _garrisonData select 0;
                        private _aliveUnits = _units select {!isNil "_x" && {alive _x}};
                        _existingUnits = count _aliveUnits;
                        
                        // Log existing units
                        ["Garrison", 4, format["Found %1 existing units at marker %2", _existingUnits, _marker]] call FLO_fnc_log;
                        
                        // If no physical units exist, delete the garrison entry to allow respawning
                        if (_existingUnits == 0) then {
                            ["Garrison", 4, format["Deleting empty garrison entry for %1 to allow fresh spawn", _marker]] call FLO_fnc_log;
                                _garrisons deleteAt _marker;
                        };
                    };
                    
                    // Get size limits for this marker type (only for initialization if needed)
                    private _sizeLimits = _self call ["getSizeLimits", [_markerType]];
                    private _baseSize = _sizeLimits select 0;
                    private _maxSize = _sizeLimits select 1;
                    
                    // Initialize size in garrisonSizes if needed
                    if (!(_marker in keys _garrisonSizes)) then {
                        _garrisonSizes set [_marker, _baseSize];
                        ["Garrison", 3, format["Initializing new garrison size for %1 with base size %2", _marker, _baseSize]] call FLO_fnc_log;
                    };
                    
                    // Get the desired size
                    private _size = _garrisonSizes get _marker;
                    
                    // Sanity check - ensure minimum size of 1
                    if (_size <= 0) then {
                        ["Garrison", 3, format["Correcting invalid garrison size for %1 from %2 to base size %3", 
                            _marker, _size, _baseSize]] call FLO_fnc_log;
                        _size = _baseSize;
                        _garrisonSizes set [_marker, _baseSize];
                    };
                    
                    // If existing units < desired size and desired size > 0, spawn the garrison
                    if (_size > _existingUnits && _size > 0) then {
                        ["Garrison", 3, format["Spawning garrison at %1 with size %2 (existing units: %3)", 
                            _marker, _size, _existingUnits]] call FLO_fnc_log;
                        
                        // Determine if vehicles should be spawned based on marker type and size
                        private _withVehicles = true; // Set to true to enable vehicle spawning
                        
                        // Get vehicle limits for this marker type
                        private _vehicleLimits = _self call ["getVehicleLimits", [_markerType]];
                        _vehicleLimits params ["_lightMax", "_heavyMax", "_totalMax"];
                        
                        // Don't spawn vehicles if this marker type has no vehicle allowance
                        if (_totalMax <= 0) then {
                            _withVehicles = false;
                        };
                        
                        // Spawn garrison with current size from garrisonSizes and appropriate vehicle setting
                        _self call ["spawnGarrison", [_marker, _size, _withVehicles, _baseSize, _maxSize]];
                        
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
                // Error logs
                ["Garrison", 1, "Error: Empty marker name"] call FLO_fnc_log;
                []
            };
            
            private _pos = getMarkerPos _marker;
            if (_pos isEqualTo [0,0,0]) exitWith {
                // Error logs with params
                ["Garrison", 1, format["Error: Invalid marker position for %1", _marker]] call FLO_fnc_log;
                []
            };
            
            // If base and max size weren't provided, get them from marker type
            if (_baseSize == 0 || _maxSize == 0) then {
                private _markerType = markerType _marker;
                private _sizeLimits = _self call ["getSizeLimits", [_markerType]];
                _baseSize = _sizeLimits select 0;
                _maxSize = _sizeLimits select 1;
            };
            
            // Update garrisonSizes with this size
            private _garrisonSizes = _self get "garrisonSizes";
            _garrisonSizes set [_marker, _size];
            
            // Log the garrison size update
            ["Garrison", 3, format["Updated garrisonSizes for %1 to %2 during spawn", _marker, _size]] call FLO_fnc_log;
            
            // Default composition based on size using East_Units
            private _composition = [];
            
            // Get available unit types from global variables
            private _availableUnits = East_Units;
            private _officerUnits = East_Units_Officers;
            
            // Generate compositions based on size
            // MODIFIED: No size categories, just create the exact number requested
            for "_i" from 1 to _size do {
                        _composition pushBack [selectRandom _availableUnits, 1];
            };
            
            // Add logging to verify unit composition generation
            ["Garrison", 2, format["SPAWNING: Generated composition of %1 units for garrison at marker '%2' (requested size: %3)", 
                count _composition, _marker, _size]] call FLO_fnc_log;
            
            // Create main group before spawning vehicles
            private _spawnedUnits = [];
            private _spawnedVehicles = [];
            private _group = createGroup [east, true];
            _group deleteGroupWhenEmpty true;
            
            // Add vehicles if requested
            if (_withVehicles) then {
                // Use vehicle types from global variables
                private _lightVehicles = East_Ground_Vehicles_Light;
                private _heavyVehicles = East_Ground_Vehicles_Heavy;
                
                // Get the marker type
                private _markerType = markerType _marker;
                
                // Get vehicle limits for this marker type
                private _limits = _self call ["getVehicleLimits", [_markerType]];
                _limits params ["_lightMax", "_heavyMax", "_totalMax"];
                
                // Get current vehicle counts
                private _vehicleCounts = _self get "vehicleCounts";
                private _currentCounts = _vehicleCounts getOrDefault [_marker, [0, 0, 0]];
                _currentCounts params ["_currentLight", "_currentHeavy", "_currentTotal"];
                
                // Calculate how many vehicles we can add
                private _availableLightSlots = _lightMax - _currentLight;
                private _availableHeavySlots = _heavyMax - _currentHeavy;
                private _availableTotalSlots = _totalMax - _currentTotal;
                
                // Define vehicle composition based on size and available slots
                private _vehicles = [];
                
                // Add light vehicles first
                if (_availableLightSlots > 0 && _availableTotalSlots > 0 && _size >= 4) then {
                    private _lightToAdd = 1 min _availableLightSlots min _availableTotalSlots;
                    
                    if (_size >= 8 && _availableLightSlots >= 2 && _availableTotalSlots >= 2) then {
                        _lightToAdd = 2;
                    };
                    
                    for "_i" from 1 to _lightToAdd do {
                        _vehicles pushBack [selectRandom _lightVehicles, 1];
                    };
                    
                    // Update counts
                    _availableLightSlots = _availableLightSlots - _lightToAdd;
                    _availableTotalSlots = _availableTotalSlots - _lightToAdd;
                    
                    // Add to vehicle counts
                    _currentLight = _currentLight + _lightToAdd;
                    _currentTotal = _currentTotal + _lightToAdd;
                };
                
                // Then add heavy vehicle if appropriate
                if (_availableHeavySlots > 0 && _availableTotalSlots > 0 && _size >= 12) then {
                    _vehicles pushBack [selectRandom _heavyVehicles, 1];
                    
                    // Update counts
                    _currentHeavy = _currentHeavy + 1;
                    _currentTotal = _currentTotal + 1;
                };
                
                // Update the vehicle counts in the hashmap
                _vehicleCounts set [_marker, [_currentLight, _currentHeavy, _currentTotal]];
                
                // Log the vehicle composition
                ["Garrison", 3, format["Adding %1 vehicles to garrison at %2 (counts now: [%3,%4,%5])", 
                    count _vehicles, _marker, _currentLight, _currentHeavy, _currentTotal]] call FLO_fnc_log;
                
                // Spawn each vehicle
            {
                _x params ["_type", "_count"];
                for "_i" from 1 to _count do {
                    private _vehPos = [_pos, 10, 100, 5, 0, 0.5, 0, [], [_pos, _pos]] call BIS_fnc_findSafePos;
                    private _veh = createVehicle [_type, _vehPos, [], 0, "NONE"];
                    
                        ["Garrison", 3, format["Created vehicle %1 of type %2", _veh, _type]] call FLO_fnc_log;
                        
                        // Create crew with explicit EAST side and get reference to the crew
                        private _crew = units (east createVehicleCrew _veh);
                        // Get the crew's group - when createVehicleCrew is called, it creates a new group automatically
                        private _vehGroup = if (count _crew > 0) then {group (_crew select 0)} else {createGroup [east, true]};
                        _vehGroup deleteGroupWhenEmpty true;

                        ["Garrison", 3, format["createVehicleCrew resulted in %1 crew members", count _crew]] call FLO_fnc_log;
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
                                        ["Garrison", 3, format["Vehicle crew killed at %1 triggered QRF request", _markerData]] call FLO_fnc_log;
                                        [_unitPos, 500] call FLO_fnc_requestQRF;
                                    };
                                };
                            }];
                        };
                    } forEach (crew _veh);
                    
                    // Verify crew is EAST
                    {
                        if (side _x != east) then {
                            ["Garrison", 2, format["WARNING: Vehicle crew member %1 is not EAST after creation", _x]] call FLO_fnc_log;
                        };
                    } forEach (crew _veh);
                        
                        // Determine if vehicle should patrol or defend (70% defend, 30% patrol)
                        if (random 1 < 0.7) then {
                            // DEFEND - Set up a defensive position or small area patrol
                            private _vehGroup = group driver _veh;
                            
                            // Give the group a defensive stance
                            _vehGroup setCombatMode "RED";
                            _vehGroup setBehaviour "AWARE";
                            
                            // Small area defense pattern
                            // Create a sentry waypoint
                            private _wp = _vehGroup addWaypoint [_vehPos, 0];
                            _wp setWaypointType "SENTRY";
                            _wp setWaypointCombatMode "RED";
                            _wp setWaypointBehaviour "AWARE";
                            _wp setWaypointSpeed "LIMITED";
                            
                            ["Garrison", 3, format["Vehicle %1 assigned to DEFENSE at %2", _veh, markerText _marker]] call FLO_fnc_log;
                        } else {
                            // PATROL - Set up a patrol pattern around the area
                            private _vehGroup = group driver _veh;
                            
                            // Set up the patrol parameters
                            _vehGroup setCombatMode "RED";
                            _vehGroup setBehaviour "AWARE";
                            _vehGroup setSpeedMode "LIMITED";
                            
                            // Create a patrol route
                            [_vehGroup, _pos, 300] call BIS_fnc_taskPatrol;
                            
                            ["Garrison", 3, format["Vehicle %1 assigned to PATROL around %2", _veh, markerText _marker]] call FLO_fnc_log;
                        };
                        
                        // Add vehicle to our tracking
                        _spawnedVehicles pushBack _veh;
                };
            } forEach _vehicles;
            };
            
            // Spawn units
            {
                _x params ["_type", "_count"];
                for "_i" from 1 to _count do {
                    // Create the unit with explicit EAST side
                    private _unit = _group createUnit [_type, _pos, [], 50, "NONE"];
                    
                    // Force side to EAST if needed
                    if (side _unit != east) then {
                        private _newUnit = createGroup [east, true] createUnit [_type, _pos, [], 50, "NONE"];
                        (group _newUnit) deleteGroupWhenEmpty true;
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
                                    ["Garrison", 3, format["Unit killed at %1 triggered QRF request (officer: %2)", _markerData, _isOfficer]] call FLO_fnc_log;
                                    [_unitPos, 500] call FLO_fnc_requestQRF;
                                };
                            };
                        }];
                        
                        // Store officer status for QRF chance calculation
                        _unit setVariable ["FLO_IsOfficer", _isOfficer, false];
                        
                        if (_isOfficer) then {
                            ["Garrison", 3, format["Officer unit %1 assigned QRF trigger capability", _unit]] call FLO_fnc_log;
                        };
                    };
                    
                    _spawnedUnits pushBack _unit;
                };
            } forEach _composition;
            
            // Verify that all units are properly assigned to EAST
            if (side _group != east) then {
                ["Garrison", 2, "WARNING: Group side is not EAST after creation. Creating new EAST group..."] call FLO_fnc_log;
                private _eastGroup = createGroup [east, true];
                _eastGroup deleteGroupWhenEmpty true;
                {
                    [_x] joinSilent _eastGroup;
                    // Double-check individual unit sides
                    if (side _x != east) then {
                        ["Garrison", 2, format["WARNING: Unit %1 is not EAST after joining group", _x]] call FLO_fnc_log;
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
            if (count _buildingPositions > 200) then {
                _buildingPositions resize 200;
            };
            
            // Log the number of available positions for reference
            ["Garrison", 3, format["Found %1 building positions for garrison at %2", count _buildingPositions, _marker]] call FLO_fnc_log;
            
            // Split the group based on buildings available and garrison size
            if (count _buildingPositions > 3 && count _spawnedUnits > 3) then {
                // Garrison units - 2/3 of units go to buildings
                private _garrisonUnits = floor ((count _spawnedUnits) * 0.6);
                private _garrisonGroup = createGroup [east, true];
                _garrisonGroup deleteGroupWhenEmpty true;
                
                for "_i" from 1 to (_garrisonUnits min count _buildingPositions) do {
                    if (count _spawnedUnits > 0) then {
                        private _unit = _spawnedUnits deleteAt 0;
                        [_unit] joinSilent _garrisonGroup;
                        
                        // Verify unit is EAST after joining garrison group
                        if (side _unit != east) then {
                            ["Garrison", 2, format["WARNING: Unit %1 lost EAST side after joining garrison group", _unit]] call FLO_fnc_log;
                            // Force the unit back to EAST if needed
                            [_unit] joinSilent createGroup [east, true];
                            (group _unit) deleteGroupWhenEmpty true;
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
                    _patrolGroup deleteGroupWhenEmpty true;
                    
                    {
                        [_x] joinSilent _patrolGroup;
                        
                        // Verify unit is EAST after joining patrol group
                        if (side _x != east) then {
                            ["Garrison", 2, format["WARNING: Unit %1 lost EAST side after joining patrol group", _x]] call FLO_fnc_log;
                            // Force the unit back to EAST if needed
                            [_x] joinSilent createGroup [east, true];
                            (group _x) deleteGroupWhenEmpty true;
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
                    ["Garrison", 2, format["FINAL CHECK: Unit %1 is not EAST after all processing", _x]] call FLO_fnc_log;
                };
            } forEach (_spawnedUnits select {alive _x});
            
            // ADDED: Assign military-style group ID
            private _squadNames = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima"];
            private _markerNum = count(_self get "processedMarkers") + 1;
            private _squadNamePrefix = _squadNames select ((_markerNum - 1) mod (count _squadNames));
            private _platoonNum = floor((_markerNum - 1) / count _squadNames) + 1;
            private _squadNum = floor(random 5) + 1;
            
            private _squadID = format ["%1 %2-%3", _squadNamePrefix, _platoonNum, _squadNum];
            
            // Set the group ID for the main group
            _group setGroupIdGlobal [_squadID];
            
            // If we created a patrol group, name it too
            if (count _spawnedUnits > 3 && count _buildingPositions > 3) then {
                // Only set group ID if _patrolGroup is defined
                if (!isNil "_patrolGroup" && {!isNull _patrolGroup}) then {
                private _patrolID = format ["%1 %2-%3 Patrol", _squadNamePrefix, _platoonNum, _squadNum + 1];
                _patrolGroup setGroupIdGlobal [_patrolID];
                };
            };
            
            ["Garrison", 3, format["Set group ID for garrison at %1 to '%2'", _marker, _squadID]] call FLO_fnc_log;
            
            // Store in garrisons hashmap
            private _garrisons = _self get "garrisons";
            
            // Garrison data structure:
            // [units, vehicles, group, timestamp, baseSize, maxSize, currentSize, isVirtualized]
            _garrisons set [_marker, [
                _spawnedUnits,                // Actual spawned units
                _spawnedVehicles,             // Spawned vehicles
                _group,                       // Main group
                time,                         // Creation timestamp
                _baseSize,                    // Base size from marker type
                _maxSize,                     // Maximum allowed size
                _size                         // Current intended size
            ]];
            
            // Update total units count
            _self set ["totalUnits", (_self get "totalUnits") + count _spawnedUnits];
            
            ["Garrison", 3, format["Created garrison at %1 with %2 units and %3 vehicles (Size: %4/%5)", 
                _marker, count _spawnedUnits, count _spawnedVehicles, _size, _maxSize]] call FLO_fnc_log;
            
            // Return spawned units
            _spawnedUnits
        }],
        
        // Reinforce an existing garrison - ONLY UPDATES TRACKED COUNT, NEVER SPAWNS UNITS
        ["reinforceGarrison", {
            params ["_marker", "_amount", ["_withVehicles", false, [true]]];
            
            private _garrisons = _self get "garrisons";
            
            // Check if garrison exists
            if (!(_marker in keys _garrisons)) then {
                ["Garrison", 3, format["Cannot reinforce non-existent garrison at %1", _marker]] call FLO_fnc_log;
            } else {
                // Garrison exists - process reinforcement based on size limits only
                private _garrisonData = _garrisons get _marker;
                
                // Get the size limits
                private _baseSize = _garrisonData param [4, 4];
                private _maxSize = _garrisonData param [5, 8];
                private _currentSize = _garrisonData param [6, 0];
                
                // Check if we've already reached max size
                if (_currentSize >= _maxSize) then {
                    ["Garrison", 3, format["Garrison at %1 already at maximum size (%2), reinforcement rejected", _marker, _maxSize]] call FLO_fnc_log;
                } else {
                    // Calculate how many reinforcements can be added before reaching max
                    private _availableSpace = _maxSize - _currentSize;
                    private _reinforcementCount = _amount min _availableSpace;
                    
                    // Log if we're capping reinforcements
                    if (_reinforcementCount < _amount) then {
                        ["Garrison", 3, format["Reinforcement for %1 limited from %2 to %3 units due to size cap (%4/%5)", 
                            _marker, _amount, _reinforcementCount, _currentSize, _maxSize]] call FLO_fnc_log;
                    };
                    
                    // Update current intended size
                    _currentSize = _currentSize + _reinforcementCount;
                    _garrisonData set [6, _currentSize];
                    
                    // Save updated garrison data
                    _garrisons set [_marker, _garrisonData];
                    
                    ["Garrison", 3, format["Reinforced garrison at %1: added %2 units to intended size (now %3/%4)", 
                        _marker, _reinforcementCount, _currentSize, _maxSize]] call FLO_fnc_log;
                    
                    // Update saved garrison size for persistence
                    private _garrisonSizes = _self get "garrisonSizes";
                    _garrisonSizes set [_marker, _currentSize min _maxSize];
                    
                    // Handle vehicle reinforcement (just update counts, don't spawn anything)
                    if (_withVehicles) then {
                        // Determine vehicle type based on marker type and rarity
                        private _markerType = markerType _marker;
                        private _vehicleType = "";
                        private _isHeavyVehicle = false;
                        
                        // Higher chance of heavy vehicles at important installations
                        if (_markerType in ["n_installation", "o_installation"] && random 1 < 0.3) then {
                            // 30% chance of heavy vehicle at major installations
                            _isHeavyVehicle = true;
                        } else {
                            if (_markerType in ["n_support", "o_support"] && random 1 < 0.2) then {
                                // 20% chance of heavy vehicle at support locations
                                _isHeavyVehicle = true;
                            } else {
                                if (_markerType == "o_antiair" && random 1 < 0.4) then {
                                    // 40% chance of heavy vehicle at AA sites
                                    _isHeavyVehicle = true;
                                };
                            };
                        };
                        
                        // Select vehicle based on type
                        if (_isHeavyVehicle) then {
                            if (count East_Ground_Vehicles_Heavy > 0) then {
                                _vehicleType = selectRandom East_Ground_Vehicles_Heavy;
                            } else {
                                _vehicleType = selectRandom East_Ground_Vehicles_Light;
                            };
                        } else {
                            _vehicleType = selectRandom East_Ground_Vehicles_Light;
                        };
                        
                        // Check if we can add a vehicle to this location with our own method
                        private _canAddVehicle = _self call ["canAddVehicle", [_marker, _vehicleType]];
                        
                        if (_canAddVehicle) then {
                            // Add the vehicle to our own vehicle count ONLY (don't spawn it)
                            _self call ["addVehicleToCount", [_marker, _vehicleType]];
                            
                            // Log the addition
                            ["Garrison", 3, format["Added %1 to vehicle count for %2 during reinforcement", 
                                if (_isHeavyVehicle) then {"heavy vehicle"} else {"light vehicle"}, _marker]] call FLO_fnc_log;
                        } else {
                            ["Garrison", 3, format["Cannot add vehicle to %1, vehicle limits reached", _marker]] call FLO_fnc_log;
                        };
                    };
                };
            };
        }],
        
        // Maintain all garrisons - simplified without queued/virtual reinforcements
        ["maintainGarrisons", {
            private _garrisons = _self get "garrisons";
            private _garrisonSizes = _self get "garrisonSizes";
            private _vehicleCounts = _self get "vehicleCounts";
            private _totalCount = 0;
            
            // Process each garrison
            {
                private _marker = _x;
                private _data = _garrisons get _marker;
                _data params ["_units", "_vehicles", "_group", "_timestamp"];
                
                // Get size data
                private _baseSize = _data param [4, 4]; 
                private _maxSize = _data param [5, 8];
                
                // Get the current intended size from garrisonSizes
                private _currentSize = 0;
                if (_marker in keys _garrisonSizes) then {
                    _currentSize = _garrisonSizes get _marker;
                };
                
                // Check for virtualized state for this marker's garrison
                private _wasVirtualized = false;
                private _markerPos = getMarkerPos _marker;
                
                // Handle virtualization system (if used)
                if (!isNil "VS_VirtualizedGroups") then {
                    // Code to handle virtualized groups - preserved from original
                    private _allVirtualizedKeys = keys VS_VirtualizedGroups;
                    
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
                                    ["Garrison", 3, format["Found virtualized garrison for marker %1", _marker]] call FLO_fnc_log;
                                    _data set [7, true]; // Mark as virtualized
                                };
                            };
                        };
                    } forEach _allVirtualizedKeys;
                };
                
                // Handle normal (non-virtualized) garrisons
                if (!_wasVirtualized) then {
                    // Check if this was previously virtualized but now restored
                    if (_data param [7, false]) then {
                        // This garrison was previously virtualized, now it's restored
                        // We need to find the newly created units and vehicles near this marker
                        
                        private _nearUnits = _markerPos nearEntities ["CAManBase", 100] select {side _x == east};
                        private _nearVehicles = _markerPos nearEntities [["Car", "Tank", "Truck"], 100] select {side _x == east};
                        
                        if (count _nearUnits > 0) then {
                            ["Garrison", 3, format["Found %1 restored units and %2 vehicles for previously virtualized garrison at %3", 
                                count _nearUnits, count _nearVehicles, _marker]] call FLO_fnc_log;
                            
                            // Update our tracking with the restored units
                            private _newGroup = group (_nearUnits select 0);
                            _data set [0, _nearUnits];
                            _data set [1, _nearVehicles];
                            _data set [2, _newGroup];
                            _data set [7, false]; // No longer virtualized
                            
                            // Update garrisonSizes based on actual unit count
                            if (_marker in keys _garrisonSizes && count _nearUnits < _currentSize) then {
                                ["Garrison", 3, format["Updating garrisonSizes for %1 from %2 to %3 based on actual restored unit count", 
                                    _marker, _currentSize, count _nearUnits]] call FLO_fnc_log;
                                
                                _garrisonSizes set [_marker, count _nearUnits];
                            };
                            
                            // Also update vehicle counts based on found vehicles
                            if (count _nearVehicles > 0) then {
                                private _lightCount = 0;
                                private _heavyCount = 0;
                                
                                {
                                    private _vehType = typeOf _x;
                                    if (_vehType in East_Ground_Vehicles_Heavy) then {
                                        _heavyCount = _heavyCount + 1;
                                    } else {
                                        _lightCount = _lightCount + 1;
                                    };
                                } forEach _nearVehicles;
                                
                                _vehicleCounts set [_marker, [_lightCount, _heavyCount, _lightCount + _heavyCount]];
                                ["Garrison", 3, format["Updated vehicle counts for %1 to [%2,%3,%4] based on restored vehicles", 
                                    _marker, _lightCount, _heavyCount, _lightCount + _heavyCount]] call FLO_fnc_log;
                            };
                        } else {
                            // Was virtualized but now no units found - treat as empty
                            _data set [0, []];
                            _data set [1, []];
                            _data set [7, false];
                            
                            // We found no units after virtualization, but we need to be careful
                            // This might be because units are dead, OR because virtualization
                            // didn't handle the transition correctly
                            if (_marker in keys _garrisonSizes && _currentSize > 0) then {
                                // Log but DON'T update garrisonSizes to 0 - it's safest to maintain
                                // the current size and let the player kill them if they respawn
                                ["Garrison", 3, format["No units found after virtualization for %1. Maintaining size at %2", 
                                    _marker, _garrisonSizes get _marker]] call FLO_fnc_log;
                                
                                // Optionally reset the garrison data so it can be respawned
                                _garrisons deleteAt _marker;
                                
                                // Reset vehicle counts for this marker
                                if (_marker in keys _vehicleCounts) then {
                                    _vehicleCounts deleteAt _marker;
                                    ["Garrison", 3, format["Reset vehicle counts for %1 after no units found post-virtualization", _marker]] call FLO_fnc_log;
                                };
                            };
                        };
                    } else {
                        // Normal non-virtualized garrison processing
                
                        // Check for alive units and vehicles
                        private _aliveUnits = _units select {alive _x};
                        private _aliveVehicles = _vehicles select {alive _x};
                        
                        // Check for any units that aren't EAST and fix them
                        private _nonEastUnits = _aliveUnits select {side _x != east};
                        if (count _nonEastUnits > 0) then {
                            
                            private _eastGroup = createGroup [east, true];
                            _eastGroup deleteGroupWhenEmpty true;
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
                        
                        // Update actual unit count and vehicles list
                        _data set [0, _aliveUnits];
                        _data set [1, _aliveVehicles];
                        
                        // Update garrisonSizes to reflect combat losses - ONLY if we're sure they're dead
                        // and not just deactivated in a different area from players
                        private _aliveCount = count _aliveUnits;
                        
                        // Only consider losses if:
                        // 1. We have active units (not just an empty array due to deactivation)
                        // 2. The current alive count is less than what's in garrisonSizes
                        // 3. The marker is in garrisonSizes
                        if (_marker in keys _garrisonSizes && count _units > 0 && _aliveCount < _currentSize) then {
                            ["Garrison", 3, format["Combat losses detected for %1: Updating garrisonSizes from %2 to %3 (alive: %4/%5)", 
                                _marker, _currentSize, _aliveCount, _aliveCount, count _units]] call FLO_fnc_log;
                            
                            _garrisonSizes set [_marker, _aliveCount];
                        };
                        
                        // Update vehicle counts based on what's still alive
                        if (count _vehicles > 0) then {
                            private _deadVehicles = _vehicles - _aliveVehicles;
                            
                            if (count _deadVehicles > 0 && _marker in keys _vehicleCounts) then {
                                private _currentCounts = _vehicleCounts get _marker;
                                private _lightLosses = 0;
                                private _heavyLosses = 0;
                                
                                {
                                    private _vehType = typeOf _x;
                                    if (_vehType in East_Ground_Vehicles_Heavy) then {
                                        _heavyLosses = _heavyLosses + 1;
                                    } else {
                                        _lightLosses = _lightLosses + 1;
                                    };
                                } forEach _deadVehicles;
                                
                                // Only update if we detected losses
                                if (_lightLosses > 0 || _heavyLosses > 0) then {
                                    // Reduce counts but don't go below 0
                                    private _newLightCount = (_currentCounts select 0) - _lightLosses;
                                    private _newHeavyCount = (_currentCounts select 1) - _heavyLosses;
                                    _newLightCount = _newLightCount max 0;
                                    _newHeavyCount = _newHeavyCount max 0;
                                    private _newTotalCount = _newLightCount + _newHeavyCount;
                                    
                                    _vehicleCounts set [_marker, [_newLightCount, _newHeavyCount, _newTotalCount]];
                                    ["Garrison", 3, format["Combat losses for vehicles at %1: Lost %2 light and %3 heavy. New counts: [%4,%5,%6]", 
                                        _marker, _lightLosses, _heavyLosses, _newLightCount, _newHeavyCount, _newTotalCount]] call FLO_fnc_log;
                                };
                            };
                        };
                    };
                };
                
                // Update garrison data timestamp
                _data set [3, time];
                _garrisons set [_marker, _data];
                
                // Get current count of units for total
                private _physicalUnits = count (_data select 0);
                _totalCount = _totalCount + _physicalUnits;
                
                // Don't log during virtualization (it's not useful)
                if (!(_data param [7, false])) then {
                    // Get the updated size from garrisonSizes
                    private _updatedSize = _garrisonSizes getOrDefault [_marker, 0];
                    
                    // Log info about garrison status
                    ["Garrison", 3, format["Garrison at %1: %2 active units (%3 in garrisonSizes)", 
                        _marker, _physicalUnits, _updatedSize]] call FLO_fnc_log;
                };
            } forEach keys _garrisons;
            
            // Update total count
            _self set ["totalUnits", _totalCount];
            _self set ["lastUpdate", time];
            
            // Update and cleanup vehicle counts - moved logic directly into the maintenance loop above
            // to avoid spawning a separate thread
            
            // Save garrisonSizes to profileNamespace to persist combat losses
            _self call ["saveGarrisonSizes", []];
            
            ["Garrison", 3, format["Maintenance complete. Total units: %1", _totalCount]] call FLO_fnc_log;
        }],
        
        // Get info about a specific garrison
        ["getGarrison", {
            params ["_marker"];
            
            private _garrisons = _self get "garrisons";
            private _garrisonSizes = _self get "garrisonSizes";
            private _result = [];
            
            if (_marker in keys _garrisons) then {
                private _data = _garrisons get _marker;
                _data params ["_units", "_vehicles", "_group", "_timestamp"];
                
                // Count alive units
                private _aliveUnits = _units select {alive _x};
                private _aliveVehicles = _vehicles select {alive _x};
                
                // Get size data
                private _baseSize = _data param [4, 4]; 
                private _maxSize = _data param [5, 8];
                private _intendedSize = 0;
                
                // Get size from garrisonSizes if available
                if (_marker in keys _garrisonSizes) then {
                    _intendedSize = _garrisonSizes get _marker;
                } else {
                    // Fallback to count of alive units if no size is defined
                    _intendedSize = count _aliveUnits;
                };
                
                // Get virtualization status
                private _isVirtualized = _data param [7, false];
                
                // Return data in a structured array for external access
                _result = [
                    _aliveUnits,         // [0] Alive units array
                    _aliveVehicles,      // [1] Alive vehicles array
                    _group,              // [2] Group
                    count _aliveUnits,   // [3] Current unit count
                    _intendedSize,       // [4] Intended size from garrisonSizes
                    _marker,             // [5] Marker
                    _isVirtualized,      // [6] Is virtualized flag
                    _baseSize,           // [7] Base size
                    _maxSize             // [8] Max size
                ];
            };
            
            _result
        }],
        
        // Extract units from a garrison for use by other systems
        ["extractUnits", {
            params [
                ["_marker", "", [""]],
                ["_count", 0, [0]],
                ["_requesterId", "", [""]]
            ];
            
            // Debug log for tracing issues
            ["Garrison", 4, format["Starting extraction of %1 units from %2 for %3", 
                _count, _marker, _requesterId]] call FLO_fnc_log;
            
            private _garrisonSizes = _self get "garrisonSizes";
            private _extractedCount = 0;
            
            // Check if this garrison exists in garrisonSizes
            if (!(_marker in keys _garrisonSizes)) exitWith {
                ["Garrison", 3, format["Cannot extract units from non-existent garrison at %1", _marker]] call FLO_fnc_log;
                []
            };
            
            // Get current size directly from garrisonSizes
            private _currentSize = _garrisonSizes get _marker;
            
            // Debug output for tracing issues
            ["Garrison", 4, format["Garrison data: current size: %1, requested: %2", 
                _currentSize, _count]] call FLO_fnc_log;
            
            // Validate count parameter
            if (_count <= 0) then {
                ["Garrison", 3, format["Invalid count parameter: %1", _count]] call FLO_fnc_log;
                _count = 0;
            };
            
            // Check if we can extract the requested count
            _extractedCount = _count min _currentSize;
            
            if (_extractedCount > 0) then {
                // Update garrisonSizes directly with reduced size
                _garrisonSizes set [_marker, (_currentSize - _extractedCount) max 0];
                
                ["Garrison", 3, format["Successfully extracted %1 units from garrison at %2 for %3 (reduced size to %4)",
                    _extractedCount, _marker, _requesterId, _garrisonSizes get _marker]] call FLO_fnc_log;
            };
            
            // Return the extracted count - let the task force system handle unit creation
            _extractedCount
        }],
        
        // Return units to their original garrison
        ["returnUnits", {
            params [
                ["_count", 0, [0]],
                ["_requesterId", "", [""]],
                ["_targetMarker", "", [""]]  // Optional - can specify a different target marker
            ];
            
            // Debug log for tracing issues
            ["Garrison", 4, format["Starting return of %1 units from %2 to target %3", 
                _count, _requesterId, if (_targetMarker == "") then {"original garrisons"} else {_targetMarker}]] call FLO_fnc_log;
            
            private _garrisonSizes = _self get "garrisonSizes";
            private _returnedCount = 0;
            
            // Validate count
            if (_count <= 0) exitWith {
                0
            };
            
            // Get the target marker
            private _marker = _targetMarker;
            
            // Only proceed if we have a valid marker
            if (_marker != "" && _marker in keys _garrisonSizes) then {
                // Get current size directly from garrisonSizes
                private _currentSize = _garrisonSizes get _marker;
                
                // For now we don't enforce a max size limit - just add the units
                _returnedCount = _count;
                
                if (_returnedCount > 0) then {
                    // Increase size directly in garrisonSizes
                    _garrisonSizes set [_marker, _currentSize + _returnedCount];
                    
                    ["Garrison", 3, format["Successfully returned %1 units to garrison at %2 (new size: %3)",
                        _returnedCount, _marker, _garrisonSizes get _marker]] call FLO_fnc_log;
                };
            } else {
                ["Garrison", 3, format["Cannot return units to invalid garrison: %1", _marker]] call FLO_fnc_log;
            };
            
            ["Garrison", 3, format["Returned %1 units to garrisons from requester %2",
                _returnedCount, _requesterId]] call FLO_fnc_log;
            
            _returnedCount
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
        }],

        ["_checkGarrisonStrength", {
            params ["_marker"];
            
            // Get strength from garrisonSizes only
            private _strength = 0;
            private _garrisonSizes = _self get "garrisonSizes";
            
            // Check if there's a size defined in garrisonSizes
            if (_marker in keys _garrisonSizes) then {
                _strength = _garrisonSizes get _marker;
                ["Garrison", 3, format["Checking garrison strength at %1: %2 units from garrisonSizes", 
                    _marker, _strength]] call FLO_fnc_log;
            };
            
            _strength
        }],
        
        // Check if a marker can receive more vehicles of a specific type
        ["canAddVehicle", {
            params ["_marker", "_vehicleType"];
            
            // Get the marker type
            private _markerType = markerType _marker;
            
            // Get vehicle limits for this marker type
            private _limits = _self call ["getVehicleLimits", [_markerType]];
            _limits params ["_lightMax", "_heavyMax", "_totalMax"];
            
            // Get current vehicle counts
            private _vehicleCounts = _self get "vehicleCounts";
            private _currentCounts = _vehicleCounts getOrDefault [_marker, [0, 0, 0]];
            _currentCounts params ["_currentLight", "_currentHeavy", "_currentTotal"];
            
            // Determine if this is a heavy vehicle
            private _isHeavy = (_vehicleType in East_Ground_Vehicles_Heavy);
            
            // Check if we can add this vehicle type
            private _canAdd = false;
            
            if (_isHeavy) then {
                _canAdd = (_currentHeavy < _heavyMax) && (_currentTotal < _totalMax);
            } else {
                _canAdd = (_currentLight < _lightMax) && (_currentTotal < _totalMax);
            };
            
            ["Garrison", 4, format["Vehicle check for %1: %2 (Heavy: %3). Current: [%4,%5,%6], Limits: [%7,%8,%9], Result: %10", 
                _marker, _vehicleType, _isHeavy, _currentLight, _currentHeavy, _currentTotal, _lightMax, _heavyMax, _totalMax, _canAdd]] call FLO_fnc_log;
            
            _canAdd
        }],
        
        // Add a vehicle to the count for a marker
        ["addVehicleToCount", {
            params ["_marker", "_vehicleType"];
            
            // Initialize if needed
            private _vehicleCounts = _self get "vehicleCounts";
            if (!(_marker in keys _vehicleCounts)) then {
                _vehicleCounts set [_marker, [0, 0, 0]];
            };
            
            // Get current counts
            private _currentCounts = _vehicleCounts get _marker;
            _currentCounts params ["_lightCount", "_heavyCount", "_totalCount"];
            
            // Determine if this is a heavy vehicle
            private _isHeavy = (_vehicleType in East_Ground_Vehicles_Heavy);
            
            // Update counts
            if (_isHeavy) then {
                _currentCounts set [1, _heavyCount + 1];
            } else {
                _currentCounts set [0, _lightCount + 1];
            };
            _currentCounts set [2, _totalCount + 1];
            
            // Update the hashmap
            _vehicleCounts set [_marker, _currentCounts];
            
            ["Garrison", 3, format["Added vehicle %1 to %2. New counts: %3", _vehicleType, _marker, _currentCounts]] call FLO_fnc_log;
            
            true
        }],
        
        // Remove a vehicle from the count for a marker
        ["removeVehicleFromCount", {
            params ["_marker", "_vehicleType"];
            
            // Check if marker has any vehicles tracked
            private _vehicleCounts = _self get "vehicleCounts";
            if (!(_marker in keys _vehicleCounts)) exitWith {
                ["Garrison", 3, format["No vehicles tracked for %1, nothing to remove", _marker]] call FLO_fnc_log;
                false
            };
            
            // Get current counts
            private _currentCounts = _vehicleCounts get _marker;
            _currentCounts params ["_lightCount", "_heavyCount", "_totalCount"];
            
            // Determine if this is a heavy vehicle
            private _isHeavy = (_vehicleType in East_Ground_Vehicles_Heavy);
            
            // Update counts
            if (_isHeavy) then {
                _currentCounts set [1, (_heavyCount - 1) max 0];
            } else {
                _currentCounts set [0, (_lightCount - 1) max 0];
            };
            _currentCounts set [2, (_totalCount - 1) max 0];
            
            // Update the hashmap
            _vehicleCounts set [_marker, _currentCounts];
            
            ["Garrison", 3, format["Removed vehicle %1 from %2. New counts: %3", _vehicleType, _marker, _currentCounts]] call FLO_fnc_log;
            
            true
        }]
    ];
    
    // Create the garrison manager object
    FLO_Garrison_Manager = createHashMapObject [_garrisonManagerClass];
};

FLO_Garrison_Manager 