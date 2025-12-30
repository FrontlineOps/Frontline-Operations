/*
 * Function: FLO_fnc_gtnCapabilityAnalyzer
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Config-Based Heavyweight Capability Analyzer for the GTN AI Commander.
 * All combat power, threat values, armor ratings, and weapon capabilities
 * are derived from actual Arma 3 config entries (CfgVehicles, CfgWeapons,
 * CfgMagazines, CfgAmmo) rather than hardcoded values.
 *
 * Key Config Values Used:
 * - CfgVehicles >> "cost" - AI value/combat power (already balanced by BI)
 * - CfgVehicles >> "threat" - [soft, armor, air] threat ratings 0-1
 * - CfgVehicles >> "armor" - overall armor protection value
 * - CfgAmmo >> "caliber" - armor penetration multiplier
 * - CfgAmmo >> "hit" - base damage value
 * - CfgWeapons >> "maxZeroing" - effective range indicator
 *
 * This approach ensures ANY modded units/vehicles are properly analyzed.
 *
 * Return Value:
 * Capability Analyzer HashMap Object <HASHMAP>
 *
 * Example:
 * private _analyzer = call FLO_fnc_gtnCapabilityAnalyzer;
 * private _analysis = _analyzer call ["_analyzeGroup", [_groupId]];
 */

if (!isNil "FLO_GTN_CapabilityAnalyzer") exitWith { FLO_GTN_CapabilityAnalyzer };

["GTN Capability Analyzer", 2, "Initializing Config-Based Capability Analyzer"] call FLO_fnc_log;

// ============================================================================
// CREATE ANALYZER OBJECT
// ============================================================================

FLO_GTN_CapabilityAnalyzer = createHashMapObject [[
    // Analysis cache to avoid repeated config lookups
    ["_analysisCache", createHashMap],
    ["_configCache", createHashMap],  // Cache for config lookups
    ["_cacheTimeout", 60],

    // Caliber thresholds for capability classification (from Arma config values)
    // These are based on actual Arma 3 caliber values in CfgAmmo
    ["_caliberThresholds", createHashMapFromArray [
        ["AT_HEAVY", 40],    // ATGM, tank rounds (caliber 40-120+)
        ["AT_LIGHT", 15],    // RPG, LAW, recoilless (caliber 15-40)
        ["AUTOCANNON", 6],   // 20mm-40mm cannons (caliber 6-15)
        ["HMG", 2],          // .50 cal, 12.7mm (caliber 2-6)
        ["SMALL_ARMS", 0]    // Everything else
    ]],

    // ========================================================================
    // CACHE UTILITY METHODS
    // ========================================================================

    // Get cached value or nil if expired
    ["_getCached", {
        params ["_key"];
        private _cache = _self get "_analysisCache";
        private _entry = _cache getOrDefault [_key, nil];
        if (isNil "_entry") exitWith { nil };
        private _timestamp = _entry select 0;
        if (diag_tickTime - _timestamp > (_self get "_cacheTimeout")) exitWith {
            _cache deleteAt _key;
            nil
        };
        _entry select 1
    }],

    // Store value in cache
    ["_setCache", {
        params ["_key", "_value"];
        (_self get "_analysisCache") set [_key, [diag_tickTime, _value]];
    }],

    // Get cached config value (configs never change during mission)
    ["_getConfigCached", {
        params ["_key"];
        (_self get "_configCache") getOrDefault [_key, nil]
    }],

    // Store config value in permanent cache
    ["_setConfigCache", {
        params ["_key", "_value"];
        (_self get "_configCache") set [_key, _value];
    }],

    // ========================================================================
    // CONFIG READING METHODS
    // ========================================================================

    // Get combat power from CfgVehicles >> "cost"
    // This is the AI's assessment of unit value - already balanced by BI
    // Typical values: Rifleman ~30000, Tank ~500000, Attack Heli ~1000000
    ["_getConfigCost", {
        params ["_typeClass"];

        private _cacheKey = format["cost_%1", _typeClass];
        private _cached = _self call ["_getConfigCached", [_cacheKey]];
        if (!isNil "_cached") exitWith { _cached };

        private _cfg = configFile >> "CfgVehicles" >> _typeClass;
        private _cost = if (isClass _cfg) then {
            getNumber (_cfg >> "cost")
        } else { 10000 };

        // Normalize to a 0-1000 scale for easier comparison
        // Rifleman ~30, Tank ~500, Attack Heli ~1000
        private _normalized = (_cost / 1000) min 1500;

        _self call ["_setConfigCache", [_cacheKey, _normalized]];
        _normalized
    }],

    // Get threat profile from CfgVehicles >> "threat"
    // Returns [softTarget, armoredTarget, airTarget] each 0-1
    ["_getConfigThreat", {
        params ["_typeClass"];

        private _cacheKey = format["threat_%1", _typeClass];
        private _cached = _self call ["_getConfigCached", [_cacheKey]];
        if (!isNil "_cached") exitWith { _cached };

        private _cfg = configFile >> "CfgVehicles" >> _typeClass;
        private _threat = if (isClass _cfg) then {
            getArray (_cfg >> "threat")
        } else { [0.5, 0, 0] };

        // Ensure we have 3 elements
        if (count _threat < 3) then {
            _threat = [0.5, 0, 0];
        };

        _self call ["_setConfigCache", [_cacheKey, _threat]];
        _threat
    }],

    // Get armor value from CfgVehicles >> "armor"
    // Higher = more armored. Tanks ~500+, APCs ~100, cars ~30
    ["_getConfigArmor", {
        params ["_typeClass"];

        private _cacheKey = format["armor_%1", _typeClass];
        private _cached = _self call ["_getConfigCached", [_cacheKey]];
        if (!isNil "_cached") exitWith { _cached };

        private _cfg = configFile >> "CfgVehicles" >> _typeClass;
        private _armor = if (isClass _cfg) then {
            getNumber (_cfg >> "armor")
        } else { 1 };

        _self call ["_setConfigCache", [_cacheKey, _armor]];
        _armor
    }],

    // Get max speed from CfgVehicles >> "maxSpeed"
    ["_getConfigMaxSpeed", {
        params ["_typeClass"];

        private _cacheKey = format["speed_%1", _typeClass];
        private _cached = _self call ["_getConfigCached", [_cacheKey]];
        if (!isNil "_cached") exitWith { _cached };

        private _cfg = configFile >> "CfgVehicles" >> _typeClass;
        private _speed = if (isClass _cfg) then {
            getNumber (_cfg >> "maxSpeed")
        } else { 0 };

        _self call ["_setConfigCache", [_cacheKey, _speed]];
        _speed
    }],

    // Get passenger capacity from CfgVehicles >> "transportSoldier"
    ["_getConfigTransport", {
        params ["_typeClass"];

        private _cacheKey = format["transport_%1", _typeClass];
        private _cached = _self call ["_getConfigCached", [_cacheKey]];
        if (!isNil "_cached") exitWith { _cached };

        private _cfg = configFile >> "CfgVehicles" >> _typeClass;
        private _transport = if (isClass _cfg) then {
            getNumber (_cfg >> "transportSoldier")
        } else { 0 };

        _self call ["_setConfigCache", [_cacheKey, _transport]];
        _transport
    }],

    // ========================================================================
    // WEAPON AND AMMO CONFIG ANALYSIS
    // ========================================================================

    // Analyze a weapon's ammo to determine penetration and damage
    // Returns: [maxCaliber, maxHit, maxIndirectHit, effectiveRange, isAA]
    ["_analyzeWeaponAmmo", {
        params ["_weaponClass"];

        private _cacheKey = format["weaponAmmo_%1", _weaponClass];
        private _cached = _self call ["_getConfigCached", [_cacheKey]];
        if (!isNil "_cached") exitWith { _cached };

        private _maxCaliber = 0;
        private _maxHit = 0;
        private _maxIndirectHit = 0;
        private _effectiveRange = 300;  // Default
        private _isAA = false;

        private _cfgWeapon = configFile >> "CfgWeapons" >> _weaponClass;
        if (!isClass _cfgWeapon) exitWith {
            _self call ["_setConfigCache", [_cacheKey, [0, 10, 0, 300, false]]];
            [0, 10, 0, 300, false]
        };

        // Get effective range from maxZeroing
        private _maxZeroing = getNumber (_cfgWeapon >> "maxZeroing");
        if (_maxZeroing > 0) then { _effectiveRange = _maxZeroing };

        // Check if this is a launcher (type 4 = secondary weapon)
        private _weaponType = getNumber (_cfgWeapon >> "type");

        // Get magazines this weapon uses
        private _magazines = getArray (_cfgWeapon >> "magazines");

        // Also check muzzles for weapons with multiple muzzles (like GL combos)
        private _muzzles = getArray (_cfgWeapon >> "muzzles");
        {
            if (_x != "this") then {
                private _muzzleMags = getArray (_cfgWeapon >> _x >> "magazines");
                _magazines append _muzzleMags;
            };
        } forEach _muzzles;

        // Analyze each magazine's ammo
        {
            private _magClass = _x;
            private _cfgMag = configFile >> "CfgMagazines" >> _magClass;
            if (!isClass _cfgMag) then { continue };

            private _ammoClass = getText (_cfgMag >> "ammo");
            private _cfgAmmo = configFile >> "CfgAmmo" >> _ammoClass;
            if (!isClass _cfgAmmo) then { continue };

            // Get ammo properties
            private _caliber = getNumber (_cfgAmmo >> "caliber");
            private _hit = getNumber (_cfgAmmo >> "hit");
            private _indirectHit = getNumber (_cfgAmmo >> "indirectHit");
            private _indirectRange = getNumber (_cfgAmmo >> "indirectHitRange");

            // Track maximums
            if (_caliber > _maxCaliber) then { _maxCaliber = _caliber };
            if (_hit > _maxHit) then { _maxHit = _hit };
            if (_indirectHit > _maxIndirectHit) then { _maxIndirectHit = _indirectHit };

            // Check if this is AA ammo (proximity fuse, flak, etc)
            private _triggerDistance = getNumber (_cfgAmmo >> "fuseDistance");
            private _simulation = getText (_cfgAmmo >> "simulation");
            if (_triggerDistance > 0 || _simulation == "shotMissile") then {
                // Check if it's a missile that tracks air
                private _missileLock = getText (_cfgAmmo >> "missileLockCone");
                private _irLock = getNumber (_cfgAmmo >> "irLock");
                if (_irLock > 0) then { _isAA = true };
            };

            // Estimate range from ammo physics if not set by zeroing
            if (_maxZeroing == 0) then {
                private _initSpeed = getNumber (_cfgAmmo >> "typicalSpeed");
                private _airFriction = getNumber (_cfgAmmo >> "airFriction");
                if (_initSpeed > 0) then {
                    // Rough estimate: faster projectile = longer range
                    _effectiveRange = _effectiveRange max (_initSpeed * 2);
                };
            };
        } forEach _magazines;

        private _result = [_maxCaliber, _maxHit, _maxIndirectHit, _effectiveRange, _isAA];
        _self call ["_setConfigCache", [_cacheKey, _result]];
        _result
    }],

    // Classify weapon capability based on ammo caliber
    // Returns: "AT_HEAVY", "AT_LIGHT", "AUTOCANNON", "HMG", "SMALL_ARMS"
    ["_classifyWeaponPenetration", {
        params ["_caliber"];

        private _thresholds = _self get "_caliberThresholds";

        if (_caliber >= (_thresholds get "AT_HEAVY")) exitWith { "AT_HEAVY" };
        if (_caliber >= (_thresholds get "AT_LIGHT")) exitWith { "AT_LIGHT" };
        if (_caliber >= (_thresholds get "AUTOCANNON")) exitWith { "AUTOCANNON" };
        if (_caliber >= (_thresholds get "HMG")) exitWith { "HMG" };
        "SMALL_ARMS"
    }],

    // Get all weapons from a vehicle's config (including turrets)
    ["_getVehicleWeapons", {
        params ["_typeClass"];

        private _cacheKey = format["vehWeapons_%1", _typeClass];
        private _cached = _self call ["_getConfigCached", [_cacheKey]];
        if (!isNil "_cached") exitWith { _cached };

        private _weapons = [];
        private _cfg = configFile >> "CfgVehicles" >> _typeClass;

        if (!isClass _cfg) exitWith {
            _self call ["_setConfigCache", [_cacheKey, []]];
            []
        };

        // Get main weapons
        private _mainWeapons = getArray (_cfg >> "weapons");
        _weapons append _mainWeapons;

        // Recursively get turret weapons
        private _fnc_getTurretWeapons = {
            params ["_turretCfg"];
            private _turretWeapons = getArray (_turretCfg >> "weapons");
            _weapons append _turretWeapons;

            // Check sub-turrets
            private _subTurrets = configProperties [_turretCfg >> "Turrets", "isClass _x"];
            {
                [_x] call _fnc_getTurretWeapons;
            } forEach _subTurrets;
        };

        private _turrets = configProperties [_cfg >> "Turrets", "isClass _x"];
        {
            [_x] call _fnc_getTurretWeapons;
        } forEach _turrets;

        // Remove empty and horn entries
        _weapons = _weapons select {_x != "" && !(_x find "Horn" >= 0)};

        _self call ["_setConfigCache", [_cacheKey, _weapons]];
        _weapons
    }],

    // ========================================================================
    // UNIT ANALYSIS METHODS
    // ========================================================================

    // Analyze a single unit's capabilities using config values
    ["_analyzeUnit", {
        params ["_unit"];
        if (isNull _unit || !alive _unit) exitWith { nil };

        private _typeClass = typeOf _unit;

        // Get combat power from config cost
        private _configCost = _self call ["_getConfigCost", [_typeClass]];

        // Get threat profile from config
        private _threatProfile = _self call ["_getConfigThreat", [_typeClass]];

        private _analysis = createHashMapFromArray [
            ["unit", _unit],
            ["typeClass", _typeClass],
            ["combatPower", _configCost],
            ["threatVsSoft", _threatProfile select 0],
            ["threatVsArmor", _threatProfile select 1],
            ["threatVsAir", _threatProfile select 2],
            ["weapons", []],
            ["capabilities", []],
            ["maxPenetration", 0],
            ["maxDamage", 0],
            ["effectiveRange", 300],
            ["isSpecialist", false],
            ["specialization", ""],
            ["role", "RIFLEMAN"],
            ["equipment", []],
            ["damageStatus", 1 - (damage _unit)]
        ];

        // Detect specialist traits
        if (_unit getUnitTrait "Medic") then {
            _analysis set ["role", "MEDIC"];
            _analysis set ["isSpecialist", true];
            _analysis set ["specialization", "MEDICAL"];
            (_analysis get "capabilities") pushBack "MEDICAL";
        };
        if (_unit getUnitTrait "Engineer") then {
            _analysis set ["role", "ENGINEER"];
            _analysis set ["isSpecialist", true];
            _analysis set ["specialization", "ENGINEERING"];
            (_analysis get "capabilities") pushBack "REPAIR";
            (_analysis get "capabilities") pushBack "DEFUSE";
        };
        if (_unit getUnitTrait "explosiveSpecialist") then {
            (_analysis get "capabilities") pushBack "EOD";
        };
        if (_unit getUnitTrait "UAVHacker") then {
            (_analysis get "capabilities") pushBack "UAV_CONTROL";
        };

        // Analyze weapons using config-based ammo analysis
        private _weapons = weapons _unit;
        private _maxPen = 0;
        private _maxDmg = 0;
        private _maxRange = 300;
        private _hasAA = false;

        {
            private _weaponClass = _x;
            private _ammoAnalysis = _self call ["_analyzeWeaponAmmo", [_weaponClass]];
            _ammoAnalysis params ["_caliber", "_hit", "_indirectHit", "_range", "_isAA"];

            // Track best stats
            if (_caliber > _maxPen) then { _maxPen = _caliber };
            if (_hit > _maxDmg) then { _maxDmg = _hit };
            if (_range > _maxRange) then { _maxRange = _range };
            if (_isAA) then { _hasAA = true };

            // Classify weapon penetration capability
            private _penClass = _self call ["_classifyWeaponPenetration", [_caliber]];

            (_analysis get "weapons") pushBack [_weaponClass, _penClass, _caliber, _hit, _range];

            // Add capabilities based on config-derived penetration
            switch (_penClass) do {
                case "AT_HEAVY": {
                    (_analysis get "capabilities") pushBack "AT_HEAVY";
                    (_analysis get "capabilities") pushBack "AT";
                };
                case "AT_LIGHT": {
                    (_analysis get "capabilities") pushBack "AT_LIGHT";
                    (_analysis get "capabilities") pushBack "AT";
                };
                case "AUTOCANNON": {
                    (_analysis get "capabilities") pushBack "AUTOCANNON";
                };
                case "HMG": {
                    (_analysis get "capabilities") pushBack "HMG";
                    (_analysis get "capabilities") pushBack "SUPPRESS";
                };
            };

            if (_isAA) then {
                (_analysis get "capabilities") pushBack "AA";
            };
        } forEach _weapons;

        _analysis set ["maxPenetration", _maxPen];
        _analysis set ["maxDamage", _maxDmg];
        _analysis set ["effectiveRange", _maxRange];

        // Determine role based on config-derived capabilities
        private _caps = _analysis get "capabilities";
        if (("AT_HEAVY" in _caps || "AT_LIGHT" in _caps) && !(_analysis get "isSpecialist")) then {
            _analysis set ["role", "AT_SPECIALIST"];
            _analysis set ["isSpecialist", true];
            _analysis set ["specialization", "ANTI_ARMOR"];
        };
        if ("AA" in _caps && !(_analysis get "isSpecialist")) then {
            _analysis set ["role", "AA_SPECIALIST"];
            _analysis set ["isSpecialist", true];
            _analysis set ["specialization", "ANTI_AIR"];
        };
        if ("HMG" in _caps && !(_analysis get "isSpecialist")) then {
            _analysis set ["role", "MACHINEGUNNER"];
        };

        // Check if this is a marksman/sniper based on effective range
        if (_maxRange > 800 && !(_analysis get "isSpecialist")) then {
            _analysis set ["role", "MARKSMAN"];
            if (_maxRange > 1200) then {
                _analysis set ["role", "SNIPER"];
                _analysis set ["isSpecialist", true];
                _analysis set ["specialization", "PRECISION"];
            };
            (_analysis get "capabilities") pushBack "PRECISION";
        };

        // Check for leader/officer
        if (_unit == leader group _unit) then {
            if (rank _unit in ["CAPTAIN", "MAJOR", "COLONEL"]) then {
                _analysis set ["role", "OFFICER"];
                (_analysis get "capabilities") pushBack "LEADERSHIP";
            };
        };

        // Analyze equipment
        private _items = items _unit + assignedItems _unit;
        if ("NVGoggles" in _items || {_x find "NVG" >= 0} count _items > 0) then {
            (_analysis get "equipment") pushBack "NVG";
            (_analysis get "capabilities") pushBack "NIGHT_OPS";
        };
        if ({_x find "Laserdesignator" >= 0} count _items > 0) then {
            (_analysis get "equipment") pushBack "LASER_DESIGNATOR";
            (_analysis get "capabilities") pushBack "JTAC";
        };
        if ({_x find "Rangefinder" >= 0} count _items > 0) then {
            (_analysis get "equipment") pushBack "RANGEFINDER";
        };
        if ({_x find "UAVTerminal" >= 0} count _items > 0) then {
            (_analysis get "equipment") pushBack "UAV_TERMINAL";
        };
        _analysis set ["damageStatus", 1 - (damage _unit)];

        _analysis
    }],

    // ========================================================================
    // VEHICLE ANALYSIS METHODS
    // ========================================================================

    // Classify vehicle type
    ["_classifyVehicle", {
        params ["_vehicle"];
        if (isNull _vehicle) exitWith { "UNKNOWN" };

        private _type = typeOf _vehicle;

        // Check inheritance chain for vehicle type
        if (_vehicle isKindOf "Tank") exitWith {
            // Distinguish MBT from IFV/APC
            private _cfgVeh = configFile >> "CfgVehicles" >> _type;
            private _armor = getNumber (_cfgVeh >> "armor");
            if (_armor > 400) then { "MBT" } else {
                // Check for troop transport capability
                private _cargo = getNumber (_cfgVeh >> "transportSoldier");
                if (_cargo >= 6) then { "APC" } else { "IFV" }
            }
        };

        if (_vehicle isKindOf "Wheeled_APC_F") exitWith { "APC" };
        if (_vehicle isKindOf "MRAP_01_base_F" || _vehicle isKindOf "MRAP_02_base_F" ||
            _vehicle isKindOf "MRAP_03_base_F") exitWith { "MRAP" };

        if (_vehicle isKindOf "Helicopter") exitWith {
            // Check for weapons to distinguish attack from transport
            private _weapons = weapons _vehicle;
            private _hasHeavyWeapons = {
                (_x find "cannon" >= 0) || (_x find "missiles" >= 0) ||
                (_x find "rockets" >= 0) || (_x find "Gatling" >= 0)
            } count _weapons > 0;
            if (_hasHeavyWeapons) then { "ATTACK_HELI" } else { "TRANSPORT_HELI" }
        };

        if (_vehicle isKindOf "Plane") exitWith {
            private _weapons = weapons _vehicle;
            private _hasAG = { (_x find "Bomb" >= 0) || (_x find "AGM" >= 0) } count _weapons > 0;
            if (_hasAG) then { "CAS_JET" } else { "FIGHTER_JET" }
        };

        if (_vehicle isKindOf "UAV") exitWith {
            if (_vehicle isKindOf "UAV_01_base_F") then { "UGAV" } else { "UAV" }
        };

        if (_vehicle isKindOf "Ship") exitWith { "BOAT" };

        if (_vehicle isKindOf "StaticWeapon") exitWith {
            private _weapons = weapons _vehicle;
            if ({_x find "AT" >= 0 || _x find "Titan" >= 0} count _weapons > 0) exitWith { "STATIC_AT" };
            if ({_x find "AA" >= 0} count _weapons > 0) exitWith { "STATIC_AA" };
            "STATIC_MG"
        };

        if (_vehicle isKindOf "Car") exitWith {
            if (count (weapons _vehicle) > 0) then { "CAR" } else { "TRUCK" }
        };

        if (_vehicle isKindOf "Truck_F") exitWith { "TRUCK" };

        "UNKNOWN"
    }],

    // Analyze a vehicle's capabilities using config values
    ["_analyzeVehicle", {
        params ["_vehicle"];
        if (isNull _vehicle) exitWith { nil };

        private _typeClass = typeOf _vehicle;
        private _type = _self call ["_classifyVehicle", [_vehicle]];
        private _cfgVeh = configFile >> "CfgVehicles" >> _typeClass;

        // Get config-based combat power from cost
        private _configCost = _self call ["_getConfigCost", [_typeClass]];

        // Get threat profile from config [soft, armor, air]
        private _threatProfile = _self call ["_getConfigThreat", [_typeClass]];

        // Get armor from config
        private _configArmor = _self call ["_getConfigArmor", [_typeClass]];

        // Get transport capacity
        private _configTransport = _self call ["_getConfigTransport", [_typeClass]];

        // Get max speed
        private _configSpeed = _self call ["_getConfigMaxSpeed", [_typeClass]];

        private _analysis = createHashMapFromArray [
            ["vehicle", _vehicle],
            ["typeClass", _typeClass],
            ["vehicleType", _type],
            ["combatPower", _configCost],
            ["threatVsSoft", _threatProfile select 0],
            ["threatVsArmor", _threatProfile select 1],
            ["threatVsAir", _threatProfile select 2],
            ["weapons", []],
            ["capabilities", []],
            ["maxPenetration", 0],
            ["maxDamage", 0],
            ["effectiveRange", 500],
            ["armor", createHashMap],
            ["sensors", []],
            ["mobility", createHashMap],
            ["crew", []],
            ["passengers", _configTransport],
            ["damageStatus", 1 - (damage _vehicle)],
            ["fuelStatus", fuel _vehicle]
        ];

        // Analyze all vehicle weapons using config
        private _allWeapons = _self call ["_getVehicleWeapons", [_typeClass]];
        private _maxPen = 0;
        private _maxDmg = 0;
        private _maxRange = 500;
        private _hasAT = false;
        private _hasAA = false;

        {
            private _weaponClass = _x;
            private _ammoAnalysis = _self call ["_analyzeWeaponAmmo", [_weaponClass]];
            _ammoAnalysis params ["_caliber", "_hit", "_indirectHit", "_range", "_isAA"];

            // Track best stats
            if (_caliber > _maxPen) then { _maxPen = _caliber };
            if (_hit > _maxDmg) then { _maxDmg = _hit };
            if (_range > _maxRange) then { _maxRange = _range };
            if (_isAA) then { _hasAA = true };

            // Classify weapon penetration
            private _penClass = _self call ["_classifyWeaponPenetration", [_caliber]];

            (_analysis get "weapons") pushBack [_weaponClass, _penClass, _caliber, _hit, _range];

            // Add capabilities based on config-derived penetration
            switch (_penClass) do {
                case "AT_HEAVY": {
                    _hasAT = true;
                    (_analysis get "capabilities") pushBackUnique "AT_HEAVY";
                    (_analysis get "capabilities") pushBackUnique "AT";
                };
                case "AT_LIGHT": {
                    _hasAT = true;
                    (_analysis get "capabilities") pushBackUnique "AT_LIGHT";
                    (_analysis get "capabilities") pushBackUnique "AT";
                };
                case "AUTOCANNON": {
                    (_analysis get "capabilities") pushBackUnique "AUTOCANNON";
                    (_analysis get "capabilities") pushBackUnique "ARMOR_PIERCING";
                };
                case "HMG": {
                    (_analysis get "capabilities") pushBackUnique "HMG";
                    (_analysis get "capabilities") pushBackUnique "SUPPRESS";
                };
            };

            // Check for area effect weapons (indirect hit)
            if (_indirectHit > 20) then {
                (_analysis get "capabilities") pushBackUnique "AREA_ATTACK";
            };
        } forEach _allWeapons;

        // Set AA capability from config threat value or weapon analysis
        if (_hasAA || (_threatProfile select 2) > 0.3) then {
            (_analysis get "capabilities") pushBackUnique "AA";
        };

        _analysis set ["maxPenetration", _maxPen];
        _analysis set ["maxDamage", _maxDmg];
        _analysis set ["effectiveRange", _maxRange];
        _analysis set ["canEngageArmor", _hasAT || _maxPen >= 15];
        _analysis set ["canEngageAir", _hasAA || (_threatProfile select 2) > 0.3];

        // Armor analysis from config
        (_analysis get "armor") set ["value", _configArmor];
        (_analysis get "armor") set ["class",
            if (_configArmor > 400) then { "HEAVY" } else {
                if (_configArmor > 100) then { "MEDIUM" } else {
                    if (_configArmor > 30) then { "LIGHT" } else { "NONE" }
                }
            }
        ];

        // Sensor analysis from config
        private _hasRadar = getNumber (_cfgVeh >> "receiveRemoteTargets") > 0;
        private _hasThermal = false;
        private _hasNV = false;

        // Check turrets for thermal/NV capability
        private _turrets = configProperties [_cfgVeh >> "Turrets", "isClass _x"];
        {
            // Check for thermal imaging
            private _thermalMode = getNumber (_x >> "turretInfoType") > 0;
            private _opticsConfig = _x >> "OpticsIn";
            if (isClass _opticsConfig) then {
                private _opticsModes = configProperties [_opticsConfig, "isClass _x"];
                {
                    private _visionMode = getArray (_x >> "visionMode");
                    if ("Ti" in _visionMode) then { _hasThermal = true };
                    if ("NVG" in _visionMode) then { _hasNV = true };
                } forEach _opticsModes;
            };
        } forEach _turrets;

        if (_hasRadar) then { (_analysis get "sensors") pushBack "RADAR" };
        if (_hasThermal) then { (_analysis get "sensors") pushBack "THERMAL" };
        if (_hasNV) then { (_analysis get "sensors") pushBack "NV" };

        // Mobility analysis from config
        (_analysis get "mobility") set ["maxSpeed", _configSpeed];
        (_analysis get "mobility") set ["isAmphibious",
            _vehicle isKindOf "Ship" || getNumber (_cfgVeh >> "canFloat") > 0];
        (_analysis get "mobility") set ["isAir", _vehicle isKindOf "Air"];

        // Crew
        _analysis set ["crew", crew _vehicle];

        _analysis
    }],

    // ========================================================================
    // GROUP ANALYSIS METHODS
    // ========================================================================

    // Analyze a group's combined capabilities (works with real groups or virtual group IDs)
    ["_analyzeGroup", {
        params ["_groupOrId"];

        // Check cache first
        private _cacheKey = format["group_%1", _groupOrId];
        private _cached = _self call ["_getCached", [_cacheKey]];
        if (!isNil "_cached") exitWith { _cached };

        private _analysis = createHashMapFromArray [
            ["groupId", _groupOrId],
            ["totalCombatPower", 0],
            ["unitCount", 0],
            ["vehicleCount", 0],
            ["capabilities", createHashMap],  // capability -> count
            ["specialists", createHashMap],   // specialization -> units
            ["vehicles", []],                 // vehicle analyses
            ["units", []],                    // unit analyses
            ["threatProfile", createHashMap], // threat type -> power
            ["effectiveRange", createHashMap], // range band -> power
            ["leadership", 0],                // leadership bonus
            ["cohesion", 1.0],               // group effectiveness
            ["position", [0,0,0]],
            ["canEngageArmor", false],
            ["canEngageAir", false],
            ["hasSupport", false],
            ["hasTransport", false]
        ];

        private _units = [];
        private _realGroup = grpNull;

        // Handle both real groups and virtual group IDs
        if (typeName _groupOrId == "GROUP") then {
            _realGroup = _groupOrId;
            _units = units _groupOrId;
            _analysis set ["position", getPos (leader _groupOrId)];
        } else {
            // Virtual group - get from virtualization system
            if (!isNil "FLO_virtualGroups") then {
                private _groups = FLO_virtualGroups get "_groups";
                private _gData = _groups getOrDefault [_groupOrId, nil];
                if (!isNil "_gData") then {
                    _analysis set ["position", _gData getOrDefault ["position", [0,0,0]]];
                    private _isActive = _gData getOrDefault ["isActive", false];
                    if (_isActive) then {
                        _realGroup = _gData getOrDefault ["realGroup", grpNull];
                        if (!isNull _realGroup) then {
                            _units = units _realGroup;
                        };
                    } else {
                        // Virtual group - calculate power from template using config
                        private _template = _gData getOrDefault ["template", []];
                        private _groupType = _gData getOrDefault ["groupType", "infantry"];
                        private _strength = _gData getOrDefault ["strength", 1.0];

                        // Calculate power from template unit classes using config
                        private _estPower = 0;
                        private _maxPenetration = 0;
                        private _maxThreatAir = 0;
                        private _canEngageArmor = false;
                        private _canEngageAir = false;
                        private _hasTransport = false;

                        {
                            private _typeClass = _x;
                            if (_typeClass isKindOf "CAManBase") then {
                                // Infantry - get cost from config
                                private _cost = _self call ["_getConfigCost", [_typeClass]];
                                private _threat = _self call ["_getConfigThreat", [_typeClass]];
                                _estPower = _estPower + _cost;

                                // Check if AT/AA capable from threat profile
                                if ((_threat select 1) > 0.3) then { _canEngageArmor = true };
                                if ((_threat select 2) > 0.3) then { _canEngageAir = true };
                            } else {
                                // Vehicle - get cost and analyze
                                private _cost = _self call ["_getConfigCost", [_typeClass]];
                                private _threat = _self call ["_getConfigThreat", [_typeClass]];
                                private _transport = _self call ["_getConfigTransport", [_typeClass]];
                                _estPower = _estPower + _cost;

                                if ((_threat select 1) > 0.3) then { _canEngageArmor = true };
                                if ((_threat select 2) > 0.3) then { _canEngageAir = true };
                                if (_transport > 4) then { _hasTransport = true };
                            };
                        } forEach _template;

                        _analysis set ["totalCombatPower", _estPower * _strength];
                        _analysis set ["unitCount", count _template];
                        _analysis set ["canEngageArmor", _canEngageArmor];
                        _analysis set ["canEngageAir", _canEngageAir];
                        _analysis set ["hasTransport", _hasTransport];

                        // Set capabilities from analysis
                        if (_canEngageArmor) then {
                            (_analysis get "capabilities") set ["AT", 1];
                        };
                        if (_canEngageAir) then {
                            (_analysis get "capabilities") set ["AA", 1];
                        };
                        if (_groupType in ["helicopter", "jet"]) then {
                            (_analysis get "capabilities") set ["AIR_POWER", 1];
                        };

                        _self call ["_setCache", [_cacheKey, _analysis]];
                        _analysis  // Return early for virtual groups
                    };
                };
            };
        };

        // Analyze each unit
        private _totalPower = 0;
        private _leadershipBonus = 0;
        private _capabilities = _analysis get "capabilities";
        private _specialists = _analysis get "specialists";

        {
            private _unit = _x;
            private _veh = vehicle _unit;

            if (_veh != _unit && alive _veh) then {
                // Unit is in a vehicle
                if !(_veh in ((_analysis get "vehicles") apply {_x get "vehicle"})) then {
                    private _vehAnalysis = _self call ["_analyzeVehicle", [_veh]];
                    if (!isNil "_vehAnalysis") then {
                        (_analysis get "vehicles") pushBack _vehAnalysis;
                        _analysis set ["vehicleCount", (_analysis get "vehicleCount") + 1];
                        _totalPower = _totalPower + (_vehAnalysis get "combatPower");

                        // Add vehicle capabilities
                        {
                            private _cap = _x;
                            _capabilities set [_cap, (_capabilities getOrDefault [_cap, 0]) + 1];
                        } forEach (_vehAnalysis get "capabilities");

                        // Check specific capabilities
                        if ("AT" in (_vehAnalysis get "capabilities") ||
                            "ARMOR_PIERCING" in (_vehAnalysis get "capabilities")) then {
                            _analysis set ["canEngageArmor", true];
                        };
                        if ("AA" in (_vehAnalysis get "capabilities")) then {
                            _analysis set ["canEngageAir", true];
                        };
                        if ((_vehAnalysis get "passengers") > 4) then {
                            _analysis set ["hasTransport", true];
                        };
                    };
                };
            } else {
                // Dismounted infantry
                private _unitAnalysis = _self call ["_analyzeUnit", [_unit]];
                if (!isNil "_unitAnalysis") then {
                    (_analysis get "units") pushBack _unitAnalysis;
                    _analysis set ["unitCount", (_analysis get "unitCount") + 1];
                    _totalPower = _totalPower + (_unitAnalysis get "combatPower");

                    // Track specialists
                    if (_unitAnalysis get "isSpecialist") then {
                        private _spec = _unitAnalysis get "specialization";
                        private _specList = _specialists getOrDefault [_spec, []];
                        _specList pushBack _unit;
                        _specialists set [_spec, _specList];
                    };

                    // Add capabilities
                    {
                        private _cap = _x;
                        _capabilities set [_cap, (_capabilities getOrDefault [_cap, 0]) + 1];
                    } forEach (_unitAnalysis get "capabilities");

                    // Check specific capabilities
                    if ("AT" in (_unitAnalysis get "capabilities")) then {
                        _analysis set ["canEngageArmor", true];
                    };
                    if ("AA" in (_unitAnalysis get "capabilities")) then {
                        _analysis set ["canEngageAir", true];
                    };
                    if ("MEDICAL" in (_unitAnalysis get "capabilities") ||
                        "REPAIR" in (_unitAnalysis get "capabilities")) then {
                        _analysis set ["hasSupport", true];
                    };

                    // Leadership bonus
                    if ("LEADERSHIP" in (_unitAnalysis get "capabilities")) then {
                        _leadershipBonus = _leadershipBonus + 0.1;
                    };
                };
            };
        } forEach _units;

        // Apply leadership bonus
        _analysis set ["leadership", _leadershipBonus];
        _totalPower = _totalPower * (1 + _leadershipBonus);
        _analysis set ["totalCombatPower", _totalPower];

        // Calculate threat profile
        private _threatProfile = _analysis get "threatProfile";
        if (_analysis get "canEngageArmor") then {
            _threatProfile set ["ANTI_ARMOR", _totalPower * 0.3];
        };
        if (_analysis get "canEngageAir") then {
            _threatProfile set ["ANTI_AIR", _totalPower * 0.25];
        };
        _threatProfile set ["ANTI_INFANTRY", _totalPower * 0.5];

        // Cache and return
        _self call ["_setCache", [_cacheKey, _analysis]];
        _analysis
    }],

    // ========================================================================
    // THREAT ASSESSMENT METHODS
    // ========================================================================

    // Calculate threat one group poses to another using config-based analysis
    ["_assessThreat", {
        params ["_attackerGroupId", "_defenderGroupId"];

        private _attackerAnalysis = _self call ["_analyzeGroup", [_attackerGroupId]];
        private _defenderAnalysis = _self call ["_analyzeGroup", [_defenderGroupId]];

        if (isNil "_attackerAnalysis" || isNil "_defenderAnalysis") exitWith {
            createHashMapFromArray [["threat", 0], ["canEngage", false], ["effectiveness", 0]]
        };

        // Get aggregated threat values from unit/vehicle analyses
        private _atkThreatSoft = 0;
        private _atkThreatArmor = 0;
        private _atkThreatAir = 0;
        private _atkMaxPen = 0;

        // Sum threat values from all units and vehicles
        {
            _atkThreatSoft = _atkThreatSoft + (_x getOrDefault ["threatVsSoft", 0.5]);
            _atkThreatArmor = _atkThreatArmor + (_x getOrDefault ["threatVsArmor", 0]);
            _atkThreatAir = _atkThreatAir + (_x getOrDefault ["threatVsAir", 0]);
            _atkMaxPen = _atkMaxPen max (_x getOrDefault ["maxPenetration", 0]);
        } forEach (_attackerAnalysis get "units");

        {
            _atkThreatSoft = _atkThreatSoft + (_x getOrDefault ["threatVsSoft", 0.5]);
            _atkThreatArmor = _atkThreatArmor + (_x getOrDefault ["threatVsArmor", 0]);
            _atkThreatAir = _atkThreatAir + (_x getOrDefault ["threatVsAir", 0]);
            _atkMaxPen = _atkMaxPen max (_x getOrDefault ["maxPenetration", 0]);
        } forEach (_attackerAnalysis get "vehicles");

        // Analyze defender composition
        private _defArmorValue = 0;
        private _defIsAir = false;
        private _defInfCount = count (_defenderAnalysis get "units");

        {
            private _armor = (_x get "armor") getOrDefault ["value", 0];
            _defArmorValue = _defArmorValue max _armor;
            if ((_x get "mobility") getOrDefault ["isAir", false]) then { _defIsAir = true };
        } forEach (_defenderAnalysis get "vehicles");

        private _threat = createHashMapFromArray [
            ["attackerPower", _attackerAnalysis get "totalCombatPower"],
            ["defenderPower", _defenderAnalysis get "totalCombatPower"],
            ["attackerMaxPenetration", _atkMaxPen],
            ["defenderMaxArmor", _defArmorValue],
            ["ratio", 0],
            ["canEngageArmor", _attackerAnalysis get "canEngageArmor"],
            ["canEngageAir", _attackerAnalysis get "canEngageAir"],
            ["effectivenessVsInfantry", _atkThreatSoft / ((_defInfCount max 1) * 0.5)],
            ["effectivenessVsArmor", 0.0],
            ["effectivenessVsAir", 0.0],
            ["overallEffectiveness", 0.5],
            ["recommendedApproach", "DIRECT"]
        ];

        private _atkPower = _attackerAnalysis get "totalCombatPower";
        private _defPower = _defenderAnalysis get "totalCombatPower";

        if (_defPower > 0) then {
            _threat set ["ratio", _atkPower / _defPower];
        } else {
            _threat set ["ratio", 10];
        };

        // Calculate effectiveness vs armor using config values
        // Compare attacker max penetration vs defender armor
        private _defHasArmor = _defArmorValue > 30;
        if (_defHasArmor) then {
            // Effectiveness based on penetration vs armor
            // Caliber of 40+ can defeat heavy armor (400+)
            // Caliber of 15+ can defeat medium armor (100-400)
            // Caliber of 6+ can defeat light armor (30-100)
            private _penRatio = _atkMaxPen / ((_defArmorValue / 10) max 1);
            private _effVsArmor = (_penRatio min 1.0);
            _threat set ["effectivenessVsArmor", _effVsArmor];
        };

        // Effectiveness vs air
        if (_defIsAir) then {
            if (_attackerAnalysis get "canEngageAir") then {
                _threat set ["effectivenessVsAir", _atkThreatAir min 1.0];
            } else {
                _threat set ["effectivenessVsAir", 0.05];
            };
        };

        // Calculate overall effectiveness
        private _overallEff = 0.5;

        // Penalty if defender has armor we can't penetrate
        if (_defHasArmor) then {
            private _effVsArmor = _threat get "effectivenessVsArmor";
            if (_effVsArmor < 0.3) then {
                _overallEff = _overallEff * (0.2 + _effVsArmor);
            } else {
                _overallEff = _overallEff * (0.5 + _effVsArmor * 0.5);
            };
        };

        // Force ratio modifiers
        private _ratio = _threat get "ratio";
        if (_ratio > 3) then {
            _overallEff = _overallEff * 1.5;
        };
        if (_ratio < 0.5) then {
            _overallEff = _overallEff * 0.5;
        };

        _threat set ["overallEffectiveness", _overallEff min 1.0];

        // Recommend approach based on analysis
        if (_ratio > 3 && _overallEff > 0.6) then {
            _threat set ["recommendedApproach", "ASSAULT"];
        } else {
            if (_ratio < 1 || _overallEff < 0.4) then {
                _threat set ["recommendedApproach", "AVOID"];
            } else {
                _threat set ["recommendedApproach", "CAUTIOUS"];
            };
        };

        _threat
    }],

    // Estimate outcome of engagement using config-based analysis
    ["_predictEngagement", {
        params ["_attackerGroups", "_defenderGroups", ["_terrain", "OPEN"], ["_defenderDug", false]];

        private _prediction = createHashMapFromArray [
            ["attackerTotalPower", 0],
            ["defenderTotalPower", 0],
            ["attackerMaxPenetration", 0],
            ["defenderMaxArmor", 0],
            ["ratio", 0],
            ["attackerCasualties", 0],
            ["defenderCasualties", 0],
            ["outcome", "UNCERTAIN"],
            ["confidence", 0.5],
            ["timeToResolve", 600],
            ["recommendations", []]
        ];

        // Aggregate attacker power and capabilities
        private _atkPower = 0;
        private _atkCanAT = false;
        private _atkCanAA = false;
        private _atkMaxPen = 0;

        {
            private _analysis = _self call ["_analyzeGroup", [_x]];
            if (!isNil "_analysis") then {
                _atkPower = _atkPower + (_analysis get "totalCombatPower");
                if (_analysis get "canEngageArmor") then { _atkCanAT = true };
                if (_analysis get "canEngageAir") then { _atkCanAA = true };

                // Track max penetration from units and vehicles
                {
                    _atkMaxPen = _atkMaxPen max (_x getOrDefault ["maxPenetration", 0]);
                } forEach (_analysis get "units");
                {
                    _atkMaxPen = _atkMaxPen max (_x getOrDefault ["maxPenetration", 0]);
                } forEach (_analysis get "vehicles");
            };
        } forEach _attackerGroups;

        // Aggregate defender power and armor values
        private _defPower = 0;
        private _defMaxArmor = 0;
        private _defHasAir = false;

        {
            private _analysis = _self call ["_analyzeGroup", [_x]];
            if (!isNil "_analysis") then {
                private _power = _analysis get "totalCombatPower";

                // Terrain and posture modifiers for defender
                if (_defenderDug) then { _power = _power * 1.5 };
                switch (_terrain) do {
                    case "URBAN": { _power = _power * 1.4 };
                    case "FOREST": { _power = _power * 1.2 };
                    case "HILLS": { _power = _power * 1.3 };
                };

                _defPower = _defPower + _power;

                // Track max armor from vehicles
                {
                    private _armor = (_x get "armor") getOrDefault ["value", 0];
                    _defMaxArmor = _defMaxArmor max _armor;
                    if ((_x get "mobility") getOrDefault ["isAir", false]) then {
                        _defHasAir = true;
                    };
                } forEach (_analysis get "vehicles");
            };
        } forEach _defenderGroups;

        _prediction set ["attackerTotalPower", _atkPower];
        _prediction set ["defenderTotalPower", _defPower];
        _prediction set ["attackerMaxPenetration", _atkMaxPen];
        _prediction set ["defenderMaxArmor", _defMaxArmor];

        // Check if attacker can penetrate defender armor
        private _defHasArmor = _defMaxArmor > 30;

        // Calculate effective power with penetration-based adjustment
        private _effectiveAtkPower = _atkPower;
        if (_defHasArmor) then {
            // Check if attacker has AT capability
            if (!_atkCanAT) then {
                _effectiveAtkPower = _effectiveAtkPower * 0.2;
                (_prediction get "recommendations") pushBack "NEED_AT_SUPPORT";
            } else {
                // Calculate penetration effectiveness
                // Rough rule: need caliber ~= armor/10 to penetrate
                private _penRatio = _atkMaxPen / ((_defMaxArmor / 10) max 1);
                if (_penRatio < 0.5) then {
                    _effectiveAtkPower = _effectiveAtkPower * 0.4;
                    (_prediction get "recommendations") pushBack "NEED_HEAVIER_AT";
                } else {
                    if (_penRatio < 1.0) then {
                        _effectiveAtkPower = _effectiveAtkPower * 0.7;
                    };
                };
            };
        };

        // Air target adjustment
        if (_defHasAir && !_atkCanAA) then {
            _effectiveAtkPower = _effectiveAtkPower * 0.5;
            (_prediction get "recommendations") pushBack "NEED_AA_SUPPORT";
        };

        if (_defPower > 0) then {
            _prediction set ["ratio", _effectiveAtkPower / _defPower];
        } else {
            _prediction set ["ratio", 10];
        };

        private _ratio = _prediction get "ratio";

        // Predict outcome
        if (_ratio > 3) then {
            _prediction set ["outcome", "ATTACKER_DECISIVE"];
            _prediction set ["attackerCasualties", 0.1];
            _prediction set ["defenderCasualties", 0.9];
            _prediction set ["confidence", 0.8];
            _prediction set ["timeToResolve", 300];
        } else {
            if (_ratio > 2) then {
                _prediction set ["outcome", "ATTACKER_VICTORY"];
                _prediction set ["attackerCasualties", 0.25];
                _prediction set ["defenderCasualties", 0.7];
                _prediction set ["confidence", 0.7];
            } else {
                if (_ratio > 1.5) then {
                    _prediction set ["outcome", "ATTACKER_MARGINAL"];
                    _prediction set ["attackerCasualties", 0.4];
                    _prediction set ["defenderCasualties", 0.5];
                    _prediction set ["confidence", 0.55];
                } else {
                    if (_ratio > 0.8) then {
                        _prediction set ["outcome", "CONTESTED"];
                        _prediction set ["attackerCasualties", 0.5];
                        _prediction set ["defenderCasualties", 0.4];
                        _prediction set ["confidence", 0.4];
                        (_prediction get "recommendations") pushBack "REINFORCE";
                    } else {
                        _prediction set ["outcome", "DEFENDER_ADVANTAGE"];
                        _prediction set ["attackerCasualties", 0.7];
                        _prediction set ["defenderCasualties", 0.25];
                        _prediction set ["confidence", 0.6];
                        (_prediction get "recommendations") pushBack "ABORT_OR_REINFORCE";
                    };
                };
            };
        };

        _prediction
    }],

    // ========================================================================
    // FORCE COMPOSITION AND COUNTERFORCE
    // ========================================================================

    // Find groups with specific capability
    ["_findGroupsWithCapability", {
        params ["_capability", ["_side", east]];

        private _result = [];
        if (isNil "FLO_virtualGroups") exitWith { _result };

        private _groups = FLO_virtualGroups get "_groups";
        {
            private _gId = _x;
            private _gData = _y;

            if ((_gData getOrDefault ["side", east]) != _side) then { continue };

            private _analysis = _self call ["_analyzeGroup", [_gId]];
            if (isNil "_analysis") then { continue };

            private _caps = _analysis get "capabilities";
            if (_capability in (keys _caps)) then {
                _result pushBack [_gId, _analysis, _caps get _capability];
            };
        } forEach _groups;

        // Sort by capability count (descending)
        _result = [_result, [], {_x select 2}, "DESCEND"] call BIS_fnc_sortBy;
        _result
    }],

    // Recommend counter-force for a target
    ["_recommendCounterforce", {
        params ["_targetGroupId", ["_availableGroups", []], ["_maxGroups", 4]];

        private _targetAnalysis = _self call ["_analyzeGroup", [_targetGroupId]];
        if (isNil "_targetAnalysis") exitWith { [] };

        private _targetPower = _targetAnalysis get "totalCombatPower";
        private _targetHasArmor = (_targetAnalysis get "vehicleCount") > 0;
        private _targetHasAir = false;

        // Check target vehicle types
        {
            private _vehType = _x get "vehicleType";
            if (_vehType in ["ATTACK_HELI", "TRANSPORT_HELI", "CAS_JET", "FIGHTER_JET"]) then {
                _targetHasAir = true;
            };
        } forEach (_targetAnalysis get "vehicles");

        private _recommendation = createHashMapFromArray [
            ["targetPower", _targetPower],
            ["requiredPower", _targetPower * 3],  // 3:1 ratio
            ["requiredAT", _targetHasArmor],
            ["requiredAA", _targetHasAir],
            ["selectedGroups", []],
            ["totalPower", 0],
            ["meetsRequirements", false],
            ["shortfalls", []]
        ];

        // Score and sort available groups
        private _scoredGroups = [];
        {
            private _gId = _x;
            private _analysis = _self call ["_analyzeGroup", [_gId]];
            if (isNil "_analysis") then { continue };

            private _power = _analysis get "totalCombatPower";
            private _score = _power;

            // Bonus for required capabilities
            if (_targetHasArmor && (_analysis get "canEngageArmor")) then {
                _score = _score * 1.5;
            };
            if (_targetHasAir && (_analysis get "canEngageAir")) then {
                _score = _score * 1.5;
            };

            // Penalty for distant groups
            private _distance = (_analysis get "position") distance2D (_targetAnalysis get "position");
            _score = _score - (_distance / 100);

            _scoredGroups pushBack [_gId, _analysis, _score];
        } forEach _availableGroups;

        _scoredGroups = [_scoredGroups, [], {_x select 2}, "DESCEND"] call BIS_fnc_sortBy;

        // Select groups until requirements met
        private _selectedPower = 0;
        private _hasAT = false;
        private _hasAA = false;

        {
            if (count (_recommendation get "selectedGroups") >= _maxGroups) exitWith {};

            private _gId = _x select 0;
            private _analysis = _x select 1;

            (_recommendation get "selectedGroups") pushBack _gId;
            _selectedPower = _selectedPower + (_analysis get "totalCombatPower");

            if (_analysis get "canEngageArmor") then { _hasAT = true };
            if (_analysis get "canEngageAir") then { _hasAA = true };

            // Check if requirements met
            if (_selectedPower >= (_recommendation get "requiredPower") &&
                (!(_recommendation get "requiredAT") || _hasAT) &&
                (!(_recommendation get "requiredAA") || _hasAA)) exitWith {
                _recommendation set ["meetsRequirements", true];
            };
        } forEach _scoredGroups;

        _recommendation set ["totalPower", _selectedPower];

        // Identify shortfalls
        if (_selectedPower < (_recommendation get "requiredPower")) then {
            (_recommendation get "shortfalls") pushBack format["Need %1 more combat power",
                (_recommendation get "requiredPower") - _selectedPower];
        };
        if ((_recommendation get "requiredAT") && !_hasAT) then {
            (_recommendation get "shortfalls") pushBack "Missing AT capability";
        };
        if ((_recommendation get "requiredAA") && !_hasAA) then {
            (_recommendation get "shortfalls") pushBack "Missing AA capability";
        };

        _recommendation
    }],

    // Get optimal force mix for objective type
    ["_getOptimalForceMix", {
        params ["_objectiveType", ["_targetPower", 100]];

        // Define optimal ratios for different objectives
        private _mixes = createHashMapFromArray [
            ["capital", createHashMapFromArray [
                ["infantry", 0.4], ["mechanized", 0.3], ["armor", 0.2], ["artillery", 0.1]
            ]],
            ["city", createHashMapFromArray [
                ["infantry", 0.5], ["mechanized", 0.3], ["armor", 0.15], ["artillery", 0.05]
            ]],
            ["village", createHashMapFromArray [
                ["infantry", 0.6], ["motorized", 0.3], ["armor", 0.1]
            ]],
            ["airfield", createHashMapFromArray [
                ["infantry", 0.3], ["mechanized", 0.3], ["armor", 0.2], ["aa", 0.2]
            ]],
            ["harbor", createHashMapFromArray [
                ["infantry", 0.4], ["mechanized", 0.3], ["armor", 0.2], ["naval", 0.1]
            ]],
            ["fob", createHashMapFromArray [
                ["infantry", 0.5], ["mechanized", 0.25], ["armor", 0.15], ["artillery", 0.1]
            ]]
        ];

        private _mix = _mixes getOrDefault [_objectiveType, createHashMapFromArray [
            ["infantry", 0.5], ["mechanized", 0.3], ["armor", 0.2]
        ]];

        // Calculate required power per type
        private _requiredPower = _targetPower * 3;  // 3:1 ratio
        private _result = createHashMap;

        {
            _result set [_x, _requiredPower * (_mix get _x)];
        } forEach (keys _mix);

        _result
    }],

    // ========================================================================
    // READINESS AND OBJECTIVE ANALYSIS
    // ========================================================================

    // Get force readiness (ammo, fuel, damage status)
    ["_getForceReadiness", {
        params ["_groupIds"];

        private _readiness = createHashMapFromArray [
            ["overall", 1.0],
            ["combat", 1.0],
            ["supply", 1.0],
            ["groups", createHashMap],
            ["issues", []]
        ];

        private _totalCombat = 0;
        private _totalSupply = 0;
        private _groupCount = 0;

        {
            private _gId = _x;
            private _analysis = _self call ["_analyzeGroup", [_gId]];
            if (isNil "_analysis") then { continue };

            private _groupReadiness = createHashMapFromArray [
                ["combat", 1.0],
                ["ammo", 1.0],
                ["fuel", 1.0],
                ["damage", 1.0]
            ];

            // Check unit damage
            private _totalDamage = 0;
            private _unitCount = 0;
            {
                _totalDamage = _totalDamage + (_x get "damageStatus");
                _unitCount = _unitCount + 1;
            } forEach (_analysis get "units");

            if (_unitCount > 0) then {
                _groupReadiness set ["damage", _totalDamage / _unitCount];
            };

            // Check vehicle status
            private _totalFuel = 0;
            private _vehCount = 0;
            {
                _totalFuel = _totalFuel + (_x get "fuelStatus");
                _totalDamage = _totalDamage + (_x get "damageStatus");
                _vehCount = _vehCount + 1;
            } forEach (_analysis get "vehicles");

            if (_vehCount > 0) then {
                _groupReadiness set ["fuel", _totalFuel / _vehCount];
            };

            // Calculate combat readiness
            private _combatReady = (_groupReadiness get "damage") *
                                   ((_groupReadiness get "fuel") max 0.5);
            _groupReadiness set ["combat", _combatReady];

            (_readiness get "groups") set [_gId, _groupReadiness];

            _totalCombat = _totalCombat + _combatReady;
            _groupCount = _groupCount + 1;

            // Log issues
            if (_combatReady < 0.5) then {
                (_readiness get "issues") pushBack format["%1: Low readiness (%2)", _gId, _combatReady];
            };
        } forEach _groupIds;

        if (_groupCount > 0) then {
            _readiness set ["combat", _totalCombat / _groupCount];
            _readiness set ["overall", _totalCombat / _groupCount];
        };

        _readiness
    }],

    // Analyze an objective's defensive strength
    ["_analyzeObjective", {
        params ["_objectiveId"];

        if (isNil "FLO_Objectives") exitWith { nil };

        private _obj = FLO_Objectives getOrDefault [_objectiveId, nil];
        if (isNil "_obj") exitWith { nil };

        private _analysis = createHashMapFromArray [
            ["objectiveId", _objectiveId],
            ["position", _obj getOrDefault ["position", [0,0,0]]],
            ["type", _obj getOrDefault ["type", "unknown"]],
            ["subType", _obj getOrDefault ["subType", ""]],
            ["radius", _obj getOrDefault ["radius", 100]],
            ["garrison", []],
            ["totalDefensePower", 0],
            ["hasArmor", false],
            ["hasAA", false],
            ["hasStatic", false],
            ["fortificationLevel", 0],
            ["approachDifficulty", "NORMAL"],
            ["recommendedAttackForce", 0]
        ];

        private _pos = _analysis get "position";
        private _radius = _analysis get "radius";

        // Find garrison groups
        if (!isNil "FLO_virtualGroups") then {
            private _groups = FLO_virtualGroups get "_groups";
            {
                private _gId = _x;
                private _gData = _y;
                private _gPos = _gData getOrDefault ["position", [0,0,0]];

                if (_gPos distance2D _pos < _radius * 1.5) then {
                    private _gAnalysis = _self call ["_analyzeGroup", [_gId]];
                    if (!isNil "_gAnalysis") then {
                        (_analysis get "garrison") pushBack [_gId, _gAnalysis];
                        _analysis set ["totalDefensePower",
                            (_analysis get "totalDefensePower") + (_gAnalysis get "totalCombatPower")];

                        if (_gAnalysis get "canEngageArmor") then {
                            _analysis set ["hasArmor", true];
                        };
                        if (_gAnalysis get "canEngageAir") then {
                            _analysis set ["hasAA", true];
                        };
                        if ((_gAnalysis get "vehicleCount") > 0) then {
                            _analysis set ["hasStatic", true];
                        };
                    };
                };
            } forEach _groups;
        };

        // Terrain analysis for approach
        private _objType = _analysis get "type";
        switch (_objType) do {
            case "capital": {
                _analysis set ["approachDifficulty", "HARD"];
                _analysis set ["fortificationLevel", 3];
            };
            case "city": {
                _analysis set ["approachDifficulty", "HARD"];
                _analysis set ["fortificationLevel", 2];
            };
            case "village": {
                _analysis set ["approachDifficulty", "NORMAL"];
                _analysis set ["fortificationLevel", 1];
            };
            case "fob": {
                _analysis set ["approachDifficulty", "HARD"];
                _analysis set ["fortificationLevel", 3];
            };
        };

        // Calculate recommended attack force
        private _basePower = _analysis get "totalDefensePower";
        private _fortMult = 1 + ((_analysis get "fortificationLevel") * 0.25);
        private _terrainMult = switch (_analysis get "approachDifficulty") do {
            case "HARD": { 1.5 };
            case "NORMAL": { 1.2 };
            default { 1.0 };
        };

        _analysis set ["recommendedAttackForce", _basePower * 3 * _fortMult * _terrainMult];

        _analysis
    }],

    // ========================================================================
    // MISSION FEASIBILITY AND HIGH-LEVEL QUERIES
    // ========================================================================

    // Check if a mission type is feasible with available assets
    ["_canExecuteMission", {
        params ["_missionType", ["_targetPos", [0,0,0]], ["_requiredPower", 0]];

        private _result = createHashMapFromArray [
            ["feasible", false],
            ["reason", ""],
            ["availableAssets", []],
            ["powerAvailable", 0],
            ["powerRequired", _requiredPower]
        ];

        if (isNil "FLO_virtualGroups") exitWith {
            _result set ["reason", "No virtualization system"];
            _result
        };

        private _groups = FLO_virtualGroups get "_groups";

        switch (toUpper _missionType) do {
            case "CAS": {
                // Need attack helicopter or CAS jet
                {
                    private _gData = _y;
                    private _gType = _gData getOrDefault ["groupType", ""];
                    if (_gType in ["helicopter", "jet"]) then {
                        if !(_gData getOrDefault ["onMission", false]) then {
                            (_result get "availableAssets") pushBack _x;
                        };
                    };
                } forEach _groups;

                if (count (_result get "availableAssets") > 0) then {
                    _result set ["feasible", true];
                } else {
                    _result set ["reason", "No air assets available"];
                };
            };

            case "ARTILLERY": {
                // Check artillery asset manager
                if (!isNil "FLO_GTNArtilleryManager") then {
                    private _batteries = FLO_GTNArtilleryManager call ["_getAvailableBatteries", []];
                    if (count _batteries > 0) then {
                        _result set ["feasible", true];
                        _result set ["availableAssets", _batteries];
                    } else {
                        _result set ["reason", "No artillery batteries available"];
                    };
                } else {
                    _result set ["reason", "Artillery system not initialized"];
                };
            };

            case "ASSAULT": {
                // Need sufficient ground forces
                private _totalPower = 0;
                {
                    private _gData = _y;
                    private _gType = _gData getOrDefault ["groupType", ""];
                    if (_gType in ["infantry", "motorized", "mechanized", "armor"]) then {
                        if !(_gData getOrDefault ["onMission", false]) then {
                            private _analysis = _self call ["_analyzeGroup", [_x]];
                            if (!isNil "_analysis") then {
                                _totalPower = _totalPower + (_analysis get "totalCombatPower");
                                (_result get "availableAssets") pushBack _x;
                            };
                        };
                    };
                } forEach _groups;

                _result set ["powerAvailable", _totalPower];
                if (_totalPower >= _requiredPower) then {
                    _result set ["feasible", true];
                } else {
                    _result set ["reason", format["Insufficient power: %1/%2", _totalPower, _requiredPower]];
                };
            };

            case "DEFENSE": {
                // Any available forces can defend
                {
                    private _gData = _y;
                    if !(_gData getOrDefault ["onMission", false]) then {
                        (_result get "availableAssets") pushBack _x;
                    };
                } forEach _groups;

                if (count (_result get "availableAssets") > 0) then {
                    _result set ["feasible", true];
                } else {
                    _result set ["reason", "No forces available"];
                };
            };

            case "RECON": {
                // Need UAV or recon infantry
                {
                    private _gData = _y;
                    private _gType = _gData getOrDefault ["groupType", ""];
                    if (_gType in ["uav", "recon"]) then {
                        if !(_gData getOrDefault ["onMission", false]) then {
                            (_result get "availableAssets") pushBack _x;
                        };
                    };
                } forEach _groups;

                if (count (_result get "availableAssets") > 0) then {
                    _result set ["feasible", true];
                } else {
                    _result set ["reason", "No recon assets available"];
                };
            };

            default {
                _result set ["reason", format["Unknown mission type: %1", _missionType]];
            };
        };

        _result
    }],

    // Get overall force summary
    ["_getForcesSummary", {
        params [["_side", east]];

        private _summary = createHashMapFromArray [
            ["totalGroups", 0],
            ["activeGroups", 0],
            ["totalCombatPower", 0],
            ["byType", createHashMap],
            ["capabilities", createHashMap],
            ["averageReadiness", 1.0],
            ["groupsOnMission", 0],
            ["groupsAvailable", 0]
        ];

        if (isNil "FLO_virtualGroups") exitWith { _summary };

        private _groups = FLO_virtualGroups get "_groups";
        private _allGroupIds = [];

        {
            private _gId = _x;
            private _gData = _y;

            if ((_gData getOrDefault ["side", east]) != _side) then { continue };

            _summary set ["totalGroups", (_summary get "totalGroups") + 1];
            _allGroupIds pushBack _gId;

            private _gType = _gData getOrDefault ["groupType", "unknown"];
            private _byType = _summary get "byType";
            _byType set [_gType, (_byType getOrDefault [_gType, 0]) + 1];

            if (_gData getOrDefault ["isActive", false]) then {
                _summary set ["activeGroups", (_summary get "activeGroups") + 1];
            };

            if (_gData getOrDefault ["onMission", false]) then {
                _summary set ["groupsOnMission", (_summary get "groupsOnMission") + 1];
            } else {
                _summary set ["groupsAvailable", (_summary get "groupsAvailable") + 1];
            };

            // Analyze group capabilities
            private _analysis = _self call ["_analyzeGroup", [_gId]];
            if (!isNil "_analysis") then {
                _summary set ["totalCombatPower",
                    (_summary get "totalCombatPower") + (_analysis get "totalCombatPower")];

                // Aggregate capabilities
                {
                    private _cap = _x;
                    private _count = _y;
                    private _caps = _summary get "capabilities";
                    _caps set [_cap, (_caps getOrDefault [_cap, 0]) + _count];
                } forEach (_analysis get "capabilities");
            };
        } forEach _groups;

        // Get overall readiness
        private _readiness = _self call ["_getForceReadiness", [_allGroupIds]];
        _summary set ["averageReadiness", _readiness get "overall"];

        _summary
    }],

    // Clear analysis cache (for when units/vehicles change significantly)
    ["_clearCache", {
        _self set ["_analysisCache", createHashMap];
        ["GTN Capability Analyzer", 4, "Analysis cache cleared"] call FLO_fnc_log;
    }],

    // Debug: Log detailed analysis of a group
    ["_debugAnalyzeGroup", {
        params ["_groupId"];

        private _analysis = _self call ["_analyzeGroup", [_groupId]];
        if (isNil "_analysis") exitWith {
            ["GTN Capability Analyzer", 2, format["Debug: No analysis for %1", _groupId]] call FLO_fnc_log;
        };

        ["GTN Capability Analyzer", 3, format["=== Group Analysis: %1 ===", _groupId]] call FLO_fnc_log;
        ["GTN Capability Analyzer", 3, format["  Combat Power: %1 (from config cost)", _analysis get "totalCombatPower"]] call FLO_fnc_log;
        ["GTN Capability Analyzer", 3, format["  Units: %1, Vehicles: %2",
            _analysis get "unitCount", _analysis get "vehicleCount"]] call FLO_fnc_log;
        ["GTN Capability Analyzer", 3, format["  Can Engage Armor: %1, Air: %2",
            _analysis get "canEngageArmor", _analysis get "canEngageAir"]] call FLO_fnc_log;
        ["GTN Capability Analyzer", 3, format["  Capabilities: %1", keys (_analysis get "capabilities")]] call FLO_fnc_log;
        ["GTN Capability Analyzer", 3, format["  Specialists: %1", keys (_analysis get "specialists")]] call FLO_fnc_log;

        // Log unit details
        {
            private _maxPen = _x getOrDefault ["maxPenetration", 0];
            private _role = _x getOrDefault ["role", "UNKNOWN"];
            private _cost = _x getOrDefault ["combatPower", 0];
            ["GTN Capability Analyzer", 4, format["  Unit: %1 | Role: %2 | Pen: %3 | Power: %4",
                _x get "typeClass", _role, _maxPen, _cost]] call FLO_fnc_log;
        } forEach (_analysis get "units");

        // Log vehicle details
        {
            private _maxPen = _x getOrDefault ["maxPenetration", 0];
            private _armor = (_x get "armor") getOrDefault ["value", 0];
            private _cost = _x getOrDefault ["combatPower", 0];
            ["GTN Capability Analyzer", 4, format["  Vehicle: %1 | Armor: %2 | MaxPen: %3 | Power: %4",
                _x get "typeClass", _armor, _maxPen, _cost]] call FLO_fnc_log;
        } forEach (_analysis get "vehicles");
    }],

    // Debug: Analyze a specific unit/vehicle class from config
    ["_debugAnalyzeClass", {
        params ["_typeClass"];

        private _cost = _self call ["_getConfigCost", [_typeClass]];
        private _threat = _self call ["_getConfigThreat", [_typeClass]];
        private _armor = _self call ["_getConfigArmor", [_typeClass]];
        private _speed = _self call ["_getConfigMaxSpeed", [_typeClass]];
        private _transport = _self call ["_getConfigTransport", [_typeClass]];
        private _weapons = _self call ["_getVehicleWeapons", [_typeClass]];

        ["GTN Capability Analyzer", 3, format["=== Class Analysis: %1 ===", _typeClass]] call FLO_fnc_log;
        ["GTN Capability Analyzer", 3, format["  Cost (Power): %1", _cost]] call FLO_fnc_log;
        ["GTN Capability Analyzer", 3, format["  Threat [Soft,Armor,Air]: %1", _threat]] call FLO_fnc_log;
        ["GTN Capability Analyzer", 3, format["  Armor Value: %1", _armor]] call FLO_fnc_log;
        ["GTN Capability Analyzer", 3, format["  Max Speed: %1 | Transport: %2", _speed, _transport]] call FLO_fnc_log;

        // Analyze each weapon
        {
            private _ammoData = _self call ["_analyzeWeaponAmmo", [_x]];
            _ammoData params ["_caliber", "_hit", "_indirectHit", "_range", "_isAA"];
            private _penClass = _self call ["_classifyWeaponPenetration", [_caliber]];
            ["GTN Capability Analyzer", 4, format["  Weapon: %1 | Cal: %2 (%3) | Hit: %4 | Range: %5",
                _x, _caliber, _penClass, _hit, _range]] call FLO_fnc_log;
        } forEach _weapons;
    }]
]];

["GTN Capability Analyzer", 2, "Heavyweight Capability Analyzer initialized"] call FLO_fnc_log;

FLO_GTN_CapabilityAnalyzer