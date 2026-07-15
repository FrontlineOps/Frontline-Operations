params ["_className", "_category"];

private _traits = [_className, _category] call FLO_fnc_storeVehicleConfigTraits;
private _transport = _traits get "transport";
private _cargo = _traits get "cargo";
private _armor = _traits get "armor";
private _protectionScore = _traits get "protectionScore";
private _slingMass = _traits get "slingMass";
private _transportAmmo = _traits get "transportAmmo";
private _transportFuel = _traits get "transportFuel";
private _transportRepair = _traits get "transportRepair";
private _aceAmmo = _traits get "aceAmmo";
private _aceFuel = _traits get "aceFuel";
private _aceRepair = _traits get "aceRepair";
private _combatWeaponCount = _traits get "combatWeaponCount";
private _weaponPower = _traits get "weaponPower";
private _antiArmorScore = _traits get "antiArmorScore";
private _antiAirScore = _traits get "antiAirScore";
private _artilleryScore = _traits get "artilleryScore";
private _grenadeScore = _traits get "grenadeScore";
private _cannonScore = _traits get "cannonScore";
private _machineGunScore = _traits get "machineGunScore";
private _directHitMax = _traits get "directHitMax";
private _threatScore = _traits get "threatScore";
private _turretCount = _traits get "turretCount";
private _remoteWeaponCount = _traits get "remoteWeaponCount";
private _exposedWeaponCount = _traits get "exposedWeaponCount";
private _stabilizedWeaponCount = _traits get "stabilizedWeaponCount";
private _thermalOpticCount = _traits get "thermalOpticCount";
private _nvgOpticCount = _traits get "nvgOpticCount";
private _opticsScore = _traits get "opticsScore";
private _hasWeapon = _traits get "hasWeapon";
private _hasAntiArmor = _traits get "hasAntiArmor";
private _hasAntiAir = _traits get "hasAntiAir";
private _hasArtillery = _traits get "hasArtillery";
private _hasLogistics = _traits get "hasLogistics";
private _hasSensors = _traits get "hasSensors";
private _isMbt = _traits get "isMbt";
private _isIfv = _traits get "isIfv";
private _isApc = _traits get "isApc";
private _isMrap = _traits get "isMrap";
private _isHumvee = _traits get "isHumvee";
private _isUav = _traits get "isUav";

private _roleBase = switch (true) do {
    case (_category isEqualTo "cars" && {_hasArtillery}): { 13500 };
    case (_category isEqualTo "cars" && {_hasLogistics}): { 750 };
    case (_category isEqualTo "cars" && {_hasWeapon && {_isMrap}}): { 2100 };
    case (_category isEqualTo "cars" && {_hasWeapon && {_isHumvee}}): { 700 };
    case (_category isEqualTo "cars" && {_hasWeapon && {_protectionScore >= 170}}): { 1300 };
    case (_category isEqualTo "cars" && {_hasWeapon}): { 500 };
    case (_category isEqualTo "cars" && {_isMrap}): { 1250 };
    case (_category isEqualTo "cars" && {_isHumvee}): { 220 };
    case (_category isEqualTo "cars" && {_protectionScore >= 170}): { 650 };
    case (_category isEqualTo "cars" && {_transport >= 8}): { 420 };
    case (_category isEqualTo "cars"): { 180 };

    case (_category isEqualTo "armor" && {_hasArtillery}): { 14000 };
    case (_category isEqualTo "armor" && {_isMbt}): { 11000 };
    case (_category isEqualTo "armor" && {_hasAntiAir}): { 9000 };
    case (_category isEqualTo "armor" && {_isIfv}): { 5500 };
    case (_category isEqualTo "armor" && {_isApc}): { 3200 };
    case (_category isEqualTo "armor"): { 3500 };

    case (_category isEqualTo "helis" && {_hasAntiArmor || {_hasAntiAir}}): { 16500 };
    case (_category isEqualTo "helis" && {_hasWeapon}): { 11500 };
    case (_category isEqualTo "helis" && {_transport >= 8}): { 6500 };
    case (_category isEqualTo "helis"): { 4500 };

    case (_category isEqualTo "planes" && {_hasAntiArmor || {_hasAntiAir}}): { 30000 };
    case (_category isEqualTo "planes" && {_hasWeapon}): { 24000 };
    case (_category isEqualTo "planes"): { 14000 };

    case (_category isEqualTo "naval" && {_hasWeapon}): { 1400 };
    case (_category isEqualTo "naval"): { 750 };

    case (_category isEqualTo "static" && {_hasArtillery}): { 2600 };
    case (_category isEqualTo "static" && {_hasAntiArmor || {_hasAntiAir}}): { 1600 };
    case (_category isEqualTo "static" && {_hasWeapon}): { 650 };
    case (_category isEqualTo "static"): { 450 };

    default { 1000 };
};

private _armorCap = switch (_category) do {
    case "cars": { 650 };
    case "armor": { 1600 };
    case "helis": { 320 };
    case "planes": { 260 };
    case "naval": { 500 };
    case "static": { 450 };
    default { 450 };
};
private _armorFactor = switch (_category) do {
    case "cars": { 1.85 };
    case "armor": { 3.8 };
    case "helis": { 2 };
    case "planes": { 2 };
    case "naval": { 2 };
    case "static": { 2 };
    default { 2 };
};
private _protectionInput = [_armor, _protectionScore] select (_protectionScore > 0);
private _protectionAdd = ceil (((_protectionInput max 0) min _armorCap) * _armorFactor);

if (_category isEqualTo "cars" && {_isHumvee && {!_isMrap}}) then {
    _protectionAdd = floor (_protectionAdd * 0.45);
};
if (_category isEqualTo "cars" && {_isMrap}) then {
    _protectionAdd = floor (_protectionAdd * 1.18);
};
private _transportAdd = ((_transport max 0) min 20) * 45;
private _cargoAdd = ceil (((_cargo max 0) min 8000) / 160);
private _slingAdd = ceil (((_slingMass max 0) min 12000) / 180);
private _weaponAdd = 0;

if (_hasWeapon) then {
    _weaponAdd = 220
        + (((_combatWeaponCount max 0) min 5) * 130)
        + ceil (((_weaponPower max 0) min 1700) * 0.85)
        + ceil ((_threatScore max 0) min 900)
        + ceil (((_machineGunScore max 0) min 500) * 0.45)
        + ceil (((_cannonScore max 0) min 900) * 0.75)
        + ceil (((_grenadeScore max 0) min 1600) * 1.35);
};

if (_hasAntiArmor) then {
    _weaponAdd = _weaponAdd + (500 + ceil (((_antiArmorScore max 0) min 500) * 0.7));
};

if (_hasAntiAir) then {
    _weaponAdd = _weaponAdd + (650 + ceil (((_antiAirScore max 0) min 500) * 0.8));
};

if (_hasArtillery) then {
    _weaponAdd = _weaponAdd + (3200 + ceil (((_artilleryScore max 0) min 2400) * 1.25));
};

if (_isMbt) then {
    _weaponAdd = _weaponAdd
        + 900
        + ceil (((_antiArmorScore max 0) min 1600) * 0.65)
        + ceil (((_directHitMax max 0) min 500) * 5.0);
};

private _logisticsAdd = 0;

if (_hasLogistics) then {
    _logisticsAdd = 500
        + ceil (((_transportAmmo max _aceAmmo) min 5000) / 8)
        + ceil (((_transportFuel max _aceFuel) min 10000) / 18)
        + ceil (((_transportRepair max 0) min 1000) / 4);

    if (_aceRepair > 0) then {
        _logisticsAdd = _logisticsAdd + 350;
    };
};

private _sensorAdd = 0;

if (_hasSensors) then {
    _sensorAdd = 250
        + ceil (((_opticsScore max 0) min 4000) * 0.7)
        + ((_thermalOpticCount max 0) min 3) * 1200
        + ((_nvgOpticCount max 0) min 3) * 250;
};

if (_isUav) then {
    _sensorAdd = _sensorAdd + 600;
};

if (_category in ["helis", "planes"]) then {
    _weaponAdd = floor (_weaponAdd * 1.45);
    _sensorAdd = floor (_sensorAdd * 1.35);
};

private _turretAdd = 0;

if (_hasWeapon) then {
    _turretAdd = ((_turretCount max 0) min 4) * 120
        + ((_remoteWeaponCount max 0) min 3) * 850
        + ((_stabilizedWeaponCount max 0) min 3) * 550;

    if (_exposedWeaponCount > 0) then {
        _turretAdd = _turretAdd - (((_exposedWeaponCount max 0) min 3) * 350);
    };
};

private _cap = switch (_category) do {
    case "cars": { 30000 };
    case "armor": { 45000 };
    case "helis": { 45000 };
    case "planes": { 70000 };
    case "naval": { 8500 };
    case "static": { 7000 };
    default { 12000 };
};
private _floor = switch (_category) do {
    case "cars": { 180 };
    case "armor": { [2500, 13000] select _isMbt };
    case "helis": { 4500 };
    case "planes": { 12000 };
    case "naval": { 600 };
    case "static": { 400 };
    default { 800 };
};
private _price = _roleBase
    + _protectionAdd
    + _transportAdd
    + _cargoAdd
    + _slingAdd
    + _weaponAdd
    + _turretAdd
    + _logisticsAdd
    + _sensorAdd;
private _rounded = (ceil (((_price min _cap) max _floor) / 50)) * 50;

_rounded

