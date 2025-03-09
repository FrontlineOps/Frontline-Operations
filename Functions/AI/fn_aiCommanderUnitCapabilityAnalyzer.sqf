/*
 * Function: FLO_fnc_AICommanderUnitCapabilityAnalyzer
 * Author: Azraeelian Angel
 * Description:
 * Analyzes unit capabilities and returns a hashmap of unit types and their capabilities
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <HASHMAP> - The integration system object with methods:
 * - Plus analysis and utility methods
 *
 * Example:
 * _analyzerSystem = call FLO_fnc_AICommanderUnitCapabilityAnalyzer;
 */

if (!isServer) exitWith {};

// Initialize the integration system if it doesn't exist
if (isNil "FLO_AICommander_UnitCapabilityAnalyzer") then {
    ["AI Commander", 3, "Initializing Unit Capability Analyzer"] call FLO_fnc_log;
    
    private _analyzerSystem = createHashMapObject [[
        // Properties
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
                    private _usageFlags = [0,0,0,0,0,0,0,0,0,0,0];
                    
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
        }],

        ["_evaluateVehicleCapabilities", {
            params ["_vehicle"];
            
            // Create empty hashmaps for storing vehicle data
            private _magTypes = createHashMap;
            private _weaponCapabilities = [0,1,2,3,4,5,6,7,8,9] createHashMapFromArray [[],[],[],[],[],[],[],[],[],[]];
            
            // Analyze all magazines in all turrets
            private _magazines = magazinesAllTurrets [_vehicle, true];
            {
                private _key = [_x select 1, _x select 0];
                if (_key in _magTypes) then {
                    private _data = _magTypes get _key; 
                    _data set [1, (_data select 1) + (_x select 2)]
                } else {
                    private _name = _x select 0;
                    private _turret = _x select 1;
                    private _ammoCount = _x select 2;
                    private _usageFlags = [0,0,0,0,0,0,0,0,0,0];
                    private _ammo = getText (configFile >> "CfgMagazines" >> _name >> "ammo");
                    private _ufValue = getNumber (configFile >> "CfgAmmo" >> _ammo >> "aiAmmoUsageFlags");
                    
                    if (_ufValue > 0) then {
                        _usageFlags = [_ufValue, 10] call BIS_fnc_decodeFlags2;
                    } else {
                        if (_ammo isKindOf "GrenadeBase") then {_usageFlags = [0,0,0,0,0,0,1,0,0,0]};
                        if (_ammo isKindOf "RocketBase") then {_usageFlags = [0,0,0,0,0,0,0,1,0,1]};
                    };
                    
                    private _cost = getNumber (configFile >> "CfgAmmo" >> _ammo >> "cost");
                    private _hit = getNumber (configFile >> "CfgAmmo" >> _ammo >> "hit");
                    
                    _magTypes set [_key, [_name, _ammoCount, _usageFlags, _hit]];
                };
            } forEach _magazines;
            
            // Analyze all turrets and weapons
            private _turrets = [[-1]] + allTurrets _vehicle;
            {
                private _weapons = _vehicle weaponsTurret _x;
                private _turret = _x;
                
                {
                    private _weaponName = _x;
                    private _minRange = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "minRange");
                    private _midRange = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "midRange");
                    private _maxRange = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "maxRange");
                    private _minRangeProbab = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "minRangeProbab");
                    private _midRangeProbab = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "midRangeProbab");
                    private _maxRangeProbab = getNumber (configFile >> "CfgWeapons" >> _weaponName >> "maxRangeProbab");
                    private _wMags = getArray (configFile >> "CfgWeapons" >> _x >> "magazines");
                    
                    {
                        private _key = [_turret, _x];
                        if (_key in _magTypes) then {
                            private _mag = _magTypes get _key;
                            for "_i" from 0 to 9 do {
                                if ((_mag select 2) select _i == 1) then {
                                    private _prev = _weaponCapabilities get _i;
                                    private _new = [_weaponName, _turret, _minRange, _midRange, _maxRange, _minRangeProbab, _midRangeProbab, _maxRangeProbab];
                                    _new append _mag;
                                    _new set [12, (_mag#1) * (_mag#3)];
                                    _prev pushBack _new;
                                };
                            };
                        };
                    } forEach _wMags;
                } forEach _weapons;
            } forEach _turrets;
            
            // Store capabilities in vehicle variables
            _vehicle setVariable ["FLO_weaponCapabilities", _weaponCapabilities];
            _vehicle setVariable ["FLO_magTypes", _magTypes];
            
            // Return the weapon capabilities
            _weaponCapabilities
        }]
    ]];
    
    // Initialize unit capabilities
    _analyzerSystem call ["_initUnitCapabilities", []];
    
    // Store the system globally
    FLO_AICommander_UnitCapabilityAnalyzer = _analyzerSystem;
    
    ["AI Commander", 3, "Unit Capability Analyzer Initialized"] call FLO_fnc_log;
};

// Return the integration system
FLO_AICommander_UnitCapabilityAnalyzer 