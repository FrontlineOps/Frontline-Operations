/*
    Function: FLO_fnc_harvestFactionGear
    
    Description:
        Harvests all weapons, items, magazines, uniforms, vests, and backpacks 
        from the defined player faction units.
        
    Returns:
        Array - List of all unique classnames
*/

private _harvestedGear = [];
private _processedUnits = [];
private _candidateUnitClasses = [];
private _catalogUnitCount = 0;
private _legacyUnitCount = 0;

// Helper to extract items from a container class (like a pre-configured backpack)
private _fnc_processContainer = {
    params ["_containerClass"];
    
    if (_containerClass == "") exitWith {};
    
    private _cfgContent = configFile >> "CfgVehicles" >> _containerClass;
    if (!isClass _cfgContent) exitWith {};
    
    // TransportMagazines
    private _transportMagazines = "true" configClasses (_cfgContent >> "TransportMagazines");
    {
        _harvestedGear pushBack (getText (_x >> "magazine"));
    } forEach _transportMagazines;
    
    // TransportItems
    private _transportItems = "true" configClasses (_cfgContent >> "TransportItems");
    {
        _harvestedGear pushBack (getText (_x >> "name"));
    } forEach _transportItems;
    
    // TransportWeapons
    private _transportWeapons = "true" configClasses (_cfgContent >> "TransportWeapons");
    {
        private _wep = getText (_x >> "weapon");
        if (_wep != "") then {
            [_wep] call _fnc_processWeapon;
        };
    } forEach _transportWeapons;

    // TransportBackpacks (Nested backpacks - rare but possible)
    private _transportBackpacks = "true" configClasses (_cfgContent >> "TransportBackpacks");
    {
        private _bag = getText (_x >> "backpack");
        if (_bag != "") then {
            _harvestedGear pushBack _bag;
            [_bag] call _fnc_processContainer;
        };
    } forEach _transportBackpacks;
};

// Helper to harvest a weapon and its linked items (attachments)
private _fnc_processWeapon = {
    params ["_weaponClass"];
    
    if (_weaponClass == "") exitWith {};
    _harvestedGear pushBack _weaponClass;
    
    private _cfgWeapon = configFile >> "CfgWeapons" >> _weaponClass;
    if (isClass _cfgWeapon) then {
        // Harvest LinkedItems (Optics, Pointers, Muzzles)
        private _linkedItems = "true" configClasses (_cfgWeapon >> "LinkedItems");
        {
            private _item = getText (_x >> "item");
            if (_item != "") then { _harvestedGear pushBack _item; };
        } forEach _linkedItems;
    };
};

private _fnc_addCandidateUnit = {
    params ["_unitClass"];

    if !(_unitClass isEqualType "") exitWith {};
    if (_unitClass == "") exitWith {};
    if !(isClass (configFile >> "CfgVehicles" >> _unitClass)) exitWith {};
    if !(_unitClass isKindOf "Man") exitWith {};

    _candidateUnitClasses pushBackUnique _unitClass;
};

private _fnc_collectUnitsFromValue = {
    params ["_value"];

    if (_value isEqualType "") exitWith {
        [_value] call _fnc_addCandidateUnit;
    };

    if !(_value isEqualType []) exitWith {};

    {
        [_x] call _fnc_collectUnitsFromValue;
    } forEach _value;
};

private _fnc_collectUnitsFromCatalog = {
    params ["_catalog"];
    if !(_catalog isEqualType createHashMap) exitWith {};

    {
        if (_x in _catalog) then {
            {
                [_x] call _fnc_addCandidateUnit;
            } forEach (_catalog get _x);
        };
    } forEach ["units", "officers", "groundInfantryUnits", "groundSpecOpsUnits"];

    {
        if (_x in _catalog) then {
            {
                private _crewClass = getText (configFile >> "CfgVehicles" >> _x >> "crew");
                if (_crewClass != "") then {
                    [_crewClass] call _fnc_addCandidateUnit;
                };
            } forEach (_catalog get _x);
        };
    } forEach [
        "groundMotorized",
        "groundMechanized",
        "groundArmor",
        "groundTransport",
        "groundArtillery",
        "airHeli",
        "airJet",
        "airTransport",
        "airDrone",
        "groundDrone",
        "mobileAA",
        "staticAA",
        "boat",
        "radar"
    ];
};

if (!isNil "FLO_FactionCatalog" && {"WEST" in FLO_FactionCatalog}) then {
    [FLO_FactionCatalog get "WEST"] call _fnc_collectUnitsFromCatalog;
    _catalogUnitCount = count _candidateUnitClasses;
};

if (
    _candidateUnitClasses isEqualTo []
    && {!isNil "FLO_FriendlyHandle"}
    && {FLO_FriendlyHandle isEqualType createHashMap}
) then {
    private _source = if ("source" in FLO_FriendlyHandle) then { FLO_FriendlyHandle get "source" } else { "" };
    private _localCatalog = createHashMap;

    if (_source in ["auto", "auto_multi"]) then {
        private _factionClasses = if ("factionClasses" in FLO_FriendlyHandle) then {
            +(FLO_FriendlyHandle get "factionClasses")
        } else {
            if ("factionClass" in FLO_FriendlyHandle) then { [FLO_FriendlyHandle get "factionClass"] } else { [] }
        };
        _factionClasses = _factionClasses select { _x isEqualType "" && {_x != ""} };
        _factionClasses = _factionClasses arrayIntersect _factionClasses;

        if (_factionClasses isNotEqualTo []) then {
            _localCatalog = if (_source isEqualTo "auto_multi" || {count _factionClasses > 1}) then {
                [_factionClasses] call FLO_fnc_factionBuildMergedAutoMilitaryCatalog
            } else {
                [_factionClasses select 0] call FLO_fnc_factionBuildAutoMilitaryCatalog
            };
        };
    };

    if ((count keys _localCatalog) > 0) then {
        [_localCatalog] call _fnc_collectUnitsFromCatalog;
        _catalogUnitCount = count _candidateUnitClasses;
    };
};

{
    if ((_x select [0, 2]) == "F_") then {
        [missionNamespace getVariable _x] call _fnc_collectUnitsFromValue;
    };
} forEach (allVariables missionNamespace);

_legacyUnitCount = (count _candidateUnitClasses) - _catalogUnitCount;

{
    private _unitClass = _x;
    if !(_unitClass in _processedUnits) then {
        _processedUnits pushBack _unitClass;

        private _cfg = configFile >> "CfgVehicles" >> _unitClass;

        {
            [_x] call _fnc_processWeapon;
        } forEach ((getArray (_cfg >> "weapons")) + (getArray (_cfg >> "respawnWeapons")));

        {
            if (_x != "") then { _harvestedGear pushBack _x; };
        } forEach ((getArray (_cfg >> "magazines")) + (getArray (_cfg >> "respawnMagazines")));

        {
            if (_x != "") then { _harvestedGear pushBack _x; };
        } forEach ((getArray (_cfg >> "items")) + (getArray (_cfg >> "respawnItems")));

        {
            if (_x != "") then { _harvestedGear pushBack _x; };
        } forEach ((getArray (_cfg >> "linkedItems")) + (getArray (_cfg >> "respawnLinkedItems")));

        private _uniform = getText (_cfg >> "uniformClass");
        if (_uniform != "") then { _harvestedGear pushBack _uniform; };

        private _backpack = getText (_cfg >> "backpack");
        if (_backpack != "") then {
            _harvestedGear pushBack _backpack;
            [_backpack] call _fnc_processContainer;
        };
    };
} forEach _candidateUnitClasses;

// --- Mod Integration: KAT & ACM ---
// we directly scan valid configuration tables for items matching the prefixes.
private _scanPrefixes = ["kat_", "ACM_"];
private _configRoots = ["CfgWeapons", "CfgMagazines", "CfgVehicles", "CfgGlasses"];

{
    private _root = _x;
    private _allConfigs = "true" configClasses (configFile >> _root);
    
    {
        private _item = configName _x;
        // Check if item starts with any of our prefixes
        {
            if ((_item find _x) != -1) exitWith {
                _harvestedGear pushBack _item;
            };
        } forEach _scanPrefixes;
    } forEach _allConfigs;
} forEach _configRoots;

// Remove duplicates and empty strings
_harvestedGear = _harvestedGear select {_x != ""};
_harvestedGear = _harvestedGear arrayIntersect _harvestedGear;

["ARSENAL", 3, format [
    "Harvested %1 unique items from %2 unit classes (catalogUnits=%3 legacyAdds=%4)",
    count _harvestedGear,
    count _processedUnits,
    _catalogUnitCount,
    _legacyUnitCount
]] call FLO_fnc_log;

_harvestedGear
