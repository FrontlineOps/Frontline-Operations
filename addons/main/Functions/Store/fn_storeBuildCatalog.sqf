params ["_sideKey"];

if (!isServer) exitWith {
    throw "[FLO][Store] Catalogs are server-owned";
};

private _cacheKey = _sideKey;
if (_cacheKey in FLO_StoreCatalogCache) exitWith {
    FLO_StoreCatalogCache get _cacheKey
};

private _sourceCatalog = FLO_FactionCatalog get _sideKey;
private _itemsByCategory = createHashMap;

{
    _itemsByCategory set [_x select 0, []];
} forEach FLO_StoreCatalogCategories;

private _seen = createHashMap;
private _unitClasses = [];

{
    if (_x in _sourceCatalog) then {
        {
            if ((typeName _x) isEqualTo "STRING") then {
                _unitClasses pushBackUnique _x;
            };
        } forEach (_sourceCatalog get _x);
    };
} forEach ["officers", "groundInfantryUnits", "groundSpecOpsUnits"];

{
    [_itemsByCategory, _seen, _x] call FLO_fnc_storeAppendUnitGear;
    [_itemsByCategory, _seen, _x, "recruit", "recruits"] call FLO_fnc_storeAppendCatalogItem;
} forEach _unitClasses;

private _vehiclePoolKeys = [
    "groundMotorized",
    "groundMechanized",
    "groundArmor",
    "groundTransport",
    "groundArtillery",
    "airTransport",
    "airHeli",
    "airJet",
    "airDrone",
    "groundDrone",
    "staticAA",
    "boat"
];

{
    if (_x in _sourceCatalog) then {
        {
            if ((typeName _x) isEqualTo "STRING") then {
                private _category = [_x] call FLO_fnc_storeCategoryForVehicle;
                if (_category isNotEqualTo "backpacks") then {
                    [_itemsByCategory, _seen, _x, "vehicle", _category] call FLO_fnc_storeAppendCatalogItem;
                };
            };
        } forEach (_sourceCatalog get _x);
    };
} forEach _vehiclePoolKeys;

[_itemsByCategory, _seen, FLO_StoreSupplyShipmentClass, "supply", "logistics"] call FLO_fnc_storeAppendCatalogItem;
private _optionalItemCounts = [_itemsByCategory, _seen] call FLO_fnc_storeAppendSupportItems;

{
    private _category = _x select 0;
    private _items = _itemsByCategory get _category;
    _items = [_items, [], { _x get "name" }, "ASCEND"] call BIS_fnc_sortBy;
    _itemsByCategory set [_category, _items];
} forEach FLO_StoreCatalogCategories;

private _catalog = createHashMapFromArray [
    ["sideKey", _sideKey],
    ["itemsByCategory", _itemsByCategory],
    ["createdAt", diag_tickTime]
];

FLO_StoreCatalogCache set [_cacheKey, _catalog];

["STORE", 3, format [
    "Catalog built: side=%1 entries=%2 optionalMods=%3 optionalItems=%4",
    _sideKey,
    count _seen,
    FLO_StoreOptionalModIndex get "activeMods",
    _optionalItemCounts
]] call FLO_fnc_log;
_catalog
