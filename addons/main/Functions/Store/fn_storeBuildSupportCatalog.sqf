private _cache = FLO_StoreSupportCatalogCache;
if (_cache get "ready") exitWith { _cache };

private _items = +FLO_StoreSupportCatalogItems;
private _seen = createHashMap;
private _counts = createHashMap;

{
    _x params ["_className"];
    _seen set [format ["gear:%1", toLower _className], true];
} forEach _items;

{
    _counts set [_x, 0];
} forEach (FLO_StoreOptionalModIndex get "activeMods");

{
    private _cfg = _x;
    private _scope = (getNumber (_cfg >> "scope")) max (getNumber (_cfg >> "scopeArsenal"));
    if (_scope < 2 || {getText (_cfg >> "displayName") == ""}) then { continue };

    private _className = configName _cfg;
    private _category = [_className] call FLO_fnc_storeCategoryForWeapon;
    if (_category == "") then { continue };

    private _mod = [_cfg] call FLO_fnc_storeOptionalModForConfig;
    private _isGps = ((_className call BIS_fnc_itemType) param [1, ""]) == "GPS";
    if (_mod == "" && {!_isGps}) then { continue };

    private _key = format ["gear:%1", toLower _className];
    if (_key in _seen) then { continue };

    _items pushBack [_className, "gear", _category];
    _seen set [_key, true];
    if (_mod != "") then {
        _counts set [_mod, (_counts get _mod) + 1];
    };
} forEach ("true" configClasses (configFile >> "CfgWeapons"));

{
    private _cfg = _x;
    private _scope = (getNumber (_cfg >> "scope")) max (getNumber (_cfg >> "scopeArsenal"));
    if (_scope < 2 || {getText (_cfg >> "displayName") == ""}) then { continue };

    private _mod = [_cfg] call FLO_fnc_storeOptionalModForConfig;
    if (_mod == "") then { continue };

    private _className = configName _cfg;
    private _key = format ["gear:%1", toLower _className];
    if (_key in _seen) then { continue };

    private _category = if ([_cfg] call FLO_fnc_storeIsMineMagazine) then {
        "mines"
    } else {
        ["ammo", "misc"] select ([_cfg] call FLO_fnc_storeIsItemBackedMagazine)
    };

    _items pushBack [_className, "gear", _category];
    _seen set [_key, true];
    _counts set [_mod, (_counts get _mod) + 1];
} forEach ("true" configClasses (configFile >> "CfgMagazines"));

{
    private _cfg = _x;
    private _scope = (getNumber (_cfg >> "scope")) max (getNumber (_cfg >> "scopeArsenal"));
    if (
        _scope < 2
        || {getNumber (_cfg >> "isBackpack") != 1}
        || {getText (_cfg >> "displayName") == ""}
    ) then { continue };

    private _mod = [_cfg] call FLO_fnc_storeOptionalModForConfig;
    if (_mod == "") then { continue };

    private _className = configName _cfg;
    private _key = format ["gear:%1", toLower _className];
    if (_key in _seen) then { continue };

    _items pushBack [_className, "gear", "backpacks"];
    _seen set [_key, true];
    _counts set [_mod, (_counts get _mod) + 1];
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

{
    private _cfg = _x;
    private _scope = (getNumber (_cfg >> "scope")) max (getNumber (_cfg >> "scopeArsenal"));
    if (_scope < 2 || {getText (_cfg >> "displayName") == ""}) then { continue };

    private _mod = [_cfg] call FLO_fnc_storeOptionalModForConfig;
    if (_mod == "") then { continue };

    private _className = configName _cfg;
    private _key = format ["gear:%1", toLower _className];
    if (_key in _seen) then { continue };

    _items pushBack [_className, "gear", "facewear"];
    _seen set [_key, true];
    _counts set [_mod, (_counts get _mod) + 1];
} forEach ("true" configClasses (configFile >> "CfgGlasses"));

_cache set ["items", _items];
_cache set ["counts", _counts];
_cache set ["ready", true];
_cache
