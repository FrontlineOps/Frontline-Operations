params ["_cfg"];

private _className = configName _cfg;

if (!FLO_StorePlaceableMagazineCacheReady) then {
    private _putCfg = configFile >> "CfgWeapons" >> "Put";

    {
        private _muzzleCfg = _putCfg >> _x;

        {
            FLO_StorePlaceableMagazineCache set [_x, true];
        } forEach getArray (_muzzleCfg >> "magazines");
    } forEach getArray (_putCfg >> "muzzles");

    FLO_StorePlaceableMagazineCacheReady = true;
};

if (_className in FLO_StorePlaceableMagazineCache) exitWith { true };

private _itemType = _className call BIS_fnc_itemType;
private _group = _itemType param [0, ""];

_group isEqualTo "Mine"
