/*
 * Function: FLO_fnc_taskForceGarrisonIntegration
 * Author: Azraeelian Angel
 * Description:
 * Integrates the Task Force system with the Garrison system, allowing task forces
 * to draw units from outpost garrisons rather than from the logistics system.
 * Also allows outposts to accept any unit type for garrison use in task forces.
 *
 * This function initializes and returns the Task Force Garrison Integration system object.
 * All functionality is accessed through direct method calls on the returned object.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <HASHMAP> - The integration system object with methods:
 * - _pullUnitsFromGarrison: Pull units from a garrison for a task force
 * - _returnUnitsToGarrison: Return units to a garrison from a task force
 * - _addUnitsToGarrison: Add new units to a garrison
 * - Plus analysis and utility methods
 *
 * Example:
 * _integrationSystem = call FLO_fnc_taskForceGarrisonIntegration;
 * _units = _integrationSystem call ["_pullUnitsFromGarrison", ["marker_outpost_1", ["O_Soldier_F", "O_Soldier_GL_F"], 5, "TF_123"]];
 */

if (!isServer) exitWith {};

// Initialize the integration system if it doesn't exist
if (isNil "FLO_TaskForce_Garrison_Integration") then {
    ["AI Commander", 3, "Initializing Task Force Garrison Integration System"] call FLO_fnc_log;
    
    private _integrationSystem = createHashMapObject [[
        // Properties
        ["_taskForceSourceMap", createHashMap], // Maps task force IDs to their source outposts
        ["_garrisonContributions", createHashMap], // Tracks how many units each garrison has contributed
        ["_unitCapabilities", createHashMap], // Maps unit types to their capabilities
        
        // Methods
        ["_initUnitCapabilities", {
            private _capMap = _self get "_unitCapabilities";
            
            // More dynamic unit capability analysis - unit types and their capabilities
            {
                private _type = _x;
                
                // Create a new unit to analyze its capabilities
                private _dummyGroup = createGroup [east, true];
                private _unit = _dummyGroup createUnit [_type, [0,0,0], [], 0, "NONE"];
                _unit allowDamage false;
                
                // Analyze weapons and ammo
                private _weaponCapabilities = createHashMap;
                private _hasAT = false;
                private _hasAA = false;
                private _hasGrenade = false;
                private _hasAutorifle = false;
                private _hasSniperRifle = false;
                private _hasHMG = false;
                
                // Check primary weapon capabilities
                private _primaryWeapon = primaryWeapon _unit;
                if (_primaryWeapon != "") then {
                    private _weaponType = getText (configFile >> "CfgWeapons" >> _primaryWeapon >> "baseWeapon");
                    
                    // Get weapon characteristics
                    private _minRange = getNumber (configFile >> "CfgWeapons" >> _primaryWeapon >> "minRange");
                    private _midRange = getNumber (configFile >> "CfgWeapons" >> _primaryWeapon >> "midRange");
                    private _maxRange = getNumber (configFile >> "CfgWeapons" >> _primaryWeapon >> "maxRange");
                    
                    // Default if not specified
                    if (_minRange == 0) then { _minRange = 5 };
                    if (_midRange == 0) then { _midRange = 150 };
                    if (_maxRange == 0) then { _maxRange = 500 };
                    
                    // Categorize weapon
                    private _weaponCat = "standard";
                    
                    // Check weapon class to categorize
                    switch (true) do {
                        // Machine guns
                        case (_primaryWeapon find "LMG" > -1 || 
                              _primaryWeapon find "_MG" > -1 || 
                              _primaryWeapon find "MMG" > -1): {
                            _weaponCat = "autorifle";
                            _hasAutorifle = true;
                            _maxRange = _maxRange max 800;
                        };
                        
                        // Sniper rifles
                        case (_primaryWeapon find "_DMR" > -1 || 
                              _primaryWeapon find "srifle" > -1): {
                            _weaponCat = "marksman";
                            _hasSniperRifle = true;
                            _maxRange = _maxRange max 1000;
                        };
                        
                        // Heavy machine guns
                        case (_primaryWeapon find "HMG" > -1): {
                            _weaponCat = "hmg";
                            _hasHMG = true;
                            _maxRange = _maxRange max 1200;
                        };
                    };
                    
                    _weaponCapabilities set ["primary", [_weaponCat, _minRange, _midRange, _maxRange]];
                };
                
                // Check secondary weapons (launchers)
                private _secondaryWeapon = secondaryWeapon _unit;
                if (_secondaryWeapon != "") then {
                    private _ammoType = "";
                    private _mags = getArray (configFile >> "CfgWeapons" >> _secondaryWeapon >> "magazines");
                    
                    if (count _mags > 0) then {
                        private _ammo = getText (configFile >> "CfgMagazines" >> (_mags select 0) >> "ammo");
                        _ammoType = _ammo;
                    };
                    
                    // Determine if AT or AA
                    switch (true) do {
                        case (_secondaryWeapon find "_AT_" > -1 || 
                              _ammoType find "_AT_" > -1 || 
                              _secondaryWeapon find "LAT" > -1 || 
                              _secondaryWeapon find "launcher" > -1): {
                            _hasAT = true;
                        };
                        
                        case (_secondaryWeapon find "_AA_" > -1 || 
                              _ammoType find "_AA_" > -1): {
                            _hasAA = true;
                        };
                    };
                    
                    private _launcherMaxRange = getNumber (configFile >> "CfgWeapons" >> _secondaryWeapon >> "maxRange");
                    if (_launcherMaxRange == 0) then { _launcherMaxRange = 300 }; // Default
                    
                    _weaponCapabilities set ["secondary", [
                        [_hasAT, _hasAA], 
                        50,  // min range
                        150, // mid range
                        _launcherMaxRange
                    ]];
                };
                
                // Check for grenades
                {
                    if (_x find "HandGrenade" > -1) then {
                        _hasGrenade = true;
                    };
                } forEach (magazines _unit);
                
                // Set unit role based on capabilities and special equipment
                private _category = "infantry";
                private _role = "basic";
                
                // Specific unit role checks
                switch (true) do {
                    case (_type find "_TL_" > -1): { _role = "leader" };
                    case (_type find "_SL_" > -1): { _role = "leader" };
                    case (_type find "_medic_" > -1): { _role = "medic" };
                    case (_type find "_engineer_" > -1): { _role = "engineer" };
                    case (_type find "_exp_" > -1): { _role = "demo" };
                    case (_hasAA): { _role = "aa" };
                    case (_hasAT): { _role = "at" };
                    case (_hasHMG): { _role = "hmg" };
                    case (_hasSniperRifle): { _role = "marksman" };
                    case (_hasAutorifle): { _role = "autorifle" };
                    case (_hasGrenade && _type find "_GL_" > -1): { _role = "grenadier" };
                    default { _role = "basic" };
                };
                
                // Add detailed capabilities to the unit type
                _capMap set [_type, [
                    _category, 
                    _role, 
                    _weaponCapabilities
                ]];
                
                // Clean up
                deleteVehicle _unit;
                deleteGroup _dummyGroup;
                
            } forEach (East_Units + East_Units_Officers);
            
            // Vehicle capabilities - more simplified but could be enhanced
            // Using a different approach for vehicles since creating dummy vehicles is expensive
            
            // Light vehicles
            {
                private _armor = getNumber (configFile >> "CfgVehicles" >> _x >> "armor");
                private _armorStructural = getNumber (configFile >> "CfgVehicles" >> _x >> "armorStructural");
                private _maxSpeed = getNumber (configFile >> "CfgVehicles" >> _x >> "maxSpeed");
                private _weapons = getArray (configFile >> "CfgVehicles" >> _x >> "weapons");
                
                private _isArmed = count (_weapons - ["TruckHorn", "CarHorn"]) > 0;
                private _subRole = if (_isArmed) then {"armed"} else {"transport"};
                
                _capMap set [_x, [
                    "vehicle", 
                    _subRole, 
                    createHashMapFromArray [
                        ["armor", _armor],
                        ["armorStructural", _armorStructural],
                        ["maxSpeed", _maxSpeed],
                        ["isArmed", _isArmed]
                    ]
                ]];
            } forEach (East_Ground_Vehicles_Ambient + East_Ground_Vehicles_Light + East_Ground_Transport);
            
            // APCs and tanks
            {
                private _armor = getNumber (configFile >> "CfgVehicles" >> _x >> "armor");
                private _armorStructural = getNumber (configFile >> "CfgVehicles" >> _x >> "armorStructural");
                private _maxSpeed = getNumber (configFile >> "CfgVehicles" >> _x >> "maxSpeed");
                private _weapons = getArray (configFile >> "CfgVehicles" >> _x >> "weapons");
                
                private _subRole = if (_x find "APC" > -1) then {"apc"} else {"tank"};
                
                _capMap set [_x, [
                    "vehicle", 
                    _subRole, 
                    createHashMapFromArray [
                        ["armor", _armor],
                        ["armorStructural", _armorStructural],
                        ["maxSpeed", _maxSpeed],
                        ["weapons", _weapons]
                    ]
                ]];
            } forEach East_Ground_Vehicles_Heavy;
            
            // Air assets
            {
                private _armor = getNumber (configFile >> "CfgVehicles" >> _x >> "armor");
                private _maxSpeed = getNumber (configFile >> "CfgVehicles" >> _x >> "maxSpeed");
                private _weapons = getArray (configFile >> "CfgVehicles" >> _x >> "weapons");
                
                private _isArmed = count (_weapons - ["CMFlareLauncher"]) > 0;
                private _subRole = if (_isArmed) then {
                    if (_x find "Attack" > -1) then {"attack"} else {"armed"}
                } else {"transport"};
                
                _capMap set [_x, [
                    "air", 
                    _subRole, 
                    createHashMapFromArray [
                        ["armor", _armor],
                        ["maxSpeed", _maxSpeed],
                        ["isArmed", _isArmed]
                    ]
                ]];
            } forEach (East_Air_Transport + East_Air_Heli + East_Air_Jet);
        }],
        
        ["_getUnitTypeCategory", {
            params ["_unitType"];
            private _capabilities = (_self get "_unitCapabilities") getOrDefault [_unitType, ["unknown", "unknown"]];
            _capabilities # 0
        }],
        
        ["_getUnitTypeRole", {
            params ["_unitType"];
            private _capabilities = (_self get "_unitCapabilities") getOrDefault [_unitType, ["unknown", "unknown"]];
            _capabilities # 1
        }],
        
        // New method to get detailed weapons capabilities
        ["_getUnitWeaponCapabilities", {
            params ["_unitType"];
            private _capabilities = (_self get "_unitCapabilities") getOrDefault [_unitType, ["unknown", "unknown", createHashMap]];
            if (count _capabilities > 2) then {
                _capabilities # 2
            } else {
                createHashMap // Return empty hashmap if not available
            }
        }],
        
        // New method to get effective range of a unit
        ["_getUnitEffectiveRange", {
            params ["_unitType"];
            private _weaponCaps = _self call ["_getUnitWeaponCapabilities", [_unitType]];
            
            private _maxRange = 0;
            
            // Check primary weapon
            if ("primary" in _weaponCaps) then {
                private _primaryData = _weaponCaps get "primary";
                if (count _primaryData >= 4) then {
                    _maxRange = _primaryData # 3; // Max range from primary weapon
                };
            };
            
            // Check secondary weapon (launchers often have longer range)
            if ("secondary" in _weaponCaps) then {
                private _secondaryData = _weaponCaps get "secondary";
                if (count _secondaryData >= 4) then {
                    _maxRange = _maxRange max (_secondaryData # 3);
                };
            };
            
            // Default range if nothing found
            if (_maxRange == 0) then {
                private _role = _self call ["_getUnitTypeRole", [_unitType]];
                switch (_role) do {
                    case "marksman": { _maxRange = 800 };
                    case "at": { _maxRange = 500 };
                    case "aa": { _maxRange = 1000 };
                    case "hmg": { _maxRange = 1000 };
                    case "autorifle": { _maxRange = 600 };
                    default { _maxRange = 300 };
                };
            };
            
            _maxRange
        }],
        
        // New method to determine if a unit is effective against a specific target type
        ["_isUnitEffectiveAgainst", {
            params [ "_unitType", "_targetType"];
            
            private _role = _self call ["_getUnitTypeRole", [_unitType]];
            private _weaponCaps = _self call ["_getUnitWeaponCapabilities", [_unitType]];
            
            private _isEffective = false;
            
            switch (_targetType) do {
                case "infantry": {
                    // Most units are effective against infantry
                    _isEffective = true;
                };
                
                case "vehicle": {
                    // AT units, heavy weapons are effective against vehicles
                    _isEffective = _role in ["at", "hmg"];
                    
                    // Also check for AT capabilities in secondary weapons
                    if (!_isEffective && "secondary" in _weaponCaps) then {
                        private _secondaryData = _weaponCaps get "secondary";
                        if (count _secondaryData > 0) then {
                            _isEffective = (_secondaryData # 0) # 0; // Check for AT capability
                        };
                    };
                };
                
                case "air": {
                    // AA units are effective against air
                    _isEffective = _role == "aa";
                    
                    // Also check for AA capabilities in secondary weapons
                    if (!_isEffective && "secondary" in _weaponCaps) then {
                        private _secondaryData = _weaponCaps get "secondary";
                        if (count _secondaryData > 0) then {
                            _isEffective = (_secondaryData # 0) # 1; // Check for AA capability
                        };
                    };
                };
                
                case "armor": {
                    // Only dedicated AT is effective against armor
                    _isEffective = _role == "at";
                    
                    // Also check for AT capabilities in secondary weapons
                    if (!_isEffective && "secondary" in _weaponCaps) then {
                        private _secondaryData = _weaponCaps get "secondary";
                        if (count _secondaryData > 0) then {
                            _isEffective = (_secondaryData # 0) # 0; // Check for AT capability
                        };
                    };
                };
            };
            
            _isEffective
        }],
        
        ["_getTaskForceSourceOutpost", {
            params [ "_taskForceID"];
            private _sourceMap = _self get "_taskForceSourceMap";
            _sourceMap getOrDefault [_taskForceID, ""]
        }],
        
        ["_registerTaskForceSource", {
            params [ "_taskForceID", "_sourceMarker"];
            private _sourceMap = _self get "_taskForceSourceMap";
            _sourceMap set [_taskForceID, _sourceMarker];
            
            ["AI Commander", 3, format["Registered Task Force %1 from source outpost %2", _taskForceID, _sourceMarker]] call FLO_fnc_log;
        }],
        
        ["_getGarrisonUnits", {
            params [ "_marker"];
            
            // Get all garrison units from the garrison manager
            private _garrisonInfo = FLO_Garrison_Manager call ["getGarrison", [_marker]];
            
            if (_garrisonInfo isEqualTo []) exitWith {[]};
            
            // Access the actual garrison data structure
            private _garrisons = FLO_Garrison_Manager get "garrisons";
            if (!(_marker in keys _garrisons)) exitWith {[]};
            
            // Get the full garrison data which includes the units array
            private _garrisonData = _garrisons get _marker;
            private _units = _garrisonData select 0; // Units are at index 0
            
            // Filter for alive units
            private _garrisonUnits = _units select {alive _x};
            
            _garrisonUnits
        }],
        
        ["_getAvailableGarrisonUnitTypes", {
            params [ "_marker"];
            
            private _garrisonUnits = _self call ["_getGarrisonUnits", [_marker]];
            private _unitTypes = createHashMap;
            
            {
                private _type = typeOf _x;
                private _count = _unitTypes getOrDefault [_type, 0];
                _unitTypes set [_type, _count + 1];
            } forEach _garrisonUnits;
            
            _unitTypes
        }],
        
        ["_checkGarrisonStrength", {
            params ["_marker"];
            
            // First try to get actual units
            private _garrisonUnits = _self call ["_getGarrisonUnits", [_marker]];
            private _actualStrength = count _garrisonUnits;
            
            // If no units are found, check the intended size from the garrison data structure
            if (_actualStrength == 0) then {
                private _garrisons = FLO_Garrison_Manager get "garrisons";
                if (_marker in keys _garrisons) then {
                    private _garrisonData = _garrisons get _marker;
                    // Get the intended size which is now at index 6
                    _actualStrength = _garrisonData param [6, 0]; 
                };
            };
            
            _actualStrength
        }],
        
        ["_canGarrisonProvideUnits", {
            params [ "_marker", "_count"];
            
            // Get current garrison strength
            private _currentStrength = _self call ["_checkGarrisonStrength", [_marker]];
            
            // Get minimum required garrison size
            private _minSize = 8;  // Default minimum
            private _markerType = markerType _marker;
            
            // Apply different minimums based on outpost type
            switch (_markerType) do {
                case "o_installation": { _minSize = 15; };
                case "n_installation": { _minSize = 12; };
                case "o_support": { _minSize = 8; };
                case "n_support": { _minSize = 10; };
                case "loc_Power": { _minSize = 6; };
                case "o_recon": { _minSize = 2; };
                case "o_service": { _minSize = 6; };
                case "o_antiair": { _minSize = 8; };
                case "loc_Ruin": { _minSize = 12; };
            };
            
            // Check if garrison can provide units while maintaining minimum strength
            _currentStrength - _count >= _minSize
        }],
        
        ["_pullUnitsFromGarrison", {
            params [ "_marker", "_desiredTypes", "_count", "_taskForceID"];
            
            // Get current garrison strength for logging
            private _garrisonStrength = _self call ["_checkGarrisonStrength", [_marker]];
            
            // Check if garrison can provide the requested number of units
            if !(_self call ["_canGarrisonProvideUnits", [_marker, _count]]) exitWith {
                ["AI Commander", 3, format["Task force %1 has insufficient outpost garrison strength (%2) to pull %3 units (adjusted garrison strength)", _taskForceID, _garrisonStrength, _count]] call FLO_fnc_log;
                []
            };
            
            // Register task force source
            _self call ["_registerTaskForceSource", [_taskForceID, _marker]];
            
            // Get available unit types in the garrison
            private _availableTypes = _self call ["_getAvailableGarrisonUnitTypes", [_marker]];
            private _garrisonUnits = _self call ["_getGarrisonUnits", [_marker]];
            
            // Check if the garrison exists but has no physical units (non-activated garrison)
            if (count _garrisonUnits == 0) then {
                private _garrisons = FLO_Garrison_Manager get "garrisons";
                if (_marker in keys _garrisons) then {
                    private _garrisonData = _garrisons get _marker;
                    private _intendedSize = _garrisonData param [6, 0];
                    
                    if (_intendedSize > 0) then {
                        // Create actual units for the task force since the garrison exists but hasn't been activated
                        ["AI Commander", 3, format["Creating %1 units for task force %2 from non-activated garrison at %3 (intended size: %4)", 
                            _count, _taskForceID, _marker, _intendedSize]] call FLO_fnc_log;
                            
                        // Get marker position
                        private _pos = getMarkerPos _marker;
                        
                        // Create a temporary group
                        private _tempGroup = createGroup [east, true];
                        
                        // Create the requested number of units (or what's available)
                        private _actualCount = (_intendedSize - 2) min _count; // Leave at least 2 units in garrison
                        
                        for "_i" from 1 to _actualCount do {
                            private _unitType = "";
                            
                            // If no specified types, use available OPFOR types
                            if (count _desiredTypes > 0) then {
                                _unitType = selectRandom _desiredTypes;
                            } else {
                                _unitType = selectRandom East_Units;
                            };
                            
                            // Create the unit
                            private _unit = _tempGroup createUnit [_unitType, _pos, [], 50, "NONE"];
                            _unit setVariable ["FLO_TaskForce_FromGarrison", [_marker, _taskForceID], true];
                            _garrisonUnits pushBack _unit;
                        };
                        
                        // Update the garrison's intended size
                        _garrisonData set [6, _intendedSize - _actualCount];
                        _garrisons set [_marker, _garrisonData];
                        
                        ["AI Commander", 3, format["Created %1 units for task force %2 and reduced garrison intended size at %3 from %4 to %5", 
                            _actualCount, _taskForceID, _marker, _intendedSize, _intendedSize - _actualCount]] call FLO_fnc_log;
                    };
                };
            };
            
            // Units to be transferred to the task force
            private _pulledUnits = [];
            private _remainingCount = _count;
            
            // Parse task force ID to determine mission type
            private _missionType = "STANDARD";
            
            if (_taskForceID find "ATTACK" > -1) then {
                _missionType = "ATTACK";
            };
            if (_taskForceID find "DEFEND" > -1) then {
                _missionType = "DEFEND";
            };
            if (_taskForceID find "PATROL" > -1) then {
                _missionType = "PATROL";
            };
            if (_taskForceID find "SKIRMISH" > -1) then {
                _missionType = "SKIRMISH";
            };
            if (_taskForceID find "FIELDATTACK" > -1) then {
                _missionType = "FIELDATTACK";
            };
            
            // Define priorities based on mission type
            private _unitPriorities = createHashMap;
            
            switch (_missionType) do {
                case "ATTACK": {
                    _unitPriorities = createHashMapFromArray [
                        ["leader", 9],
                        ["at", 8],
                        ["hmg", 7],
                        ["autorifle", 7],
                        ["grenadier", 6],
                        ["marksman", 5],
                        ["medic", 8],
                        ["basic", 4],
                        ["aa", 2],
                        ["engineer", 2],
                        ["demo", 3]
                    ];
                };
                
                case "DEFEND": {
                    _unitPriorities = createHashMapFromArray [
                        ["leader", 8],
                        ["at", 7],
                        ["hmg", 9],
                        ["autorifle", 9],
                        ["grenadier", 5],
                        ["marksman", 8],
                        ["medic", 7],
                        ["basic", 4],
                        ["aa", 3],
                        ["engineer", 2],
                        ["demo", 3]
                    ];
                };
                
                case "PATROL": {
                    _unitPriorities = createHashMapFromArray [
                        ["leader", 8],
                        ["at", 4],
                        ["hmg", 3],
                        ["autorifle", 6],
                        ["grenadier", 7],
                        ["marksman", 6],
                        ["medic", 5],
                        ["basic", 9],
                        ["aa", 2],
                        ["engineer", 1],
                        ["demo", 1]
                    ];
                };
                
                case "SKIRMISH": {
                    _unitPriorities = createHashMapFromArray [
                        ["leader", 8],
                        ["at", 5],
                        ["hmg", 4],
                        ["autorifle", 7],
                        ["grenadier", 7],
                        ["marksman", 7],
                        ["medic", 6],
                        ["basic", 5],
                        ["aa", 2],
                        ["engineer", 2],
                        ["demo", 2]
                    ];
                };
                
                case "FIELDATTACK": {
                    _unitPriorities = createHashMapFromArray [
                        ["leader", 9],
                        ["at", 7],
                        ["hmg", 6],
                        ["autorifle", 8],
                        ["grenadier", 6],
                        ["marksman", 7],
                        ["medic", 8],
                        ["basic", 5],
                        ["aa", 2],
                        ["engineer", 1],
                        ["demo", 2]
                    ];
                };
                
                default {
                    _unitPriorities = createHashMapFromArray [
                        ["leader", 7],
                        ["at", 6],
                        ["hmg", 5],
                        ["autorifle", 7],
                        ["grenadier", 6],
                        ["marksman", 5],
                        ["medic", 7],
                        ["basic", 5],
                        ["aa", 3],
                        ["engineer", 3],
                        ["demo", 3]
                    ];
                };
            };
            
            // Group available units by role with their types
            private _availableByRole = createHashMap;
            {
                private _unit = _x;
                private _type = typeOf _unit;
                private _role = _self call ["_getUnitTypeRole", [_type]];
                
                private _roleUnits = _availableByRole getOrDefault [_role, []];
                _roleUnits pushBack _unit;
                _availableByRole set [_role, _roleUnits];
            } forEach _garrisonUnits;
            
            // First, ensure we have leadership
            if ("leader" in _availableByRole) then {
                private _leaders = _availableByRole get "leader";
                if (count _leaders > 0 && _remainingCount > 0) then {
                    private _leader = _leaders select 0;
                    _pulledUnits pushBack _leader;
                    _leaders deleteAt 0;
                    _availableByRole set ["leader", _leaders];
                    _remainingCount = _remainingCount - 1;
                    
                    ["AI Commander", 3, format["Selected leader (%1) for task force %2", typeOf _leader, _taskForceID]] call FLO_fnc_log;
                };
            };
            
            // Then ensure we have a medic if possible
            if ("medic" in _availableByRole) then {
                private _medics = _availableByRole get "medic";
                if (count _medics > 0 && _remainingCount > 0) then {
                    private _medic = _medics select 0;
                    _pulledUnits pushBack _medic;
                    _medics deleteAt 0;
                    _availableByRole set ["medic", _medics];
                    _remainingCount = _remainingCount - 1;
                    
                    ["AI Commander", 3, format["Selected medic (%1) for task force %2", typeOf _medic, _taskForceID]] call FLO_fnc_log;
                };
            };
            
            // Sort roles by priority for this mission type
            private _sortedRoles = [];
            {
                _sortedRoles pushBack [_x, _unitPriorities getOrDefault [_x, 1]];
            } forEach keys _availableByRole;
            
            _sortedRoles = [_sortedRoles, [], {_x # 1}, "DESCEND"] call BIS_fnc_sortBy;
            
            // Add units by priority until we reach the desired count
            {
                private _roleData = _x;
                private _role = _roleData # 0;
                private _priority = _roleData # 1;
                
                // Skip if we already processed leaders and medics
                if (_role != "leader" && _role != "medic") then {
                    private _roleUnits = _availableByRole get _role;
                    
                    // Calculate how many units of this role to take based on priority and remaining count
                    private _totalCount = count _roleUnits;
                    private _takeCount = 0;
                    
                    // Higher priority gets more units
                    switch (true) do {
                        case (_priority >= 8): { _takeCount = ceil(_totalCount * 0.8) min _remainingCount };
                        case (_priority >= 6): { _takeCount = ceil(_totalCount * 0.6) min _remainingCount };
                        case (_priority >= 4): { _takeCount = ceil(_totalCount * 0.4) min _remainingCount };
                        default { _takeCount = ceil(_totalCount * 0.2) min _remainingCount };
                    };
                    
                    // Cap based on role type to ensure garrison diversity
                    switch (_role) do {
                        case "at": { _takeCount = _takeCount min 2 };
                        case "aa": { _takeCount = _takeCount min 1 };
                        case "hmg": { _takeCount = _takeCount min 2 };
                        case "demo": { _takeCount = _takeCount min 1 };
                        case "engineer": { _takeCount = _takeCount min 1 };
                    };
                    
                    // Take the units
                    for "_i" from 0 to (_takeCount - 1) do {
                        if (_i < count _roleUnits && _remainingCount > 0) then {
                            _pulledUnits pushBack (_roleUnits select _i);
                            _remainingCount = _remainingCount - 1;
                        };
                    };
                    
                    // Update the available units
                    _roleUnits = _roleUnits select [_takeCount, count _roleUnits];
                    _availableByRole set [_role, _roleUnits];
                    
                    ["AI Commander", 3, format["Selected %1 %2 units for task force %3", _takeCount, _role, _taskForceID]] call FLO_fnc_log;
                };
                
                // Exit if we have enough units
                if (_remainingCount <= 0) exitWith {};
                
            } forEach _sortedRoles;
            
            // If we still need more units, take any available
            if (_remainingCount > 0) then {
                private _allRemainingUnits = [];
                
                {
                    _allRemainingUnits append (_availableByRole get _x);
                } forEach keys _availableByRole;
                
                private _takeCount = count _allRemainingUnits min _remainingCount;
                
                for "_i" from 0 to (_takeCount - 1) do {
                    _pulledUnits pushBack (_allRemainingUnits select _i);
                };
                
                ["AI Commander", 3, format["Selected %1 additional units to complete task force %2", _takeCount, _taskForceID]] call FLO_fnc_log;
            };
            
            // Remove the units from the garrison
            {
                private _unit = _x;
                private _group = group _unit;
                
                // Set a variable to identify the unit was pulled from garrison
                _unit setVariable ["FLO_TaskForce_FromGarrison", [_marker, _taskForceID], true];
                
                // Remove from garrison tracking
                // Direct manipulation of garrison data structure since removeUnitFromGarrison doesn't exist
                private _garrisons = FLO_Garrison_Manager get "garrisons";
                if (_marker in keys _garrisons) then {
                    private _garrisonData = _garrisons get _marker;
                    private _garrisonUnits = _garrisonData select 0;
                    
                    // Remove the unit from the garrison's unit array
                    private _index = _garrisonUnits find _unit;
                    if (_index != -1) then {
                        _garrisonUnits deleteAt _index;
                        _garrisonData set [0, _garrisonUnits];
                        _garrisons set [_marker, _garrisonData];
                        
                        ["AI Commander", 3, format["Removed unit %1 from garrison at %2", _unit, _marker]] call FLO_fnc_log;
                    };
                };
                
            } forEach _pulledUnits;
            
            // Update contribution counter
            private _contributions = _self get "_garrisonContributions";
            private _currentContribution = _contributions getOrDefault [_marker, 0];
            _contributions set [_marker, _currentContribution + count _pulledUnits];
            
            ["AI Commander", 3, format["Pulled %1 units from garrison at %2 for Task Force %3", count _pulledUnits, _marker, _taskForceID]] call FLO_fnc_log;
            
            // Return the list of pulled units
            _pulledUnits
        }],
        
        ["_returnUnitsToGarrison", {
            params [ "_taskForceID", "_marker", "_units"];
            
            // Filter for alive units
            private _aliveUnits = _units select {alive _x};
            
            if (count _aliveUnits == 0) exitWith {
                ["AI Commander", 3, format["No units to return to garrison at %1 from Task Force %2", _marker, _taskForceID]] call FLO_fnc_log;
                false
            };
            
            // Get the source outpost (use provided marker or lookup from task force ID)
            private _targetOutpost = if (_marker != "") then {
                _marker
            } else {
                _self call ["_getTaskForceSourceOutpost", [_taskForceID]]
            };
            
            // If no valid outpost, exit
            if (_targetOutpost == "") exitWith {
                ["AI Commander", 3, format["No valid outpost found to return units from Task Force %1", _taskForceID]] call FLO_fnc_log;
                false
            };
            
            // Return units to the garrison
            {
                private _unit = _x;
                
                // Clear task force variable
                _unit setVariable ["FLO_TaskForce_FromGarrison", nil, true];
                
                // Add to garrison
                private _garrisons = FLO_Garrison_Manager get "garrisons";
                if (_targetOutpost in keys _garrisons) then {
                    private _garrisonData = _garrisons get _targetOutpost;
                    private _garrisonUnits = _garrisonData select 0;
                    
                    // Add the unit to the garrison's unit array
                    _garrisonUnits pushBack _unit;
                    _garrisonData set [0, _garrisonUnits];
                    _garrisons set [_targetOutpost, _garrisonData];
                    
                    // Make sure the unit joins the garrison group
                    private _garrisonGroup = _garrisonData select 2;
                    if (!isNull _garrisonGroup) then {
                        [_unit] joinSilent _garrisonGroup;
                    };
                    
                    ["AI Commander", 3, format["Added unit %1 to garrison at %2", _unit, _targetOutpost]] call FLO_fnc_log;
                };
                
            } forEach _aliveUnits;
            
            // Update contribution counter
            private _contributions = _self get "_garrisonContributions";
            private _currentContribution = _contributions getOrDefault [_targetOutpost, 0];
            _contributions set [_targetOutpost, _currentContribution - count _aliveUnits];
            
            ["AI Commander", 3, format["Returned %1 units to garrison at %2 from Task Force %3", count _aliveUnits, _targetOutpost, _taskForceID]] call FLO_fnc_log;
            
            true
        }],
        
        ["_addUnitsToGarrison", {
            params [ "_marker", "_unitTypes", "_count"];
            
            // Ensure the marker exists and is appropriate
            if (_marker == "" || {markerColor _marker != "colorOPFOR" && markerColor _marker != "ColorEAST"}) exitWith {
                ["AI Commander", 3, format["Invalid marker for garrison: %1", _marker]] call FLO_fnc_log;
                false
            };
            
            // Verify unitTypes is not empty
            if (count _unitTypes == 0) exitWith {
                ["AI Commander", 3, "No unit types specified for garrison addition"] call FLO_fnc_log;
                false
            };
            
            // Get marker position
            private _position = getMarkerPos _marker;
            
            // Create a temporary group for the new units
            private _group = createGroup [east, true];
            
            // Spawn the requested units
            for "_i" from 1 to _count do {
                private _unitType = selectRandom _unitTypes;
                private _unit = _group createUnit [_unitType, _position, [], 0, "NONE"];
                
                // Set variable to indicate this is a garrison unit
                _unit setVariable ["FLO_GarrisonUnit", true, true];
            };
            
            // Add the group to the garrison - direct manipulation
            private _garrisons = FLO_Garrison_Manager get "garrisons";
            
            if (_marker in keys _garrisons) then {
                // Update existing garrison
                private _garrisonData = _garrisons get _marker;
                private _garrisonUnits = _garrisonData select 0;
                private _garrisonVehicles = _garrisonData select 1;
                private _garrisonGroup = _garrisonData select 2;
                
                // Merge with existing garrison group if it exists
                if (!isNull _garrisonGroup) then {
                    (units _group) joinSilent _garrisonGroup;
                    _garrisonUnits append (units _group);
                } else {
                    // Use the new group as the garrison group
                    _garrisonData set [2, _group];
                    _garrisonUnits append (units _group);
                };
                
                // Update the units in the garrison data
                _garrisonData set [0, _garrisonUnits];
                _garrisons set [_marker, _garrisonData];
            } else {
                // Create a new garrison entry
                private _markerType = markerType _marker;
                private _sizeLimits = FLO_Garrison_Manager call ["getSizeLimits", [_markerType]];
                private _baseSize = _sizeLimits select 0;
                private _maxSize = _sizeLimits select 1;
                
                // Create garrison data structure
                private _newGarrisonData = [
                    units _group,   // Units
                    [],             // Vehicles
                    _group,         // Group
                    time,           // Timestamp
                    0,              // Virtual strength
                    0,              // Queued reinforcements
                    _baseSize,      // Base size
                    _maxSize,       // Max size
                    count (units _group) // Current size
                ];
                
                // Add to garrisons hashmap
                _garrisons set [_marker, _newGarrisonData];
            };
            
            ["AI Commander", 3, format["Added %1 units to garrison at %2", _count, _marker]] call FLO_fnc_log;
            
            true
        }],
        
        // Add a method to analyze vehicle weapon capabilities in detail
        ["_analyzeVehicleWeapons", {
            params [ "_vehicle"];
            
            // If the vehicle is a string (class name), create a temporary vehicle
            private _tempVehicle = objNull;
            private _vehicleObj = _vehicle;
            
            if (_vehicle isEqualType "") then {
                _tempVehicle = createVehicle [_vehicle, [0,0,0], [], 0, "NONE"];
                _tempVehicle allowDamage false;
                _vehicleObj = _tempVehicle;
            };
            
            // Initialize capabilities maps
            private _magTypes = createHashMap;
            private _weaponCapabilities = createHashMapFromArray [
                [0, []], // Anti-Infantry
                [1, []], // Anti-Vehicle Light
                [2, []], // Anti-Vehicle Medium
                [3, []], // Anti-Vehicle Heavy
                [4, []], // Anti-Air
                [5, []], // Anti-Structure
                [6, []], // Anti-Personnel (grenades)
                [7, []], // Anti-Armor (rockets)
                [8, []], // Ground-To-Air
                [9, []]  // Ground-To-Ground
            ];
            
            // Analyze magazines
            private _magazines = magazinesAmmoFull [_vehicleObj, false];
            {
                private _key = _x select 0;
                
                if (_key in _magTypes) then {
                    // Update existing entry
                    private _data = _magTypes get _key;
                    _data set [1, (_data select 1) + (_x select 1)];
                } else {
                    // Create new entry
                    private _name = _x select 0;
                    private _ammoCount = _x select 1;
                    private _usageFlags = [0,0,0,0,0,0,0,0,0,0];
                    
                    // Get ammo info
                    private _ammo = getText (configFile >> "CfgMagazines" >> _name >> "ammo");
                    private _ufValue = getNumber (configFile >> "CfgAmmo" >> _ammo >> "aiAmmoUsageFlags");
                    
                    // Decode flags or determine based on ammo type
                    if (_ufValue > 0) then {
                        _usageFlags = [_ufValue, 10] call BIS_fnc_decodeFlags2;
                    } else {
                        if (_ammo isKindOf "GrenadeBase") then {
                            _usageFlags = [0,0,0,0,0,0,1,0,0,0];
                        };
                        if (_ammo isKindOf "RocketBase") then {
                            _usageFlags = [0,0,0,0,0,0,0,1,0,1];
                        };
                    };
                    
                    // Get hit power
                    private _hit = getNumber (configFile >> "CfgAmmo" >> _ammo >> "hit");
                    
                    // Store data
                    _magTypes set [_key, [_name, _ammoCount, _usageFlags, _hit]];
                };
            } forEach _magazines;
            
            // Analyze weapons
            private _weapons = weapons _vehicleObj;
            {
                private _weaponName = _x;
                
                // Get weapon characteristics
                private _minRange = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "minRange");
                private _midRange = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "midRange");
                private _maxRange = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "maxRange");
                private _minRangeProbab = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "minRangeProbab");
                private _midRangeProbab = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "midRangeProbab");
                private _maxRangeProbab = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "maxRangeProbab");
                
                // Get compatible magazines
                private _wMags = getArray (configFile >> "CfgWeapons" >> _weaponName >> "magazines");
                
                // Associate weapon with magazine capabilities
                {
                    private _key = _x;
                    if (_key in _magTypes) then {
                        private _mag = _magTypes get _key;
                        
                        // Add weapon to each capability category based on magazine usage flags
                        for "_i" from 0 to 9 do {
                            if ((_mag select 2) select _i == 1) then {
                                private _prev = _weaponCapabilities get _i;
                                private _new = [
                                    _weaponName,           // Weapon name
                                    0,                     // Generic index
                                    _minRange,             // Min range
                                    _midRange,             // Mid range
                                    _maxRange,             // Max range
                                    _minRangeProbab,       // Min range probability
                                    _midRangeProbab,       // Mid range probability
                                    _maxRangeProbab        // Max range probability
                                ];
                                
                                // Append magazine info
                                _new append _mag;
                                
                                // Calculate total damage potential
                                _new set [12, (_mag # 1) * (_mag # 3)];
                                
                                _prev pushBack _new;
                            };
                        };
                    };
                } forEach _wMags;
            } forEach _weapons;
            
            // Clean up temporary vehicle if created
            if (!isNull _tempVehicle) then {
                deleteVehicle _tempVehicle;
            };
            
            // Return the capabilities map
            [_weaponCapabilities, _magTypes]
        }],
        
        // Add a method to update a unit's weapon capabilities in the field
        ["_updateUnitWeaponCapabilities", {
            params [ "_unit"];
            
            if (isNull _unit || !alive _unit) exitWith {false};
            
            // If this is a vehicle, use the vehicle analysis method
            if (_unit isKindOf "LandVehicle" || _unit isKindOf "Air" || _unit isKindOf "Ship") then {
                private _capabilities = _self call ["_analyzeVehicleWeapons", [_unit]];
                _unit setVariable ["FLO_weaponCapabilities", _capabilities # 0];
                _unit setVariable ["FLO_magTypes", _capabilities # 1];
                
                ["AI Commander", 3, format["Updated vehicle %1 weapon capabilities", typeOf _unit]] call FLO_fnc_log;
                true
            } else {
                // For infantry, do a simpler analysis
                private _primaryWeapon = primaryWeapon _unit;
                private _secondaryWeapon = secondaryWeapon _unit;
                
                private _capabilities = createHashMap;
                
                if (_primaryWeapon != "") then {
                    private _maxRange = getNumber (configFile >> "CfgWeapons" >> _primaryWeapon >> "maxRange");
                    if (_maxRange == 0) then { _maxRange = 500 }; // Default
                    
                    _capabilities set ["primary", [
                        _primaryWeapon,
                        getArray (configFile >> "CfgWeapons" >> _primaryWeapon >> "magazines"),
                        _maxRange
                    ]];
                };
                
                if (_secondaryWeapon != "") then {
                    private _maxRange = getNumber (configFile >> "CfgWeapons" >> _secondaryWeapon >> "maxRange");
                    if (_maxRange == 0) then { _maxRange = 300 }; // Default
                    
                    private _mags = getArray (configFile >> "CfgWeapons" >> _secondaryWeapon >> "magazines");
                    private _isAT = false;
                    private _isAA = false;
                    
                    // Check first magazine to determine launcher type
                    if (count _mags > 0) then {
                        private _ammo = getText (configFile >> "CfgMagazines" >> (_mags select 0) >> "ammo");
                        
                        // Determine if AT or AA
                        _isAT = _secondaryWeapon find "_AT_" > -1 || 
                               _ammo find "_AT_" > -1 || 
                               _secondaryWeapon find "LAT" > -1 ||
                               _secondaryWeapon find "launcher" > -1;
                                
                        _isAA = _secondaryWeapon find "_AA_" > -1 || 
                               _ammo find "_AA_" > -1;
                    };
                    
                    _capabilities set ["secondary", [
                        _secondaryWeapon,
                        _mags,
                        _maxRange,
                        [_isAT, _isAA]
                    ]];
                };
                
                _unit setVariable ["FLO_infantryCapabilities", _capabilities];
                
                true
            };
        }],
        
        // Add a method to get the most effective weapons for a specific target type
        ["_getEffectiveWeaponsForTarget", {
            params [ "_unit", "_targetType"];
            
            if (isNull _unit || !alive _unit) exitWith {[]};
            
            // Check if it's a vehicle
            if (_unit isKindOf "LandVehicle" || _unit isKindOf "Air" || _unit isKindOf "Ship") then {
                // If weapon capabilities are not analyzed yet, do it now
                if (isNil {_unit getVariable "FLO_weaponCapabilities"}) then {
                    _self call ["_updateUnitWeaponCapabilities", [_unit]];
                };
                
                private _weaponCapabilities = _unit getVariable ["FLO_weaponCapabilities", createHashMap];
                
                // Select appropriate capabilities based on target type
                private _effectiveWeapons = [];
                
                switch (_targetType) do {
                    case "infantry": {
                        // Anti-infantry capabilities (index 0)
                        _effectiveWeapons = _weaponCapabilities getOrDefault [0, []];
                    };
                    
                    case "vehicle": {
                        // Combine anti-vehicle capabilities (indices 1, 2, 3)
                        _effectiveWeapons = [];
                        _effectiveWeapons append (_weaponCapabilities getOrDefault [1, []]);
                        _effectiveWeapons append (_weaponCapabilities getOrDefault [2, []]);
                        _effectiveWeapons append (_weaponCapabilities getOrDefault [3, []]);
                    };
                    
                    case "armor": {
                        // Heavy anti-vehicle capabilities (index 3) and anti-armor rockets (index 7)
                        _effectiveWeapons = [];
                        _effectiveWeapons append (_weaponCapabilities getOrDefault [3, []]);
                        _effectiveWeapons append (_weaponCapabilities getOrDefault [7, []]);
                    };
                    
                    case "air": {
                        // Anti-air capabilities (index 4) and ground-to-air (index 8)
                        _effectiveWeapons = [];
                        _effectiveWeapons append (_weaponCapabilities getOrDefault [4, []]);
                        _effectiveWeapons append (_weaponCapabilities getOrDefault [8, []]);
                    };
                    
                    case "structure": {
                        // Anti-structure capabilities (index 5)
                        _effectiveWeapons = _weaponCapabilities getOrDefault [5, []];
                    };
                    
                    default {
                        // Return all available weapons
                        {
                            _effectiveWeapons append (_weaponCapabilities getOrDefault [_x, []]);
                        } forEach [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
                    };
                };
                
                // Sort by damage potential (highest first)
                _effectiveWeapons = [_effectiveWeapons, [], {_x # 12}, "DESCEND"] call BIS_fnc_sortBy;
                
                _effectiveWeapons
            } else {
                // For infantry, check weapon capabilities
                if (isNil {_unit getVariable "FLO_infantryCapabilities"}) then {
                    _self call ["_updateUnitWeaponCapabilities", [_unit]];
                };
                
                private _capabilities = _unit getVariable ["FLO_infantryCapabilities", createHashMap];
                private _effectiveWeapons = [];
                
                switch (_targetType) do {
                    case "infantry": {
                        // Primary weapon is typically most effective against infantry
                        if ("primary" in _capabilities) then {
                            _effectiveWeapons pushBack (_capabilities get "primary");
                        };
                    };
                    
                    case "vehicle": 
                    case "armor": {
                        // Secondary AT weapon for vehicles
                        if ("secondary" in _capabilities) then {
                            private _secondaryData = _capabilities get "secondary";
                            if (count _secondaryData >= 4 && (_secondaryData # 3) # 0) then {
                                _effectiveWeapons pushBack _secondaryData;
                            };
                        };
                        
                        // Also add primary if no secondary
                        if (count _effectiveWeapons == 0 && "primary" in _capabilities) then {
                            _effectiveWeapons pushBack (_capabilities get "primary");
                        };
                    };
                    
                    case "air": {
                        // Secondary AA weapon for air
                        if ("secondary" in _capabilities) then {
                            private _secondaryData = _capabilities get "secondary";
                            if (count _secondaryData >= 4 && (_secondaryData # 3) # 1) then {
                                _effectiveWeapons pushBack _secondaryData;
                            };
                        };
                        
                        // Also add primary if no secondary
                        if (count _effectiveWeapons == 0 && "primary" in _capabilities) then {
                            _effectiveWeapons pushBack (_capabilities get "primary");
                        };
                    };
                    
                    default {
                        // Return all available weapons
                        {
                            if (_x in _capabilities) then {
                                _effectiveWeapons pushBack (_capabilities get _x);
                            };
                        } forEach ["primary", "secondary"];
                    };
                };
                
                _effectiveWeapons
            };
        }]
    ]];
    
    // Initialize unit capabilities
    _integrationSystem call ["_initUnitCapabilities", []];
    
    // Store the system globally
    FLO_TaskForce_Garrison_Integration = _integrationSystem;
    
    ["AI Commander", 3, "Task Force Garrison Integration System Initialized"] call FLO_fnc_log;
};

// Return the integration system
FLO_TaskForce_Garrison_Integration 