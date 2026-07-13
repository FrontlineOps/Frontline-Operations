if (!hasInterface) exitWith { [] };

private _itemsByKey = createHashMap;
private _order = [];

{
    _x params ["_weapon", "_items", "_magazines", "_slot"];
    [_itemsByKey, _order, _weapon, "auto", 1, _slot] call FLO_fnc_storeKitAccumulateLine;
    {
        [_itemsByKey, _order, _x, "auto", 1, _slot] call FLO_fnc_storeKitAccumulateLine;
    } forEach _items;
    {
        [_itemsByKey, _order, _x] call FLO_fnc_storeKitAccumulateLine;
    } forEach _magazines;
} forEach [
    [primaryWeapon player, primaryWeaponItems player, primaryWeaponMagazine player, "primary"],
    [handgunWeapon player, handgunItems player, handgunMagazine player, "handgun"],
    [secondaryWeapon player, secondaryWeaponItems player, secondaryWeaponMagazine player, "secondary"]
];

{
    [_itemsByKey, _order, _x, "auto", 1, "assigned"] call FLO_fnc_storeKitAccumulateLine;
} forEach assignedItems player;

{
    _x params ["_className", "_slot"];
    [_itemsByKey, _order, _className, "auto", 1, _slot] call FLO_fnc_storeKitAccumulateLine;
} forEach [
    [uniform player, "uniform"],
    [vest player, "vest"],
    [backpack player, "backpack"],
    [headgear player, "headgear"],
    [goggles player, "facewear"],
    [binocular player, "binocular"]
];

{
    _x params ["_containerObject", "_container"];
    if (!isNull _containerObject) then {
        [_itemsByKey, _order, getItemCargo _containerObject, _container] call FLO_fnc_storeKitAppendCargo;
        [_itemsByKey, _order, getMagazineCargo _containerObject, _container] call FLO_fnc_storeKitAppendCargo;
    };
} forEach [
    [uniformContainer player, "uniform"],
    [vestContainer player, "vest"],
    [backpackContainer player, "backpack"]
];

private _items = [];
{
    private _entry = _itemsByKey get _x;
    private _remaining = _entry get "quantity";
    while {_remaining > 0} do {
        private _quantity = _remaining min 20;
        _items pushBack createHashMapFromArray [
            ["className", _entry get "className"],
            ["entryKind", _entry get "entryKind"],
            ["category", _entry get "category"],
            ["name", _entry get "name"],
            ["priceValue", _entry get "priceValue"],
            ["quantity", _quantity],
            ["container", _entry get "container"],
            ["slot", _entry get "slot"]
        ];
        _remaining = _remaining - _quantity;
    };
} forEach _order;

_items
