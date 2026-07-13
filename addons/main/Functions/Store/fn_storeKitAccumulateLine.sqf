params [
    "_itemsByKey",
    "_order",
    "_className",
    ["_container", "auto", [""]],
    ["_quantity", 1, [0]],
    ["_slot", "", [""]]
];

if !(_itemsByKey isEqualType createHashMap && {_order isEqualType []} && {_className isEqualType ""}) then {
    throw "Store kit accumulation received invalid state";
};
if (_className == "") exitWith { false };

_className = [_className] call FLO_fnc_storeNormalizeRuntimeRadioClass;
if (_className == "") exitWith { false };
if !(_container in FLO_StoreGearContainers) then { _container = "auto"; };

_quantity = floor _quantity;
if (_quantity < 1) exitWith { false };

private _category = [_className] call FLO_fnc_storeKitCategoryForClass;
if (_category == "" || {!(_category in FLO_StoreGearCategories)}) exitWith { false };

private _key = format ["%1:%2:%3:%4", _category, _container, _slot, toLower _className];
if (_key in _itemsByKey) exitWith {
    private _existing = _itemsByKey get _key;
    _existing set ["quantity", (_existing get "quantity") + _quantity];
    true
};

_itemsByKey set [_key, createHashMapFromArray [
    ["className", _className],
    ["entryKind", "gear"],
    ["category", _category],
    ["name", [_className, _category] call FLO_fnc_storeKitDisplayName],
    ["priceValue", [_className, _category, "gear"] call FLO_fnc_storePriceClass],
    ["quantity", _quantity],
    ["container", _container],
    ["slot", _slot]
]];
_order pushBack _key;
true
