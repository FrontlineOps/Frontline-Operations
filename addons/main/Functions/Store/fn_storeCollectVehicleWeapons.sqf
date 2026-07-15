params ["_cfg"];

private _weapons = [];
private _magazines = [];
private _turretCount = 0;
private _remoteWeaponCount = 0;
private _exposedWeaponCount = 0;
private _stabilizedWeaponCount = 0;
private _thermalOpticCount = 0;
private _nvgOpticCount = 0;
private _opticsScore = 0;

{
    if (_x != "") then {
        _weapons pushBackUnique _x;
    };
} forEach getArray (_cfg >> "weapons");

{
    if (_x isNotEqualTo "") then {
        _magazines pushBack _x;
    };
} forEach getArray (_cfg >> "magazines");

{
    private _turretCfg = _x;
    private _turretWeapons = getArray (_turretCfg >> "weapons");
    private _turretText = toLower format [
        "%1 %2 %3 %4 %5",
        configName _turretCfg,
        getText (_turretCfg >> "gunnerName"),
        getText (_turretCfg >> "turretInfoType"),
        getText (_turretCfg >> "gunnerAction"),
        getText (_turretCfg >> "gunnerInAction")
    ];
    private _hasCombatTurretWeapon = false;

    {
        private _weaponText = toLower _x;

        if !(
            _weaponText isEqualTo ""
            || {(_weaponText find "horn") >= 0}
            || {(_weaponText find "smoke") >= 0}
            || {(_weaponText find "flare") >= 0}
            || {(_weaponText find "countermeasure") >= 0}
            || {(_weaponText find "laserdesignator") >= 0}
            || {(_weaponText find "fakeweapon") >= 0}
            || {(_weaponText find "weaponempty") >= 0}
        ) exitWith {
            _hasCombatTurretWeapon = true;
        };
    } forEach _turretWeapons;

    if (_hasCombatTurretWeapon) then {
        _turretCount = _turretCount + 1;

        private _isRemote = false;
        {
            if ((_turretText find _x) >= 0) exitWith {
                _isRemote = true;
            };
        } forEach ["crows", "crow", "rws", "rcws", "remote", "m153", "m151"];

        if (_isRemote) then {
            _remoteWeaponCount = _remoteWeaponCount + 1;
        };

        private _isExposed = (getNumber (_turretCfg >> "isPersonTurret")) > 0;
        {
            if ((_turretText find _x) >= 0) exitWith {
                _isExposed = true;
            };
        } forEach ["standup", "turnout", "open", "gunner_standup"];

        if (_isExposed) then {
            _exposedWeaponCount = _exposedWeaponCount + 1;
        };

        private _stabilized = getNumber (_turretCfg >> "stabilizedInAxes");
        if (_stabilized > 0) then {
            _stabilizedWeaponCount = _stabilizedWeaponCount + 1;
            _opticsScore = _opticsScore + (180 * (_stabilized min 3));
        };

        private _visionTraits = createHashMapFromArray [
            ["hasNvg", false],
            ["hasThermal", false],
            ["hasThermalResolution", false],
            ["thermalModeCount", 0]
        ];

        [_turretCfg, _visionTraits] call FLO_fnc_storeReadConfigVisionTree;

        if (_visionTraits get "hasThermal") then {
            _thermalOpticCount = _thermalOpticCount + 1;
            _opticsScore = _opticsScore + 900 + (((_visionTraits get "thermalModeCount") max 1) min 5) * 160;
        };

        if (_visionTraits get "hasNvg") then {
            _nvgOpticCount = _nvgOpticCount + 1;
            _opticsScore = _opticsScore + 250;
        };

        if (getText (_turretCfg >> "gunnerOpticsModel") isNotEqualTo "") then {
            _opticsScore = _opticsScore + 120;
        };

        private _bestDistance = 0;
        {
            _bestDistance = _bestDistance max _x;
        } forEach getArray (_turretCfg >> "discreteDistance");

        if (_bestDistance >= 1200) then {
            _opticsScore = _opticsScore + 250;
        } else {
            if (_bestDistance >= 800) then {
                _opticsScore = _opticsScore + 125;
            };
        };
    };

    private _child = [_x] call FLO_fnc_storeCollectVehicleWeapons;

    {
        if (_x != "") then {
            _weapons pushBackUnique _x;
        };
    } forEach (_child get "weapons");

    {
        _magazines pushBack _x;
    } forEach (_child get "magazines");

    _turretCount = _turretCount + (_child get "turretCount");
    _remoteWeaponCount = _remoteWeaponCount + (_child get "remoteWeaponCount");
    _exposedWeaponCount = _exposedWeaponCount + (_child get "exposedWeaponCount");
    _stabilizedWeaponCount = _stabilizedWeaponCount + (_child get "stabilizedWeaponCount");
    _thermalOpticCount = _thermalOpticCount + (_child get "thermalOpticCount");
    _nvgOpticCount = _nvgOpticCount + (_child get "nvgOpticCount");
    _opticsScore = _opticsScore + (_child get "opticsScore");
} forEach ("true" configClasses (_cfg >> "Turrets"));

createHashMapFromArray [
    ["weapons", _weapons],
    ["magazines", _magazines],
    ["turretCount", _turretCount],
    ["remoteWeaponCount", _remoteWeaponCount],
    ["exposedWeaponCount", _exposedWeaponCount],
    ["stabilizedWeaponCount", _stabilizedWeaponCount],
    ["thermalOpticCount", _thermalOpticCount],
    ["nvgOpticCount", _nvgOpticCount],
    ["opticsScore", _opticsScore]
]
