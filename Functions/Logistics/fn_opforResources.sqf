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
        Nothing
    
    Returns:
        Nothing
*/

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
            params ["_amount", "_type"];
            private _current = _self get "resources";
            private _currentTime = time;

            // Define spending categories with strategic modifiers
            private _spendingModifiers = createHashMapFromArray [
                // [type, [base_multiplier, resource_threshold, efficiency_loss_per_use]]
                ["garrison", [1.0, 10, 0.05]],         // Garrison
                ["qrf", [1.5, 100, 0.08]],               // QRF
                ["offensiveops", [4.0, 500, 0.15]],     // Major operations 
                ["air_support", [2.0, 250, 0.12]],       // Air support
                ["artillery", [3.0, 150, 0.07]]          // Artillery
            ];

            private _typeData = _spendingModifiers getOrDefault [_type, [1.0, 30, 0.05]];
            _typeData params ["_multiplier", "_resourceThreshold", "_efficiencyLoss"];

            // Check if we have enough resources to maintain operational effectiveness
            if (_current < _resourceThreshold) exitWith {
                ["OPFOR Resources", 3, format ["Insufficient strategic resources for %1 (need %2, have %3)", 
                    _type, _resourceThreshold, _current]] call FLO_fnc_log;
                false
            };

            // Calculate final cost with strategic considerations
            private _finalCost = _amount * _multiplier;

            // Get current efficiency for this type
            private _efficiency = _self getOrDefault [format ["efficiency_%1", _type], 1.0];
            
            // Apply efficiency modifier
            _finalCost = _finalCost * (1 / _efficiency);

            if (_current >= _finalCost) then {
                private _new = _current - _finalCost;
                _self set ["resources", _new];
                _self set ["lastUpdate", _currentTime];
                
                // Reduce efficiency for this type of operation
                _efficiency = (_efficiency - _efficiencyLoss) max 0.4; // Won't go below 40% efficiency
                _self set [format ["efficiency_%1", _type], _efficiency];

                // If resources are abundant, slowly recover efficiency
                if (_new > (_resourceThreshold * 2)) then {
                    {
                        private _currentEff = _self getOrDefault [format ["efficiency_%1", _x], 1.0];
                        _self set [format ["efficiency_%1", _x], (_currentEff + 0.02) min 1.0];
                    } forEach (keys _spendingModifiers);
                };

                true
            } else {
                ["OPFOR Resources", 3, format ["Cannot afford %1 operation (cost: %2, available: %3)", 
                    _type, _finalCost, _current]] call FLO_fnc_log;
                false
            }
        }],
        
        // Initialize the resource generation loop
        // This runs continuously in the background
        ["initResourceLoop", {
            // Define resource values with diminishing returns
            private _resourceValues = createHashMapFromArray [
                ["o_installation", 7],    // Military Outpost
                ["n_support", 5],         // Military Service Post
                ["o_support", 3],         // Military Road Post
                ["n_installation", 15]    // Military Headquarters
            ];

            // Spawn continuous resource generation loop
            [_resourceValues] spawn {
                params ["_resourceValues"];
                private _lastGeneratedAmount = 0;
                
                while {true} do {
                    private _totalResources = 0;
                    private _activeInstallations = 0;
                    
                    // Find all OPFOR installations
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
                            _activeInstallations = _activeInstallations + 1;
                            // Apply diminishing returns based on number of active installations
                            _totalResources = _totalResources + (_baseValue * (1 - (_activeInstallations * 0.1)));
                        };
                    } forEach _opforInstallations;
                    
                    // Add resources
                    _totalResources = round _totalResources;
                    FLO_OPFOR_Resources call ["addResources", [_totalResources]];
                    _lastGeneratedAmount = _totalResources;
                    
                    // Wait 10 minutes before next resource generation cycle
                    sleep 600;
                };
            };
        }]
    ];
    
    // Create the resource management object with initial resources of 0
    FLO_OPFOR_Resources = createHashMapObject [_resourceClass, 0];
};