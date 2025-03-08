/*
    Function: FLO_fnc_opforResources
    
    Description:
    Manages resource generation for OPFOR installations.
    Similar to Antistasi's resource system but adapted for FLO.
    
    Resources are generated from:
    - Military Service Posts (n_support): 5 resources
    - Military Road Posts (o_support): 3 resources
    - Military Outpost (o_installation): 7 resources
    - Military Headquarters (n_installation): 15 resources
    
    Parameter(s):
    _mode - The function mode to execute ["init", "get", "add", "spend"] (String)
    _params - Parameters based on mode (Array)
        init: [] - No parameters needed
        get: [] - No parameters needed
        add: [_amount] - Amount to add
        spend: [_amount] - Amount to spend
    
    Returns:
    Based on mode:
        init: Nothing
        get: Number - Current resources
        add: Number - New resource total
        spend: Boolean - True if successfully spent, false if insufficient resources
*/

params [
    ["_mode", "init", [""]],
    ["_params", [], [[]]]
];

// Only execute on server to prevent multiple resource systems running
if (!isServer) exitWith {};

// Initialize OPFOR resources object if it doesn't exist
// This uses HashMapObject for OOP-style resource management
if (isNil "FLO_OPFOR_Resources") then {
    // Define the resource management class with its methods and properties
    private _resourceClass = [
        // Class identifier
        ["#type", "OPFORResources"],
        // Initial resource state
        ["resources", 0],
        ["lastUpdate", time],
        
        // Constructor - Called when object is created
        ["#create", {
            params ["_initialResources"];
            _self set ["resources", _initialResources];
            _self set ["lastUpdate", time];
        }],
        
        // Get current resource amount
        ["getResources", {
            _self get "resources"
        }],
        
        // Add resources and update timestamp
        ["addResources", {
            params ["_amount"];
            private _current = _self get "resources";
            private _new = _current + _amount;
            _self set ["resources", _new];
            _self set ["lastUpdate", time];
            _new
        }],
        
        // Attempt to spend resources
        // Returns true if successful, false if insufficient resources
        ["spendResources", {
            params ["_amount"];
            private _current = _self get "resources";
            if (_current >= _amount) then {
                private _new = _current - _amount;
                _self set ["resources", _new];
                _self set ["lastUpdate", time];
                true
            } else {
                diag_log format ["[FLO][Resources] Failed to spend %1 resources (current: %2)", _amount, _current];
                false
            }
        }],
        
        // Initialize the resource generation loop
        // This runs continuously in the background
        ["initResourceLoop", {
            // Define resource values for different installation types
            private _resourceValues = createHashMapFromArray [
                ["o_installation", 7],    // Military Outpost
                ["n_support", 5],         // Military Service Post
                ["o_support", 3],         // Military Road Post
                ["n_installation", 15]    // Military Headquarters
            ];

            // Spawn continuous resource generation loop
            [_resourceValues] spawn {
                params ["_resourceValues"];
                
                while {true} do {
                    private _totalResources = 0;
                    
                    // Find all OPFOR installations on the map
                    private _opforInstallations = allMapMarkers select {
                        markerColor _x in ["colorOPFOR", "ColorEAST"] && 
                        markerType _x in ["n_support", "o_support", "o_installation", "n_installation"]
                    };
                    
                    // Process each installation
                    {
                        private _markerType = markerType _x;
                        private _baseValue = _resourceValues getOrDefault [_markerType, 0];
                        private _pos = getMarkerPos _x;
                        
                        // Check for nearby units that might contest the installation
                        private _nearbyUnits = _pos nearEntities [["Man", "Car", "Tank", "Ship", "LandVehicle"], 500];
                        private _isContested = false;
                        
                        // Check if any BLUFOR units are nearby
                        {
                            if (side _x == west) exitWith {
                                _isContested = true;
                            };
                        } forEach _nearbyUnits;
                        
                        // Only generate resources if installation is not contested
                        if (!_isContested) then {
                            _totalResources = _totalResources + _baseValue;
                        };
                    } forEach _opforInstallations;
                    
                    // Add accumulated resources to the system
                    FLO_OPFOR_Resources call ["addResources", [_totalResources]];
                    
                    // Wait 10 minutes before next resource generation cycle
                    sleep 600;
                };
            };
        }]
    ];
    
    // Create the resource management object with initial resources of 0
    FLO_OPFOR_Resources = createHashMapObject [_resourceClass, 0];
};

// Handle different operation modes
private _result = switch (_mode) do {
    // Initialize the resource system and start generation loop
    case "init": {
        _self = FLO_OPFOR_Resources;
        _self call ["initResourceLoop", []];
        0
    };
    
    // Get current resource amount
    case "get": {
        _self = FLO_OPFOR_Resources;
        _self call ["getResources", []]
    };
    
    // Add resources to the system
    case "add": {
        _params params [["_amount", 0, [0]]];
        _self = FLO_OPFOR_Resources;
        _self call ["addResources", [_amount]]
    };
    
    // Attempt to spend resources
    case "spend": {
        _params params [["_amount", 0, [0]]];
        _self = FLO_OPFOR_Resources;
        _self call ["spendResources", [_amount]]
    };
};

_result 