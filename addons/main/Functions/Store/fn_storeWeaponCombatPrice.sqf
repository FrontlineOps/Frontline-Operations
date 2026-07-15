params ["_className", "_category"];

private _cfg = configFile >> "CfgWeapons" >> _className;
if !(isClass _cfg) exitWith { 0 };
if !(_category in ["primary", "handgun", "secondary"]) exitWith { 0 };

private _magazines = [];
private _baseMagazines = [];
private _launcherMagazines = [];

private _muzzles = getArray (_cfg >> "muzzles");
if ((count _muzzles) isEqualTo 0) then {
    _muzzles = ["this"];
};
if !("this" in _muzzles) then {
    _muzzles pushBack "this";
};

{
    private _muzzle = _x;
    private _muzzleMagazines = if (_muzzle isEqualTo "this") then {
        getArray (_cfg >> "magazines")
    } else {
        getArray (_cfg >> _muzzle >> "magazines")
    };

    {
        if (_x == "") then { continue };
        _magazines pushBackUnique _x;

        if (_muzzle isEqualTo "this") then {
            _baseMagazines pushBackUnique _x;
        } else {
            _launcherMagazines pushBackUnique _x;
        };
    } forEach _muzzleMagazines;
} forEach _muzzles;

if ((count _baseMagazines) isEqualTo 0) then {
    {
        if (_x != "") then {
            _baseMagazines pushBackUnique _x;
        };
    } forEach getArray (_cfg >> "magazines");
};

{
    if (_x != "") then {
        _magazines pushBackUnique _x;
    };
} forEach _baseMagazines;

private _bestPower = 0;
private _bestAntiArmor = 0;
private _bestAntiAir = 0;
private _bestGrenade = 0;
private _bestLauncherGrenade = 0;
private _bestBaseGrenade = 0;
private _bestCannon = 0;
private _bestMachineGun = 0;
private _bestDirectHit = 0;
private _bestCaliber = 0;
private _bestGrenadeAmmoCount = 0;

{
    private _traits = [_x] call FLO_fnc_storeMagazineCombatTraits;

    if (_traits get "isUtility") then { continue };

    _bestPower = _bestPower max (_traits get "weaponPower");
    _bestAntiArmor = _bestAntiArmor max (_traits get "antiArmorScore");
    _bestAntiAir = _bestAntiAir max (_traits get "antiAirScore");
    _bestGrenade = _bestGrenade max (_traits get "grenadeScore");
    _bestCannon = _bestCannon max (_traits get "cannonScore");
    _bestMachineGun = _bestMachineGun max (_traits get "machineGunScore");
    _bestDirectHit = _bestDirectHit max (_traits get "directHit");
    _bestCaliber = _bestCaliber max (_traits get "caliber");

    if ((_traits get "grenadeScore") > 0) then {
        _bestGrenadeAmmoCount = _bestGrenadeAmmoCount max (_traits get "ammoCount");

        if (_x in _launcherMagazines) then {
            _bestLauncherGrenade = _bestLauncherGrenade max (_traits get "grenadeScore");
        };

        if (_x in _baseMagazines) then {
            _bestBaseGrenade = _bestBaseGrenade max (_traits get "grenadeScore");
        };
    };
} forEach _magazines;

private _weaponText = toLower format ["%1 %2 %3", _className, getText (_cfg >> "displayName"), getText (_cfg >> "descriptionShort")];
private _maxRange = getNumber (_cfg >> "maxZeroing");

{
    _maxRange = _maxRange max getNumber (_x >> "maxRange");
    _maxRange = _maxRange max getNumber (_x >> "distanceZoomMax");
} forEach ("true" configClasses _cfg);

private _isAntiMateriel = (_bestDirectHit >= 28)
    || {_bestCaliber >= 2.2}
    || {(_weaponText find "m107") >= 0}
    || {(_weaponText find "m82") >= 0}
    || {(_weaponText find "m95") >= 0}
    || {(_weaponText find "anti-materiel") >= 0}
    || {(_weaponText find "anti materiel") >= 0}
    || {(_weaponText find ".50") >= 0}
    || {(_weaponText find "12.7") >= 0};
private _isStandaloneMgl = ((_weaponText find "m32") >= 0)
    || {(_weaponText find "mgl") >= 0};
private _isUnderbarrelGl = (_bestLauncherGrenade > 0)
    || {(_weaponText find "m203") >= 0}
    || {(_weaponText find "m320") >= 0}
    || {(_weaponText find "ugl") >= 0}
    || {(_weaponText find "eglm") >= 0};
private _isMachineGun = (_bestMachineGun >= 12)
    || {(_weaponText find "m249") >= 0}
    || {(_weaponText find "m240") >= 0}
    || {(_weaponText find "machine gun") >= 0}
    || {(_weaponText find "lmg") >= 0}
    || {(_weaponText find "mmg") >= 0};
private _isGenericGrenadeLauncher = (!_isUnderbarrelGl) && {
    ((_weaponText find "m32") >= 0)
    || {(_weaponText find "mgl") >= 0}
    || {(_weaponText find "grenade launcher") >= 0}
};
private _rangeAdd = switch (true) do {
    case (_maxRange >= 1800): { 220 };
    case (_maxRange >= 1200): { 130 };
    case (_maxRange >= 800): { 60 };
    default { 0 };
};

private _price = switch (_category) do {
    case "handgun": {
        ceil ((_bestPower min 180) * 0.12)
    };
    case "secondary": {
        110
            + ceil ((_bestPower min 1200) * 0.5)
            + ceil ((_bestAntiArmor min 1400) * 0.85)
            + ceil ((_bestAntiAir min 1400) * 0.95)
    };
    default {
        ceil ((_bestPower min 900) * 0.12)
            + ceil ((_bestCannon min 900) * 0.18)
            + _rangeAdd
    };
};

if (_category isEqualTo "primary" && {_isMachineGun}) then {
    _price = _price + 95 + ceil (((_bestMachineGun max 0) min 120) * 1.1);
};

if (_category isEqualTo "primary" && {_isAntiMateriel}) then {
    _price = _price
        + 300
        + ceil (((_bestDirectHit max 0) min 90) * 6)
        + ceil (((_bestCaliber max 0) min 7) * 60);
};

if (_category isEqualTo "primary" && {_isUnderbarrelGl && {!_isStandaloneMgl}}) then {
    _price = _price
        + 210
        + ceil (((_bestLauncherGrenade max 0) min 1400) * 0.14);
};

if (_category isEqualTo "primary" && {(_isStandaloneMgl || {_isGenericGrenadeLauncher})}) then {
    _price = _price
        + 760
        + ceil ((((_bestBaseGrenade max _bestGrenade) max 0) min 2400) * 0.28)
        + (((_bestGrenadeAmmoCount max 1) min 8) * 45);
};

_price
