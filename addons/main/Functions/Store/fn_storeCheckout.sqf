params ["_access", "_cart"];

if (!isServer) exitWith {
    createHashMapFromArray [["success", false], ["message", "Checkout must run on the server."]]
};
if !(_cart isEqualType []) exitWith {
    createHashMapFromArray [["success", false], ["message", "Invalid checkout cart."]]
};
if (_cart isEqualTo []) exitWith {
    createHashMapFromArray [["success", false], ["message", "Cart is empty."]]
};

private _sideKey = _access get "sideKey";
private _player = _access get "player";
private _owner = _access get "owner";
private _network = _access get "logisticsNetwork";
private _node = _access get "logisticsNode";
private _nodeId = _node get "id";
private _treasury = FLO_SideResources get _sideKey;
private _catalog = [_sideKey] call FLO_fnc_storeBuildCatalog;
private _itemsByCategory = _catalog get "itemsByCategory";
private _itemIndex = createHashMap;

{
    private _category = _x select 0;
    {
        _itemIndex set [format ["%1:%2", _x get "entryKind", toLower (_x get "className")], _x];
    } forEach (_itemsByCategory get _category);
} forEach FLO_StoreCatalogCategories;

private _valid = true;
private _message = "";
private _total = 0;
private _throughputDemand = 0;
private _gearEntries = [];
private _vehicleJobs = [];
private _recruitJobs = [];
private _supplyJobs = [];

{
    if (!_valid) then { continue };
    if !(_x isEqualType createHashMap) then {
        _valid = false;
        _message = "Invalid cart line.";
        continue;
    };
    if !("className" in _x && {"entryKind" in _x}) then {
        _valid = false;
        _message = "Cart line is missing item data.";
        continue;
    };

    private _className = _x get "className";
    private _entryKind = _x get "entryKind";
    private _quantity = if ("quantity" in _x) then { floor (_x get "quantity") } else { 1 };
    private _container = if ("container" in _x) then { _x get "container" } else { "auto" };
    private _slot = if ("slot" in _x) then { _x get "slot" } else { "" };

    if !(
        _className isEqualType ""
        && {_entryKind isEqualType ""}
        && {_quantity isEqualType 0}
        && {_container isEqualType ""}
        && {_slot isEqualType ""}
    ) then {
        _valid = false;
        _message = "Cart line has invalid item data.";
        continue;
    };
    if (_quantity < 1 || {_quantity > 20}) then {
        _valid = false;
        _message = "Cart quantity is invalid.";
        continue;
    };

    private _key = format ["%1:%2", _entryKind, toLower _className];
    if !(_key in _itemIndex) then {
        _valid = false;
        _message = format ["%1 is not available for this side.", _className];
        continue;
    };

    private _item = _itemIndex get _key;
    private _capability = [_item get "category"] call FLO_fnc_storeCapabilityForCategory;
    private _capabilityCheck = [_network, _nodeId, _capability, 0] call FLO_fnc_logisticsNetworkCanNodeFulfill;
    if !(_capabilityCheck select 0) then {
        _valid = false;
        _message = _capabilityCheck select 1;
        continue;
    };

    _total = _total + ((_item get "priceValue") * _quantity);
    _throughputDemand = _throughputDemand + (([_item] call FLO_fnc_storeThroughputCost) * _quantity);

    switch (_item get "entryKind") do {
        case "vehicle": {
            for "_i" from 1 to _quantity do { _vehicleJobs pushBack _item; };
        };
        case "recruit": {
            for "_i" from 1 to _quantity do { _recruitJobs pushBack _item; };
        };
        case "supply": {
            for "_i" from 1 to _quantity do { _supplyJobs pushBack _item; };
        };
        default {
            _gearEntries pushBack createHashMapFromArray [
                ["className", _item get "className"],
                ["name", _item get "name"],
                ["category", _item get "category"],
                ["container", _container],
                ["quantity", _quantity],
                ["slot", _slot]
            ];
        };
    };
} forEach _cart;

private _economyBefore = [_treasury] call FLO_fnc_sideResourcesGetSnapshot;
if (!_valid) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", _message],
        ["balance", _economyBefore get "available"],
        ["totalBalance", _economyBefore get "balance"],
        ["committed", _economyBefore get "committed"]
    ]
};
private _throughputCheck = [_network, _nodeId, "gear", _throughputDemand] call FLO_fnc_logisticsNetworkCanNodeFulfill;
if !(_throughputCheck select 0) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", _throughputCheck select 1],
        ["balance", _economyBefore get "available"],
        ["totalBalance", _economyBefore get "balance"],
        ["committed", _economyBefore get "committed"]
    ]
};
if ((_economyBefore get "available") < _total) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", format ["Not enough available resources. Required: %1; available: %2.", _total, _economyBefore get "available"]],
        ["balance", _economyBefore get "available"],
        ["totalBalance", _economyBefore get "balance"],
        ["committed", _economyBefore get "committed"]
    ]
};

FLO_StoreCheckoutSequence = FLO_StoreCheckoutSequence + 1;
private _reservationId = format ["STORE:%1:%2:%3", _sideKey, _owner, FLO_StoreCheckoutSequence];
private _reserved = true;
if (_total > 0) then {
    _reserved = _treasury call ["reserve", [
        _reservationId,
        _total,
        "PLAYER_REQUISITION",
        "Store checkout",
        name _player,
        _nodeId
    ]];
};
if (!_reserved) exitWith {
    private _economy = [_treasury] call FLO_fnc_sideResourcesGetSnapshot;
    createHashMapFromArray [
        ["success", false],
        ["message", "Resources changed before checkout could be reserved."],
        ["balance", _economy get "available"],
        ["totalBalance", _economy get "balance"],
        ["committed", _economy get "committed"]
    ]
};

private _throughputConsumed = [_network, _nodeId, _throughputDemand, "Player Store checkout"] call FLO_fnc_logisticsNetworkConsumeThroughput;
if (!_throughputConsumed) exitWith {
    if (_total > 0) then { _treasury call ["releaseReservation", [_reservationId, "Store local supplies changed"]]; };
    private _economy = [_treasury] call FLO_fnc_sideResourcesGetSnapshot;
    createHashMapFromArray [
        ["success", false],
        ["message", "Local supplies changed before checkout completed."],
        ["balance", _economy get "available"],
        ["totalBalance", _economy get "balance"],
        ["committed", _economy get "committed"]
    ]
};

if (_total > 0 && {!(_treasury call ["commitReservation", [_reservationId, _total, "Player Store checkout"]])}) then {
    throw format ["Failed to commit guaranteed Store reservation %1", _reservationId];
};

private _refund = 0;
private _throughputRefund = 0;
{
    if (isNull ([_access, _x get "className"] call FLO_fnc_storeSpawnVehicle)) then {
        _refund = _refund + (_x get "priceValue");
        _throughputRefund = _throughputRefund + ([_x] call FLO_fnc_storeThroughputCost);
    };
} forEach _vehicleJobs;

{
    if (isNull ([_access] call FLO_fnc_storeSpawnSupplyShipment)) then {
        _refund = _refund + (_x get "priceValue");
        _throughputRefund = _throughputRefund + ([_x] call FLO_fnc_storeThroughputCost);
    };
} forEach _supplyJobs;

if (_refund > 0) then {
    [_treasury, _refund, "REFUND", "Failed Store asset creation", "STORE", _nodeId, true] call FLO_fnc_sideResourcesAddResources;
};
if (_throughputRefund > 0) then {
    [_network, _nodeId, _throughputRefund, "Failed Store asset creation"] call FLO_fnc_logisticsNetworkRestoreThroughput;
};

if (_gearEntries isNotEqualTo []) then {
    if (_owner <= 0) then {
        if (hasInterface) then { [_gearEntries] call FLO_fnc_storeApplyKit; };
    } else {
        [_gearEntries] remoteExecCall ["FLO_fnc_storeApplyKit", _owner];
    };
};
if (_recruitJobs isNotEqualTo []) then {
    private _recruitClasses = _recruitJobs apply { _x get "className" };
    if (_owner <= 0) then {
        if (hasInterface) then { [_recruitClasses] call FLO_fnc_storeRecruitAI; };
    } else {
        [_recruitClasses] remoteExecCall ["FLO_fnc_storeRecruitAI", _owner];
    };
};

private _parts = [];
if (_gearEntries isNotEqualTo []) then { _parts pushBack format ["%1 gear lines", count _gearEntries]; };
if (_vehicleJobs isNotEqualTo []) then { _parts pushBack format ["%1 vehicles", count _vehicleJobs]; };
if (_recruitJobs isNotEqualTo []) then { _parts pushBack format ["%1 recruits", count _recruitJobs]; };
if (_supplyJobs isNotEqualTo []) then { _parts pushBack format ["%1 supply shipments", count _supplyJobs]; };
if (_refund > 0) then { _parts pushBack format ["%1 refunded", _refund]; };

private _spent = _total - _refund;
private _economyAfter = [_treasury] call FLO_fnc_sideResourcesGetSnapshot;
createHashMapFromArray [
    ["success", true],
    ["message", format ["Purchased %1 for %2.", _parts joinString ", ", _spent]],
    ["balance", _economyAfter get "available"],
    ["totalBalance", _economyAfter get "balance"],
    ["committed", _economyAfter get "committed"],
    ["nodeType", _node get "type"],
    ["nodeState", _node get "state"],
    ["throughput", round (_node get "throughput")],
    ["throughputMax", _node get "throughputMax"],
    ["resupplyAmount", _node get "refillAmount"],
    ["resupplyIntervalSeconds", _network get "NODE_REFILL_INTERVAL"],
    ["spent", _spent],
    ["gearCount", count _gearEntries],
    ["vehicleCount", count _vehicleJobs],
    ["shipmentCount", count _supplyJobs]
]
