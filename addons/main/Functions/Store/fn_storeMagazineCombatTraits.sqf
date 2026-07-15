params ["_magazineClass"];

private _empty = createHashMapFromArray [
    ["isUtility", true],
    ["weaponPower", 0],
    ["antiArmorScore", 0],
    ["antiAirScore", 0],
    ["artilleryScore", 0],
    ["grenadeScore", 0],
    ["machineGunScore", 0],
    ["cannonScore", 0],
    ["directHit", 0],
    ["indirectPower", 0],
    ["caliber", 0],
    ["ammoCount", 0]
];

private _magCfg = configFile >> "CfgMagazines" >> _magazineClass;
if !(isClass _magCfg) exitWith { _empty };

private _ammoClass = getText (_magCfg >> "ammo");
private _ammoCfg = configFile >> "CfgAmmo" >> _ammoClass;
if !(isClass _ammoCfg) exitWith { _empty };

private _ammoText = toLower format ["%1 %2 %3", _ammoClass, _magazineClass, getText (_magCfg >> "displayName")];
private _simulation = toLower getText (_ammoCfg >> "simulation");
private _isUtility = false;

{
    if ((_ammoText find _x) >= 0) exitWith {
        _isUtility = true;
    };
} forEach ["smoke", "flare", "chaff", "countermeasure", "laser"];

if (_isUtility || {_simulation isEqualTo "shotsmoke"}) exitWith { _empty };

private _hit = getNumber (_ammoCfg >> "hit");
private _indirectHit = getNumber (_ammoCfg >> "indirectHit");
private _indirectRange = getNumber (_ammoCfg >> "indirectHitRange");
private _caliber = getNumber (_ammoCfg >> "caliber");
private _count = getNumber (_magCfg >> "count");
private _airLock = getNumber (_ammoCfg >> "airLock");
private _irLock = getNumber (_ammoCfg >> "irLock");
private _laserLock = getNumber (_ammoCfg >> "laserLock");
private _manualControl = getNumber (_ammoCfg >> "manualControl");
private _maxControlRange = getNumber (_ammoCfg >> "maxControlRange");
private _indirectPower = _indirectHit * (_indirectRange max 1);
private _quantityFactor = 1 + (((_count max 1) min 300) / 180);
private _quality = ((_hit min 240) * 3)
    + ((_indirectHit min 90) * ((_indirectRange max 1) min 20) * 5)
    + ((_caliber max 0) min 12) * 18;
private _weaponPower = ceil ((_quality min 900) * _quantityFactor);
private _antiArmorScore = 0;
private _antiAirScore = 0;
private _artilleryScore = 0;
private _grenadeScore = 0;
private _machineGunScore = 0;
private _cannonScore = 0;

if (_hit > 0 && {_hit < 45} && {_indirectHit < 4}) then {
    _machineGunScore = ceil ((_hit min 35) * _quantityFactor);
};

if ((_hit >= 45 && {_hit < 120}) || {_caliber >= 2.5}) then {
    _cannonScore = ceil (((_hit min 100) + ((_caliber min 8) * 8)) * _quantityFactor);
};

if (_indirectHit >= 5 && {_indirectRange >= 3}) then {
    private _explosiveTextBonus = [1, 1.25] select (
        ((_ammoText find "gmg") >= 0)
        || {(_ammoText find "mk19") >= 0}
        || {(_ammoText find "grenade") >= 0}
    );

    _grenadeScore = ceil (((_indirectHit * (_indirectRange max 1) * 3) min 1200) * _quantityFactor * _explosiveTextBonus);
};

if (
    _hit >= 120
    || {_manualControl > 0}
    || {_maxControlRange > 0}
    || {(_ammoText find "atgm") >= 0}
    || {(_ammoText find "at_") >= 0}
    || {(_ammoText find "heat") >= 0}
    || {(_ammoText find "apfsds") >= 0}
) then {
    _antiArmorScore = ceil (((_hit min 240) max 80) * _quantityFactor);
};

if (
    _airLock > 0
    || {_irLock > 0}
    || {_laserLock > 0}
    || {(_ammoText find "aa") >= 0}
    || {(_ammoText find "sam") >= 0}
) then {
    _antiAirScore = ceil (140 * _quantityFactor);
};

if (
    _indirectRange >= 12 && {_indirectHit >= 20}
    || {(_ammoText find "rocket") >= 0}
    || {(_ammoText find "mlrs") >= 0}
    || {(_ammoText find "himars") >= 0}
    || {(_ammoText find "mortar") >= 0}
    || {(_ammoText find "artillery") >= 0}
    || {(_ammoText find "howitzer") >= 0}
) then {
    _artilleryScore = ceil (((_indirectPower min 650) max 150) * _quantityFactor);
};

createHashMapFromArray [
    ["isUtility", false],
    ["weaponPower", _weaponPower],
    ["antiArmorScore", _antiArmorScore],
    ["antiAirScore", _antiAirScore],
    ["artilleryScore", _artilleryScore],
    ["grenadeScore", _grenadeScore],
    ["machineGunScore", _machineGunScore],
    ["cannonScore", _cannonScore],
    ["directHit", _hit],
    ["indirectPower", _indirectPower],
    ["caliber", _caliber],
    ["ammoCount", _count]
]

