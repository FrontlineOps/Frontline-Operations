params ["_access", "_category"];

private _valid = false;
private _label = _category;

{
    if ((_x select 0) isEqualTo _category) then {
        _valid = true;
        _label = _x select 1;
    };
} forEach FLO_StoreCategories;

if (!_valid) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", format ["Unknown store category: %1", _category]],
        ["category", _category],
        ["label", _label],
        ["items", []]
    ]
};

private _catalog = [_access get "sideKey"] call FLO_fnc_storeBuildCatalog;
private _itemsByCategory = _catalog get "itemsByCategory";

createHashMapFromArray [
    ["success", true],
    ["message", ""],
    ["category", _category],
    ["label", _label],
    ["items", _itemsByCategory get _category],
    ["baseType", _access get "baseType"],
    ["vehicleStoreEnabled", true],
    ["balance", FLO_MoneyHandle get "value"],
    ["personalBalance", 0],
    ["canUseFactionFunds", true],
    ["deploymentFund", 0],
    ["deploymentFundAmount", 0],
    ["tickets", 0]
]
