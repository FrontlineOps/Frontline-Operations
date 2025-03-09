/*
    Function: FLO_fnc_logisticsNetwork
    
    Description:
    Manages the logistics network that distributes supplies to frontline outposts.
    Uses resource system to allocate supplies, which boosts garrison strength over time.
    
    Parameters:
    _mode - The function mode to execute ["init", "update", "calculateRoute", "getSupplyLevel"] (String)
    _params - Parameters based on mode (Array)
        init: [] - Initialize the logistics network
        update: [] - Force an update of all supply routes
        calculateRoute: [_sourceMarker, _targetMarker] - Calculate and establish a supply route
        getSupplyLevel: [_marker] - Get current supply level for a marker
    
    Returns:
    Based on mode:
        init: HashMapObject - The logistics network object
        update: Nothing
        calculateRoute: Boolean - Success of route creation
        getSupplyLevel: Number - Current supply level (0-100)
*/

if (!isServer) exitWith {};

params [
    ["_mode", "", [""]],
    ["_params", [], [[]]]
];

private _result = false;

// Initialize the Logistics Network object if it doesn't exist
if (isNil "FLO_Logistics_Network") then {
    // Define the Logistics Network class with its methods and properties
    private _logisticsNetworkClass = [
        // Class identifier
        ["#type", "LogisticsNetwork"],
        
        // Properties
        ["supplyRoutes", createHashMap],
        ["supplyLevels", createHashMap],
        ["lastUpdate", time],
        
        // Constructor - Called when object is created
        ["#create", {
            _self set ["supplyRoutes", createHashMap];
            _self set ["supplyLevels", createHashMap];
            _self set ["lastUpdate", time];
            diag_log "[FLO][Logistics] Network initialized";
        }],
        
        // Initialize logistics network and start update loop
        ["initialize", {
            // Start the update loop
            [] spawn {
                while {true} do {
                    // Update supply levels every 5 minutes
                    ["update", []] call FLO_fnc_logisticsNetwork;
                    sleep 300;
                };
            };
        }],
        
        // Calculate and establish a supply route between two markers
        ["calculateSupplyRoute", {
            params ["_sourceMarker", "_targetMarker"];
            
            if (_sourceMarker == "" || _targetMarker == "") exitWith {
                diag_log "[FLO][Logistics] Error: Empty marker name for supply route";
                false
            };
            
            private _sourcePos = getMarkerPos _sourceMarker;
            private _targetPos = getMarkerPos _targetMarker;
            
            if (_sourcePos isEqualTo [0,0,0] || _targetPos isEqualTo [0,0,0]) exitWith {
                diag_log format ["[FLO][Logistics] Error: Invalid marker position for route %1 -> %2", _sourceMarker, _targetMarker];
                false
            };
            
            // Calculate distance
            private _distance = _sourcePos distance _targetPos;
            
            // Calculate route quality based on distance and road connections
            private _routeQuality = 0;
            
            // Better quality for shorter distances
            if (_distance < 1000) then {
                _routeQuality = 0.9;
            } else {
                if (_distance < 3000) then {
                    _routeQuality = 0.75;
                } else {
                    if (_distance < 5000) then {
                        _routeQuality = 0.5;
                    } else {
                        _routeQuality = 0.3;
                    };
                };
            };
            
            // Check for road connections to improve route quality
            private _roads = _sourcePos nearRoads 200;
            private _targetRoads = _targetPos nearRoads 200;
            
            if (count _roads > 0 && count _targetRoads > 0) then {
                _routeQuality = _routeQuality min 0.95;
            };
            
            // Store the route
            private _supplyRoutes = _self get "supplyRoutes";
            _supplyRoutes set [_targetMarker, [_sourceMarker, _routeQuality, _distance, time]];
            
            // Initialize supply level if not exist
            private _supplyLevels = _self get "supplyLevels";
            if (!(_targetMarker in keys _supplyLevels)) then {
                _supplyLevels set [_targetMarker, 0];
            };
            
            diag_log format ["[FLO][Logistics] Supply route established: %1 -> %2 (Quality: %3)", _sourceMarker, _targetMarker, _routeQuality];
            true
        }],
        
        // Get all valid supply depots (typically headquarters or larger outposts)
        ["getSupplyDepots", {
            private _depots = [];
            
            // Find all OPFOR headquarters and outposts that can serve as supply depots
            private _opforInstallations = allMapMarkers select {
                markerColor _x in ["colorOPFOR", "ColorEAST"] && 
                markerType _x in ["n_support", "o_installation", "n_installation"]
            };
            
            // Check each installation if it's a valid supply depot
            {
                private _marker = _x;
                private _pos = getMarkerPos _marker;
                
                // Must not be under attack or contested
                private _nearbyUnits = _pos nearEntities [["Man", "Car", "Tank"], 500];
                private _isContested = false;
                
                {
                    if (side _x == west) exitWith {
                        _isContested = true;
                    };
                } forEach _nearbyUnits;
                
                if (!_isContested) then {
                    _depots pushBack _marker;
                };
            } forEach _opforInstallations;
            
            diag_log format ["[FLO][Logistics] Found %1 valid supply depots", count _depots];
            _depots
        }],
        
        // Get all frontline outposts that need supplies
        ["getFrontlineOutposts", {
            private _outposts = [];
            private _priorityOutposts = []; // High priority outposts (o_support and n_support)
            private _secondaryOutposts = []; // Secondary priority outposts
            
            // Find all OPFOR positions that can receive supplies
            private _opforPositions = allMapMarkers select {
                markerColor _x in ["colorOPFOR", "ColorEAST"] && 
                markerType _x in ["o_support", "n_support", "o_installation", "n_installation", 
                                  "loc_Power", "o_recon", "o_service", "o_antiair", "loc_Ruin"]
            };
            
            // Check for frontline positions
            {
                private _marker = _x;
                private _pos = getMarkerPos _marker;
                
                // Check for nearby BLUFOR areas to determine if it's frontline
                private _nearbyMarkers = allMapMarkers select {
                    markerColor _x in ["colorBLUFOR", "ColorWEST", "ColorYellow"] && 
                    (getMarkerPos _x) distance _pos < 3000
                };
                
                if (count _nearbyMarkers > 0) then {
                    // Sort outposts by priority
                    private _markerType = markerType _marker;
                    if (_markerType in ["o_support", "n_support"]) then {
                        _priorityOutposts pushBack _marker;
                    } else {
                        _secondaryOutposts pushBack _marker;
                    };
                };
            } forEach _opforPositions;
            
            // Combine lists with priority outposts first
            _outposts = _priorityOutposts + _secondaryOutposts;
            
            diag_log format ["[FLO][Logistics] Found %1 outposts (%2 high priority) that need supplies", 
                count _outposts, count _priorityOutposts];
            
            _outposts
        }],
        
        // Update all supply routes and levels
        ["updateSupplyNetwork", {
            private _supplyRoutes = _self get "supplyRoutes";
            private _supplyLevels = _self get "supplyLevels";
            
            // Get all valid supply depots and frontline outposts
            private _depots = _self call ["getSupplyDepots", []];
            private _outposts = _self call ["getFrontlineOutposts", []];
            
            // Create or update routes for outposts that don't have one
            {
                private _outpost = _x;
                
                // Skip if already has a route
                if (_outpost in keys _supplyRoutes) then {
                    // Update existing route
                    private _routeData = _supplyRoutes get _outpost;
                    _routeData params ["_source", "_quality", "_distance", "_timestamp"];
                    
                    // Check if source is still valid
                    if (!(_source in _depots)) then {
                        // Need to find a new source
                        _supplyRoutes deleteAt _outpost;
                        
                        // Find closest valid depot
                        private _outpostPos = getMarkerPos _outpost;
                        private _closestDepot = "";
                        private _closestDistance = 999999;
                        
                        {
                            private _depotPos = getMarkerPos _x;
                            private _dist = _outpostPos distance _depotPos;
                            
                            if (_dist < _closestDistance) then {
                                _closestDepot = _x;
                                _closestDistance = _dist;
                            };
                        } forEach _depots;
                        
                        if (_closestDepot != "") then {
                            _self call ["calculateSupplyRoute", [_closestDepot, _outpost]];
                        };
                    };
                } else {
                    // No route, create new one
                    // Find closest depot
                    private _outpostPos = getMarkerPos _outpost;
                    private _closestDepot = "";
                    private _closestDistance = 999999;
                    
                    {
                        private _depotPos = getMarkerPos _x;
                        private _dist = _outpostPos distance _depotPos;
                        
                        if (_dist < _closestDistance) then {
                            _closestDepot = _x;
                            _closestDistance = _dist;
                        };
                    } forEach _depots;
                    
                    if (_closestDepot != "") then {
                        _self call ["calculateSupplyRoute", [_closestDepot, _outpost]];
                    };
                };
            } forEach _outposts;
            
            // Calculate supply distribution based on resource availability
            private _availableResources = ["get", []] call FLO_fnc_opforResources;
            private _routeCount = count _supplyRoutes;
            
            if (_routeCount > 0 && _availableResources > 0) then {
                // Calculate base resource allocation per route
                private _baseAllocation = (_availableResources / 3) / _routeCount; // Use 1/3 of resources for logistics
                private _resourcesUsed = 0;
                
                // Process each route
                {
                    private _target = _x;
                    private _routeData = _supplyRoutes get _target;
                    _routeData params ["_source", "_quality", "_distance", "_timestamp"];
                    
                    // Calculate supply delivery based on quality and distance
                    private _supplyAmount = _baseAllocation * _quality;
                    
                    // Priority multiplier for o_support and n_support
                    private _markerType = markerType _target;
                    if (_markerType in ["o_support", "n_support"]) then {
                        _supplyAmount = _supplyAmount * 1.5; // 50% more supplies for priority outposts
                    };
                    
                    // Longer routes are more expensive
                    if (_distance > 3000) then {
                        _supplyAmount = _supplyAmount * 0.7;
                    };
                    
                    // Apply supply to target
                    private _currentSupply = _supplyLevels getOrDefault [_target, 0];
                    private _newSupply = (_currentSupply + _supplyAmount) min 100;
                    _supplyLevels set [_target, _newSupply];
                    
                    // Adjust resource usage
                    _resourcesUsed = _resourcesUsed + _supplyAmount;
                    
                    // Determine reinforcement threshold based on marker type
                    private _reinforcementThreshold = 80;
                    if (_markerType in ["o_support", "n_support"]) then {
                        _reinforcementThreshold = 70; // Lower threshold for priority outposts
                    };
                    
                    // If supply level high enough, reinforce garrison
                    if (_newSupply >= _reinforcementThreshold) then {
                        // Spend supply to reinforce
                        _supplyLevels set [_target, _newSupply - 40]; // Reduce supply level after reinforcing
                        
                        // Add some units to garrison based on outpost size and type
                        private _markerSize = getMarkerSize _target;
                        private _size = (_markerSize select 0) max (_markerSize select 1);
                        private _reinforceAmount = round (_size / 50) max 2;
                        
                        // Bonus reinforcements for priority outposts
                        if (_markerType in ["o_support", "n_support"]) then {
                            _reinforceAmount = _reinforceAmount + 2;
                        };
                        
                        // Call garrison reinforce function
                        ["reinforce", [_target, _reinforceAmount]] call FLO_fnc_garrisonManager;
                        
                        diag_log format ["[FLO][Logistics] Reinforcing %1 with %2 units (priority: %3)", 
                            _target, _reinforceAmount, _markerType in ["o_support", "n_support"]];
                    };
                } forEach keys _supplyRoutes;
                
                // Spend the resources used
                ["spend", [round _resourcesUsed]] call FLO_fnc_opforResources;
            };
            
            // Clean up any invalid routes
            private _toDelete = [];
            {
                private _target = _x;
                
                // Check if target marker still exists
                if (getMarkerPos _target isEqualTo [0,0,0]) then {
                    _toDelete pushBack _target;
                    continue;
                };
                
                // Check if the marker changed sides (captured by BLUFOR)
                if (markerColor _target in ["colorBLUFOR", "ColorWEST"]) then {
                    _toDelete pushBack _target;
                    diag_log format ["[FLO][Logistics] Route removed - target %1 was captured by BLUFOR", _target];
                };
            } forEach keys _supplyRoutes;
            
            {
                _supplyRoutes deleteAt _x;
                _supplyLevels deleteAt _x;
            } forEach _toDelete;
            
            // Update timestamp
            _self set ["lastUpdate", time];
            
            // Log detailed statistics
            if (count keys _supplyRoutes > 0) then {
                // Count routes by target marker type
                private _routesByType = createHashMap;
                {
                    private _targetMarker = _x;
                    private _targetType = markerType _targetMarker;
                    
                    private _count = _routesByType getOrDefault [_targetType, 0];
                    _routesByType set [_targetType, _count + 1];
                } forEach keys _supplyRoutes;
                
                // Build log message
                private _logDetails = "";
                {
                    private _type = _x;
                    private _count = _routesByType get _type;
                    _logDetails = _logDetails + format ["%1: %2, ", _type, _count];
                } forEach keys _routesByType;
                
                // Remove trailing comma and space if needed
                if (_logDetails != "") then {
                    _logDetails = _logDetails select [0, count _logDetails - 2];
                };
                
                diag_log format ["[FLO][Logistics] Supply network updated. %1 active routes. By type: %2", 
                    count keys _supplyRoutes, _logDetails];
            } else {
                diag_log "[FLO][Logistics] Supply network updated. No active routes.";
            };
        }],
        
        // Get supply level for a marker
        ["getMarkerSupplyLevel", {
            params ["_marker"];
            
            private _supplyLevels = _self get "supplyLevels";
            _supplyLevels getOrDefault [_marker, 0]
        }]
    ];
    
    // Create the logistics network object
    FLO_Logistics_Network = createHashMapObject [_logisticsNetworkClass];
};

// Execute the requested mode
switch (_mode) do {
    // Initialize the logistics network
    case "init": {
        FLO_Logistics_Network call ["initialize", []];
        _result = FLO_Logistics_Network;
    };
    
    // Force an update of all supply routes
    case "update": {
        FLO_Logistics_Network call ["updateSupplyNetwork", []]
    };
    
    // Calculate and establish a supply route
    case "calculateRoute": {
        _params params [
            ["_sourceMarker", "", [""]],
            ["_targetMarker", "", [""]]
        ];
        
        _result = FLO_Logistics_Network call ["calculateSupplyRoute", [_sourceMarker, _targetMarker]]
    };
    
    // Get current supply level for a marker
    case "getSupplyLevel": {
        _params params [
            ["_marker", "", [""]]
        ];
        
        _result = FLO_Logistics_Network call ["getMarkerSupplyLevel", [_marker]]
    };
};

_result 