params ["_access"];

private _sideKey = _access get "sideKey";
private _catalog = [_sideKey] call FLO_fnc_storeBuildCatalog;
private _itemsByCategory = _catalog get "itemsByCategory";
private _categories = [];
private _firstCategory = "";
private _treasury = FLO_SideResources get _sideKey;
private _economy = [_treasury] call FLO_fnc_sideResourcesGetSnapshot;
private _node = _access get "logisticsNode";

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
    ["factionName", _access get "sideName"],
    ["balance", _economy get "available"],
    ["totalBalance", _economy get "balance"],
    ["committed", _economy get "committed"],
    ["nodeId", _node get "id"],
    ["nodeType", _node get "type"],
    ["nodeState", _node get "state"],
    ["throughput", round (_node get "throughput")],
    ["throughputMax", _node get "throughputMax"],
    ["categories", _categories],
    ["firstCategory", _firstCategory]
]
