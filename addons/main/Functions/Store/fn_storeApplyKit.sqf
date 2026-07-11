params ["_gearEntries"];

if (!hasInterface) exitWith {};

if (isMultiplayer && {remoteExecutedOwner isNotEqualTo 2} && {remoteExecutedOwner isNotEqualTo 0}) exitWith {
    diag_log format ["[FLO][Store] Rejected store kit application from owner %1", remoteExecutedOwner];
};

if ((typeName _gearEntries) isNotEqualTo "ARRAY") exitWith {};

private _overflowDrops = [];
private _weaponSlotFilled = createHashMapFromArray [
    ["primary", false],
    ["handgun", false],
    ["secondary", false]
];

{
    private _targetCategory = _x;

    {
        if ((typeName _x) isNotEqualTo "HASHMAP") then { continue };
        if (!(("className" in _x) && {"category" in _x})) then { continue };

        private _className = _x get "className";
        private _category = _x get "category";
        if (_category isNotEqualTo _targetCategory) then { continue };

        private _quantity = 1;
        private _container = "auto";
        private _slot = "";

        if ("quantity" in _x) then {
            _quantity = floor (_x get "quantity");
        };
        if ("container" in _x) then {
            _container = _x get "container";
        };
        if ("slot" in _x) then {
            _slot = _x get "slot";
        };
        if !(_container in FLO_StoreGearContainers) then {
            _container = "auto";
        };
        if (_quantity < 1) then { continue };

        switch (_category) do {
            case "uniforms": {
                removeUniform player;
                player forceAddUniform _className;
                [uniformContainer player] call FLO_fnc_storeClearCargo;

                for "_i" from 2 to _quantity do {
                    _overflowDrops pushBack _className;
                };
            };
            case "vests": {
                removeVest player;
                player addVest _className;
                [vestContainer player] call FLO_fnc_storeClearCargo;

                for "_i" from 2 to _quantity do {
                    _overflowDrops pushBack _className;
                };
            };
            case "backpacks": {
                removeBackpack player;
                player addBackpack _className;
                [backpackContainer player] call FLO_fnc_storeClearCargo;

                for "_i" from 2 to _quantity do {
                    _overflowDrops pushBack _className;
                };
            };
            case "headgear": {
                removeHeadgear player;
                player addHeadgear _className;
            };
            case "facewear": {
                removeGoggles player;
                player addGoggles _className;
            };
            case "primary";
            case "handgun";
            case "secondary": {
                if (_weaponSlotFilled get _category) then {
                    for "_i" from 1 to _quantity do {
                        _overflowDrops pushBack _className;
                    };
                } else {
                    private _overflow = [player, _className, _category, _quantity] call FLO_fnc_storeApplyWeaponLine;
                    _overflowDrops append _overflow;

                    if ((count _overflow) < _quantity) then {
                        _weaponSlotFilled set [_category, true];
                    };
                };
            };
            case "ammo";
            case "mines": {
                for "_i" from 1 to _quantity do {
                    if !([player, _className, _container] call FLO_fnc_storeAddInventoryItem) then {
                        _overflowDrops pushBack _className;
                    };
                };
            };
            default {
                private _itemType = _className call BIS_fnc_itemType;
                private _group = _itemType select 0;
                private _kind = _itemType select 1;

                if (_category isEqualTo "attachments") then {
                    switch (_slot) do {
                        case "primary": { player addPrimaryWeaponItem _className };
                        case "handgun": { player addHandgunItem _className };
                        case "secondary": { player addSecondaryWeaponItem _className };
                        default {
                            for "_i" from 1 to _quantity do {
                                if !([player, _className, _container] call FLO_fnc_storeAddInventoryItem) then {
                                    _overflowDrops pushBack _className;
                                };
                            };
                        };
                    };
                } else {
                    if (_slot isEqualTo "binocular") then {
                        if ((binocular player) isNotEqualTo "") then {
                            player removeWeapon (binocular player);
                        };
                        player addWeapon _className;
                    } else {
                        if ((_slot isEqualTo "assigned") || {_kind in ["GPS", "Map", "Compass", "Watch", "Radio", "NVGoggles", "Terminal"]}) then {
                            player linkItem _className;
                        } else {
                            if ((_group isEqualTo "Weapon") && {_kind in ["Binocular", "LaserDesignator"]}) then {
                                player addWeapon _className;
                            } else {
                                for "_i" from 1 to _quantity do {
                                    if !([player, _className, _container] call FLO_fnc_storeAddInventoryItem) then {
                                        _overflowDrops pushBack _className;
                                    };
                                };
                            };
                        };
                    };
                };
            };
        };
    } forEach _gearEntries;
} forEach ["uniforms", "vests", "backpacks", "headgear", "facewear", "primary", "handgun", "secondary", "attachments", "misc", "ammo", "mines"];

if (_overflowDrops isEqualTo []) then {
    ["Purchased kit applied.", "success"] call FLO_fnc_displayNotification;
} else {
    private _dropped = [player, _overflowDrops] call FLO_fnc_storeDropGearItems;
    [format ["Purchased kit applied. Dropped %1 overflow items at your feet.", _dropped], "warning"] call FLO_fnc_displayNotification;
};
