params ["_access", "_cart"];

if (!isServer) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Checkout must run on the server."]
    ]
};

if ((typeName _cart) isNotEqualTo "ARRAY") exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Invalid checkout cart."]
    ]
};

if ((count _cart) <= 0) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Cart is empty."]
    ]
};

private _sideKey = _access get "sideKey";
private _player = _access get "player";
private _owner = _access get "owner";
private _catalog = [_sideKey] call FLO_fnc_storeBuildCatalog;
private _itemsByCategory = _catalog get "itemsByCategory";
private _itemIndex = createHashMap;

{
    private _category = _x select 0;

    {
        private _key = format ["%1:%2", _x get "entryKind", toLower (_x get "className")];
        _itemIndex set [_key, _x];
    } forEach (_itemsByCategory get _category);
} forEach FLO_StoreCatalogCategories;

private _ok = true;
private _message = "";
private _total = 0;
private _gearEntries = [];
private _vehicleJobs = [];
private _recruitJobs = [];
private _baseJobs = [];

{
    if (_ok) then {
        if ((typeName _x) isNotEqualTo "HASHMAP") then {
            _ok = false;
            _message = "Invalid cart line.";
        } else {
            if (!(("className" in _x) && {"entryKind" in _x})) then {
                _ok = false;
                _message = "Cart line is missing item data.";
            } else {
                private _className = _x get "className";
                private _entryKind = _x get "entryKind";
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

                if (((typeName _className) isNotEqualTo "STRING") || {((typeName _entryKind) isNotEqualTo "STRING") || {((typeName _quantity) isNotEqualTo "SCALAR") || {((typeName _container) isNotEqualTo "STRING") || {((typeName _slot) isNotEqualTo "STRING")}}}}) then {
                    _ok = false;
                    _message = "Cart line has invalid item data.";
                } else {
                    if ((_quantity < 1) || {_quantity > 20}) then {
                        _ok = false;
                        _message = "Cart quantity is invalid.";
                    } else {
                        private _key = format ["%1:%2", _entryKind, toLower _className];

                        if !(_key in _itemIndex) then {
                            _ok = false;
                            _message = format ["%1 is not available for this side.", _className];
                        } else {
                            private _item = _itemIndex get _key;
                            _total = _total + ((_item get "priceValue") * _quantity);

                            switch (_item get "entryKind") do {
                                case "vehicle": {
                                    for "_i" from 1 to _quantity do {
                                        _vehicleJobs pushBack _item;
                                    };
                                };
                                case "recruit": {
                                    for "_i" from 1 to _quantity do {
                                        _recruitJobs pushBack _item;
                                    };
                                };
                                case "base": {
                                    for "_i" from 1 to _quantity do {
                                        _baseJobs pushBack _item;
                                    };
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
                        };
                    };
                };
            };
        };
    };
} forEach _cart;

if (!_ok) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", _message],
        ["balance", FLO_MoneyHandle get "value"],
        ["pendingVehicles", []]
    ]
};

if ((count _baseJobs) > 1) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Deploy one base per checkout."],
        ["balance", FLO_MoneyHandle get "value"],
        ["pendingVehicles", []]
    ]
};

private _money = FLO_MoneyHandle get "value";

if (_money < _total) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", format ["Not enough resources. Required: %1.", _total]],
        ["balance", _money],
        ["pendingVehicles", []]
    ]
};

private _baseDeployMessage = "";

if (_baseJobs isNotEqualTo []) then {
    private _baseJob = _baseJobs select 0;
    private _baseType = ["FOB", "COP"] select ((_baseJob get "className") isEqualTo "FLO_BASE_COP");
    private _deploy = [_player, _baseType] call FLO_fnc_storeDeployBase;

    if !(_deploy get "success") then {
        _ok = false;
        _message = _deploy get "message";
    } else {
        _baseDeployMessage = _deploy get "message";
    };
};

if (!_ok) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", _message],
        ["balance", FLO_MoneyHandle get "value"],
        ["pendingVehicles", []]
    ]
};

private _newMoney = _money - _total;
FLO_MoneyHandle set ["value", _newMoney];
[_newMoney] call FLO_fnc_publishMoneyState;

{
    [_access, _x get "className"] call FLO_fnc_storeSpawnVehicle;
} forEach _vehicleJobs;

if (_gearEntries isNotEqualTo []) then {
    if (_owner <= 0) then {
        if (hasInterface) then {
            [_gearEntries] call FLO_fnc_storeApplyKit;
        };
    } else {
        [_gearEntries] remoteExecCall ["FLO_fnc_storeApplyKit", _owner];
    };
};

if (_recruitJobs isNotEqualTo []) then {
    private _recruitClasses = _recruitJobs apply { _x get "className" };

    if (_owner <= 0) then {
        if (hasInterface) then {
            [_recruitClasses] call FLO_fnc_storeRecruitAI;
        };
    } else {
        [_recruitClasses] remoteExecCall ["FLO_fnc_storeRecruitAI", _owner];
    };
};

private _parts = [];
if (_gearEntries isNotEqualTo []) then { _parts pushBack format ["%1 gear lines", count _gearEntries] };
if (_vehicleJobs isNotEqualTo []) then { _parts pushBack format ["%1 vehicles", count _vehicleJobs] };
if (_recruitJobs isNotEqualTo []) then { _parts pushBack format ["%1 recruits", count _recruitJobs] };
if (_baseJobs isNotEqualTo []) then { _parts pushBack _baseDeployMessage };

createHashMapFromArray [
    ["success", true],
    ["approvalPending", false],
    ["message", format ["Purchased %1 for %2.", (_parts joinString ", "), _total]],
    ["balance", _newMoney],
    ["personalBalance", 0],
    ["canUseFactionFunds", true],
    ["deploymentFund", 0],
    ["deploymentFundAmount", 0],
    ["deploymentFundSpent", 0],
    ["personalSpent", 0],
    ["factionSpent", _total],
    ["tickets", 0],
    ["spent", _total],
    ["gearCount", count _gearEntries],
    ["vehicleCount", count _vehicleJobs],
    ["pendingVehicles", []]
]
