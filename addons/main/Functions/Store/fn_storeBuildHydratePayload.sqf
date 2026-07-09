params ["_access"];

private _sideKey = _access get "sideKey";
private _catalog = [_sideKey] call FLO_fnc_storeBuildCatalog;
private _itemsByCategory = _catalog get "itemsByCategory";
private _categories = [];
private _firstCategory = "";

{
    private _category = _x select 0;
    private _label = _x select 1;
    private _count = count (_itemsByCategory get _category);

    _categories pushBack createHashMapFromArray [
        ["id", _category],
        ["label", _label],
        ["count", _count]
    ];

    if ((_firstCategory isEqualTo "") && {_count > 0}) then {
        _firstCategory = _category;
    };
} forEach FLO_StoreCategories;

createHashMapFromArray [
    ["success", true],
    ["message", ""],
    ["sideKey", _sideKey],
    ["sideName", _access get "sideName"],
    ["factionClass", _sideKey],
    ["factionName", _access get "sideName"],
    ["baseType", _access get "baseType"],
    ["vehicleStoreEnabled", true],
    ["balance", FLO_MoneyHandle get "value"],
    ["personalBalance", 0],
    ["canUseFactionFunds", true],
    ["deploymentFund", 0],
    ["deploymentFundAmount", 0],
    ["tickets", 0],
    ["categories", _categories],
    ["firstCategory", _firstCategory],
    ["fobNetId", _access get "baseNetId"],
    ["pendingVehicles", []]
]
