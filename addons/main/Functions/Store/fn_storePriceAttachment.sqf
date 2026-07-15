params ["_className", "_mass"];

private _cfg = configFile >> "CfgWeapons" >> _className;

if !(isClass _cfg) exitWith { 75 };

private _itemInfo = _cfg >> "ItemInfo";
private _itemType = _className call BIS_fnc_itemType;
private _kind = _itemType param [1, ""];
private _price = switch (_kind) do {
    case "AccessoryMuzzle": { 120 };
    case "AccessoryPointer": { 100 };
    case "AccessorySights": { 150 };
    case "AccessoryBipod": { 175 };
    default { 75 };
};

_price = _price + (ceil (_mass / 4));

if (_kind isEqualTo "AccessoryMuzzle") then {
    private _ammoCoef = _itemInfo >> "AmmoCoef";

    if (isClass _ammoCoef) then {
        private _audible = getNumber (_ammoCoef >> "audibleFire");
        private _visible = getNumber (_ammoCoef >> "visibleFire");
        private _visibleTime = getNumber (_ammoCoef >> "visibleFireTime");
        private _reducesSound = (_audible > 0) && {_audible < 1};
        private _reducesFlash = ((_visible > 0) && {_visible < 1}) || {(_visibleTime > 0) && {_visibleTime < 1}};

        if (_reducesSound || {_reducesFlash}) then {
            _price = _price + 350;
        };
    };
};

if (_kind isEqualTo "AccessoryPointer") then {
    private _hasPointer = isClass (_itemInfo >> "Pointer");
    private _hasFlashlight = isClass (_itemInfo >> "FlashLight");

    if (_hasPointer) then {
        _price = _price + 250;
    };

    if (_hasFlashlight) then {
        _price = _price + 100;
    };

    if (_hasPointer && {_hasFlashlight}) then {
        _price = _price + 150;
    };
};

if (_kind isEqualTo "AccessorySights") then {
    private _modeCount = 0;
    private _bestMagnification = 1;
    private _bestDistance = 0;

    {
        private _candidateCfg = _x;
        private _zoomMin = getNumber (_candidateCfg >> "opticsZoomMin");
        private _distanceMax = getNumber (_candidateCfg >> "distanceZoomMax");

        if (_zoomMin > 0) then {
            _bestMagnification = _bestMagnification max (0.25 / _zoomMin);
        };

        if (_distanceMax > 0) then {
            _bestDistance = _bestDistance max _distanceMax;
        };

        private _modesCfg = _candidateCfg >> "OpticsModes";

        if (isClass _modesCfg) then {
            {
                _modeCount = _modeCount + 1;

                private _modeZoomMin = getNumber (_x >> "opticsZoomMin");
                private _modeDistanceMax = getNumber (_x >> "distanceZoomMax");

                if (_modeZoomMin > 0) then {
                    _bestMagnification = _bestMagnification max (0.25 / _modeZoomMin);
                };

                if (_modeDistanceMax > 0) then {
                    _bestDistance = _bestDistance max _modeDistanceMax;
                };
            } forEach ("true" configClasses _modesCfg);
        };
    } forEach [_cfg, _itemInfo];

    _price = _price + (switch (true) do {
        case (_bestMagnification >= 12): { 1400 };
        case (_bestMagnification >= 8): { 900 };
        case (_bestMagnification >= 4): { 550 };
        case (_bestMagnification > 1.4): { 250 };
        default { 75 };
    });

    if (_bestDistance >= 1200) then {
        _price = _price + 500;
    } else {
        if (_bestDistance >= 800) then {
            _price = _price + 250;
        };
    };

    if (_modeCount > 1) then {
        _price = _price + ((_modeCount min 6) * 50);
    };
};

_price

