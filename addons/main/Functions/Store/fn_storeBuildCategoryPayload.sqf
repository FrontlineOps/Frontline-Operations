params ["_access", "_category"];

private _valid = false;
private _label = _category;
{
    if ((_x select 0) == _category) exitWith {
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
private _sourceItems = (_catalog get "itemsByCategory") get _category;
private _network = _access get "logisticsNetwork";
private _node = _access get "logisticsNode";
private _items = [];

{
    private _sourceItem = _x;
    private _item = createHashMap;
    { _item set [_x, _y]; } forEach _sourceItem;

    private _throughputCost = [_item] call FLO_fnc_storeThroughputCost;
    private _capability = [_item get "category"] call FLO_fnc_storeCapabilityForCategory;
    private _fulfillment = [
        _network,
        _node get "id",
        _capability,
        _throughputCost
    ] call FLO_fnc_logisticsNetworkCanNodeFulfill;
    _item set ["throughputCost", _throughputCost];
    _item set ["locked", !(_fulfillment select 0)];
    _item set ["lockReason", _fulfillment select 1];
    _items pushBack _item;
} forEach _sourceItems;

private _treasury = FLO_SideResources get (_access get "sideKey");
private _economy = [_treasury] call FLO_fnc_sideResourcesGetSnapshot;

createHashMapFromArray [
    ["success", true],
    ["message", ""],
    ["category", _category],
    ["label", _label],
    ["items", _items],
    ["balance", _economy get "available"],
    ["totalBalance", _economy get "balance"],
    ["committed", _economy get "committed"],
    ["nodeId", _node get "id"],
    ["nodeType", _node get "type"],
    ["nodeState", _node get "state"],
    ["throughput", round (_node get "throughput")],
    ["throughputMax", _node get "throughputMax"]
]
