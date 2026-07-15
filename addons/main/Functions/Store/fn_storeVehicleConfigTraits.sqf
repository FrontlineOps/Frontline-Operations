params ["_className", "_category"];

private _cfg = configFile >> "CfgVehicles" >> _className;

if !(isClass _cfg) then {
    throw format ["[FLO][Store] Cannot price missing vehicle class %1", _className];
};

private _collected = [_cfg] call FLO_fnc_storeCollectVehicleWeapons;
private _weapons = +(_collected get "weapons");
private _magazines = +(_collected get "magazines");
private _turretCount = _collected get "turretCount";
private _remoteWeaponCount = _collected get "remoteWeaponCount";
private _exposedWeaponCount = _collected get "exposedWeaponCount";
private _stabilizedWeaponCount = _collected get "stabilizedWeaponCount";
private _thermalOpticCount = _collected get "thermalOpticCount";
private _nvgOpticCount = _collected get "nvgOpticCount";
private _opticsScore = _collected get "opticsScore";

{
    private _weaponCfg = configFile >> "CfgWeapons" >> _x;

    if (isClass _weaponCfg) then {
        {
            if (_x != "") then {
                _magazines pushBackUnique _x;
            };
        } forEach getArray (_weaponCfg >> "magazines");
    };
} forEach _weapons;

private _transport = getNumber (_cfg >> "transportSoldier");
private _cargo = getNumber (_cfg >> "maximumLoad");
private _armor = getNumber (_cfg >> "armor");
private _armorStructural = getNumber (_cfg >> "armorStructural");
private _crewExplosionProtection = getNumber (_cfg >> "crewExplosionProtection");
private _explosionShielding = getNumber (_cfg >> "explosionShielding");
private _crewVulnerable = getNumber (_cfg >> "crewVulnerable");
private _slingMass = getNumber (_cfg >> "slingLoadMaxCargoMass");
private _transportAmmo = getNumber (_cfg >> "transportAmmo");
private _transportFuel = getNumber (_cfg >> "transportFuel");
private _transportRepair = getNumber (_cfg >> "transportRepair");
private _aceAmmo = getNumber (_cfg >> "ace_rearm_defaultSupply");
private _aceFuel = getNumber (_cfg >> "ace_refuel_fuelCapacity");
private _aceRepair = getNumber (_cfg >> "ace_repair_canRepair");
private _radar = getNumber (_cfg >> "radarType");
private _irScan = getNumber (_cfg >> "irScanRange");
private _laserScanner = getNumber (_cfg >> "laserScanner");
private _lockDetection = getNumber (_cfg >> "lockDetectionSystem");
private _incomingMissileDetection = getNumber (_cfg >> "incomingMissileDetectionSystem");
private _artilleryScanner = getNumber (_cfg >> "artilleryScanner");
private _isUav = getNumber (_cfg >> "isUav");
private _threat = getArray (_cfg >> "threat");
private _softThreat = _threat param [0, 0];
private _armorThreat = _threat param [1, 0];
private _airThreat = _threat param [2, 0];
private _searchText = toLower format ["%1 %2 %3", _className, getText (_cfg >> "displayName"), getText (_cfg >> "editorSubcategory")];
private _isMrap = false;
private _isHumvee = false;

{
    if ((_searchText find _x) >= 0) exitWith {
        _isMrap = true;
    };
} forEach ["mrap", "m-atv", "matv", "m1240", "m1277", "m1230", "maxxpro", "cougar", "rg33", "rg-33"];

{
    if ((_searchText find _x) >= 0) exitWith {
        _isHumvee = true;
    };
} forEach ["humvee", "hmmwv", "m1025", "m1043", "m1045", "m1097", "m1114", "m1151", "m1152", "m1165"];

private _structuralProtection = 0;

if (_armorStructural > 0) then {
    _structuralProtection = _structuralProtection + (_armorStructural min 12) * 22;
};

if (_crewExplosionProtection > 0) then {
    _structuralProtection = _structuralProtection + (_crewExplosionProtection min 8) * 80;
};

if (_explosionShielding > 0) then {
    _structuralProtection = _structuralProtection + (_explosionShielding min 8) * 55;
};

if (_isMrap) then {
    _structuralProtection = _structuralProtection + 260;
};

if (_isHumvee && {!_isMrap}) then {
    _structuralProtection = _structuralProtection - 160;
};

if (_crewVulnerable > 0) then {
    _structuralProtection = _structuralProtection - 220;
};

private _protectionScore = (_armor max 0) + (_structuralProtection max -220);
private _combatWeaponCount = 0;
private _weaponPower = 0;
private _antiArmorScore = 0;
private _antiAirScore = 0;
private _artilleryScore = 0;
private _cannonScore = 0;
private _machineGunScore = 0;
private _grenadeScore = 0;
private _directHitMax = 0;
private _indirectPowerMax = 0;

{
    private _weaponCfg = configFile >> "CfgWeapons" >> _x;
    private _weaponText = toLower format ["%1 %2", _x, getText (_weaponCfg >> "displayName")];
    private _isUtilityWeapon = false;

    {
        if ((_weaponText find _x) >= 0) exitWith {
            _isUtilityWeapon = true;
        };
    } forEach [
        "horn",
        "smoke",
        "flare",
        "chaff",
        "countermeasure",
        "laserdesignator",
        "fakeweapon",
        "weaponempty"
    ];

    if (!_isUtilityWeapon) then {
        _combatWeaponCount = _combatWeaponCount + 1;
    };
} forEach _weapons;

{
    private _magTraits = [_x] call FLO_fnc_storeMagazineCombatTraits;

    if (_magTraits get "isUtility") then { continue };

    _directHitMax = _directHitMax max (_magTraits get "directHit");
    _indirectPowerMax = _indirectPowerMax max (_magTraits get "indirectPower");
    _weaponPower = _weaponPower + ((_magTraits get "weaponPower") min 360);
    _antiArmorScore = _antiArmorScore + (_magTraits get "antiArmorScore");
    _antiAirScore = _antiAirScore + (_magTraits get "antiAirScore");
    _artilleryScore = _artilleryScore + (_magTraits get "artilleryScore");
    _grenadeScore = _grenadeScore + (_magTraits get "grenadeScore");
    _cannonScore = _cannonScore + (_magTraits get "cannonScore");
    _machineGunScore = _machineGunScore + (_magTraits get "machineGunScore");
} forEach _magazines;

private _threatScore = ((_softThreat min 1) * 350) + ((_armorThreat min 1) * 750) + ((_airThreat min 1) * 850);

if (_combatWeaponCount > 0 && {_weaponPower <= 0}) then {
    _weaponPower = 120 + _threatScore;
};

private _maxThreat = (_softThreat max _armorThreat) max _airThreat;
private _hasWeapon = _combatWeaponCount > 0 || {_weaponPower > 0} || {
    _category isNotEqualTo "cars"
    && {_maxThreat >= 0.75}
};
private _hasAntiArmor = _antiArmorScore > 0 || {_hasWeapon && {_armorThreat >= 0.55}};
private _hasAntiAir = _antiAirScore > 0 || {_hasWeapon && {_airThreat >= 0.55}};
private _hasArtillery = _artilleryScanner > 0
    || {_artilleryScore > 0}
    || {(_searchText find "m142") >= 0}
    || {(_searchText find "himars") >= 0}
    || {(_searchText find "mlrs") >= 0}
    || {(_searchText find "rocket") >= 0}
    || {(_searchText find "mortar") >= 0}
    || {(_searchText find "artillery") >= 0}
    || {(_searchText find "howitzer") >= 0};
private _hasLogistics = _transportAmmo > 0 || {_transportFuel > 0} || {_transportRepair > 0} || {_aceAmmo > 0} || {_aceFuel > 0} || {_aceRepair > 0};
private _hasSensors = _radar > 0 || {_irScan > 0} || {_laserScanner > 0} || {_lockDetection > 0} || {_incomingMissileDetection > 0} || {_thermalOpticCount > 0} || {_nvgOpticCount > 0};
private _isMbt = _category isEqualTo "armor" && {
    _armor >= 650
    || {(_searchText find "mbt") >= 0}
    || {(_searchText find "tank") >= 0}
};
private _isIfv = _category isEqualTo "armor" && {
    !_isMbt
    && {_hasWeapon}
    && {(_cannonScore > 0) || {_hasAntiArmor}}
};
private _isApc = _category isEqualTo "armor" && {
    !_isMbt
    && {!_isIfv}
    && {_transport >= 4}
};

createHashMapFromArray [
    ["transport", _transport],
    ["cargo", _cargo],
    ["armor", _armor],
    ["armorStructural", _armorStructural],
    ["crewExplosionProtection", _crewExplosionProtection],
    ["explosionShielding", _explosionShielding],
    ["crewVulnerable", _crewVulnerable],
    ["protectionScore", _protectionScore],
    ["slingMass", _slingMass],
    ["transportAmmo", _transportAmmo],
    ["transportFuel", _transportFuel],
    ["transportRepair", _transportRepair],
    ["aceAmmo", _aceAmmo],
    ["aceFuel", _aceFuel],
    ["aceRepair", _aceRepair],
    ["combatWeaponCount", _combatWeaponCount],
    ["weaponPower", _weaponPower],
    ["antiArmorScore", _antiArmorScore],
    ["antiAirScore", _antiAirScore],
    ["artilleryScore", _artilleryScore],
    ["cannonScore", _cannonScore],
    ["machineGunScore", _machineGunScore],
    ["grenadeScore", _grenadeScore],
    ["directHitMax", _directHitMax],
    ["indirectPowerMax", _indirectPowerMax],
    ["threatScore", _threatScore],
    ["turretCount", _turretCount],
    ["remoteWeaponCount", _remoteWeaponCount],
    ["exposedWeaponCount", _exposedWeaponCount],
    ["stabilizedWeaponCount", _stabilizedWeaponCount],
    ["thermalOpticCount", _thermalOpticCount],
    ["nvgOpticCount", _nvgOpticCount],
    ["opticsScore", _opticsScore],
    ["hasWeapon", _hasWeapon],
    ["hasAntiArmor", _hasAntiArmor],
    ["hasAntiAir", _hasAntiAir],
    ["hasArtillery", _hasArtillery],
    ["hasLogistics", _hasLogistics],
    ["hasSensors", _hasSensors],
    ["isMbt", _isMbt],
    ["isIfv", _isIfv],
    ["isApc", _isApc],
    ["isMrap", _isMrap],
    ["isHumvee", _isHumvee],
    ["isUav", _isUav > 0]
]
