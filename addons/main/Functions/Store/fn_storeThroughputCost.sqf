params ["_item"];

private _entryKind = _item get "entryKind";
private _price = _item get "priceValue";
if (_entryKind == "gear") exitWith { 0 };
if (_entryKind == "recruit") exitWith { 100 };
if (_entryKind == "supply") exitWith { 300 };
if (_entryKind == "vehicle") exitWith {
    if ((_item get "category") in ["armor", "helis", "planes"]) then {
        _price
    } else {
        ceil (_price * 0.5)
    }
};

throw format ["No throughput rule for Store entry kind %1", _entryKind]
