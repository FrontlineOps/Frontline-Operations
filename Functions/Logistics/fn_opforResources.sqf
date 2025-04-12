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
if (isNil "FLO_OPFOR_Resources") then {
    // Define the resource management class with its methods and properties
    private _resourceClass = [
        // Class identifier
        ["#type", "OPFORResources"],
        // Initial resource state - start with nil to indicate no initialization
        ["resources", nil],
        ["lastUpdate", nil],
        
        // Define spending modifiers at class level for consistency
        ["spendingModifiers", createHashMapFromArray [
            // [type, [base_multiplier, resource_threshold, efficiency_loss_per_use]]
            ["garrison", [1.0, 10, 0.05]],
            ["qrf", [1.5, 100, 0.08]],    
            ["offensiveops", [4.0, 500, 0.15]],
            ["air_support", [2.0, 250, 0.12]],
            ["artillery", [3.0, 150, 0.07]]
        ]],
        
        // Constructor - Called when object is created
        ["#create", {
            params [["_initialResources", -1]];
            
            // Only set initial values if resources is nil (not yet initialized)
            if (isNil {_self get "resources"}) then {
                // Try to load saved data first
                private _missionTag = missionName;
                _missionTag = [_missionTag] call BIS_fnc_filterString;
                private _resourcesDataName = _missionTag + "_Resources";
                private _savedData = profileNamespace getVariable [_resourcesDataName, createHashMap];
                
                if (count _savedData > 0) then {
                    // Load saved values
                    private _savedResources = _savedData getOrDefault ["resources", 0];
                    _self set ["resources", _savedResources];
                    _self set ["lastUpdate", _savedData getOrDefault ["lastUpdate", time]];
                    
                    // Load efficiency values using spendingModifiers keys
                    private _spendingModifiers = _self get "spendingModifiers";
                    {
                        private _effKey = format ["efficiency_%1", _x];
                        private _efficiency = _savedData getOrDefault [_effKey, 1.0];
                        _self set [_effKey, _efficiency];
                    } forEach (keys _spendingModifiers);
                    
                    ["OPFOR Resources", 3, format["Initialized with saved data: %1 resources", _savedResources]] call FLO_fnc_log;
                } else {
                    // No saved data, use initial values
                    _self set ["resources", if (_initialResources == -1) then {0} else {_initialResources}];
                    _self set ["lastUpdate", time];
                    ["OPFOR Resources", 3, format["Initialized fresh with %1 resources", _self get "resources"]] call FLO_fnc_log;
                };
                
                // Initialize the resource generation loop
                _self call ["initResourceLoop", []];
            };
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

            private _spendingModifiers = _self get "spendingModifiers";
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
                _efficiency = (_efficiency - _efficiencyLoss) max 0.2; // Won't go below 20% efficiency
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
                private _eventCooldown = 0;
                
                while {true} do {
                    private _totalResources = 0;
                    private _activeInstallations = 0;
                    private _globalModifier = 1;
                    
                    // Random event chance (every 30-60 minutes)
                    if (time > _eventCooldown) then {
                        private _eventRoll = random 100;
                        private _eventID = "";
                        switch (true) do {
                            case (_eventRoll <= 7 && _eventRoll > 2): {
                                _globalModifier = 1.5;
                                _eventID = "STR_FLO_RESOURCES_OPTIMIZATION";
                            };
                            case (_eventRoll >= 0 && _eventRoll < 3): {
                                _globalModifier = 0.7;
                                _eventID = "STR_FLO_RESOURCES_DISRUPTION";
                            };
                        };
                        if (_eventID != "") then {
                            ["STR_FLO_WARNING_TITLE", _eventID, "warning", false] call FLO_fnc_sendNotification;
                            _eventCooldown = time + (random 1800) + 1800; // 30-60 minutes
                        };
                    };
                    
                    // Find all OPFOR installations
                    private _opforInstallations = allMapMarkers select {
                        markerColor _x in ["colorOPFOR", "ColorEAST"] && 
                        markerType _x in ["n_support", "o_support", "o_installation", "n_installation"]
                    };
                    
                    // Process each installation
                    {
                        private _markerType = markerType _x;
                        private _baseValue = _resourceValues get _markerType;
                        private _pos = getMarkerPos _x;
                        
                        // Check for nearby BLUFOR units that might contest the installation
                        private _nearbyBlufor = _pos nearEntities [["Man", "Car", "Tank", "Ship", "LandVehicle"], 500] select {side _x == west};
                        
                        // Only generate resources if installation is not contested
                        if (count _nearbyBlufor == 0) then {
                            private _finalValue = _baseValue * _globalModifier;
                            _totalResources = _totalResources + _finalValue;
                            
                            // Log significant changes from events
                            if (_globalModifier != 1) then {
                                ["OPFOR Resources", 3, format["%1 at %2 generating %3 resources (Base: %4)", 
                                    _markerType, mapGridPosition _pos, round _finalValue, _baseValue]] call FLO_fnc_log;
                            };
                        };
                    } forEach _opforInstallations;
                    
                    // Add resources
                    _totalResources = round _totalResources;
                    if (_totalResources > 0) then {
                        FLO_OPFOR_Resources call ["addResources", [_totalResources]];
                        _lastGeneratedAmount = _totalResources;
                        
                        ["OPFOR Resources", 3, format["Generated %1 resources from %2 installations", 
                            _totalResources, _activeInstallations]] call FLO_fnc_log;
                    };
                    
                    // Wait 10 minutes before next resource generation cycle
                    sleep 600;
                };
            };
        }],

        // Save resources state to profileNamespace
        ["saveResources", {
            private _missionTag = missionName;
            _missionTag = [_missionTag] call BIS_fnc_filterString;
            private _resourcesDataName = _missionTag + "_Resources";
            
            private _resourcesDataHash = createHashMap;
            
            // Save core resource data
            _resourcesDataHash set ["resources", _self call ["getResources", []]];
            _resourcesDataHash set ["lastUpdate", _self get "lastUpdate"];
            
            // Save efficiency data using spendingModifiers keys
            private _spendingModifiers = _self get "spendingModifiers";
            {
                private _effKey = format ["efficiency_%1", _x];
                private _efficiency = _self getOrDefault [_effKey, 1.0];
                _resourcesDataHash set [_effKey, _efficiency];
            } forEach (keys _spendingModifiers);
            
            // Save to profileNamespace
            profileNamespace setVariable [_resourcesDataName, _resourcesDataHash];
            
            ["OPFOR Resources", 3, format["Saved resource state with %1 resources", _self call ["getResources", []]]] call FLO_fnc_log;
            true
        }],
        
        // Load resources state from profileNamespace
        ["loadResources", {
            private _missionTag = missionName;
            _missionTag = [_missionTag] call BIS_fnc_filterString;
            private _resourcesDataName = _missionTag + "_Resources";
            
            private _resourcesData = profileNamespace getVariable [_resourcesDataName, createHashMap];
            
            if (count _resourcesData > 0) then {
                // Load saved values
                private _savedResources = _resourcesData getOrDefault ["resources", 0];
                _self set ["resources", _savedResources];
                _self set ["lastUpdate", _resourcesData getOrDefault ["lastUpdate", time]];
                
                // Load efficiency values using spendingModifiers keys
                private _spendingModifiers = _self get "spendingModifiers";
                {
                    private _effKey = format ["efficiency_%1", _x];
                    private _efficiency = _resourcesData getOrDefault [_effKey, 1.0];
                    _self set [_effKey, _efficiency];
                } forEach (keys _spendingModifiers);
                
                ["OPFOR Resources", 3, format["Loaded resource state with %1 resources", _savedResources]] call FLO_fnc_log;
                true
            } else {
                ["OPFOR Resources", 2, "No saved resource state found"] call FLO_fnc_log;
                false
            }
        }]
    ];
    
    // Create the resource management object with initial resources of 0
    FLO_OPFOR_Resources = createHashMapObject [_resourceClass, 0];
};