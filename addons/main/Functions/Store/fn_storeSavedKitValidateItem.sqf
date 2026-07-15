params ["_entry", "_kitId", "_lineIndex"];

if !(_entry isEqualType createHashMap) then {
    throw format ["Store saved kit %1 line %2 is not a HashMap", _kitId, _lineIndex];
};
private _requiredKeys = ["className", "entryKind", "category", "name", "priceValue", "quantity", "container", "slot"];
{
    if !(_x in _entry) then {
        throw format ["Store saved kit %1 line %2 is missing %3", _kitId, _lineIndex, _x];
    };
} forEach _requiredKeys;
private _unexpectedKeys = (keys _entry) select {!(_x in _requiredKeys)};
if (_unexpectedKeys isNotEqualTo []) then {
    throw format ["Store saved kit %1 line %2 has unexpected fields %3", _kitId, _lineIndex, _unexpectedKeys];
};

private _className = _entry get "className";
private _entryKind = _entry get "entryKind";
private _category = _entry get "category";
private _name = _entry get "name";
private _priceValue = _entry get "priceValue";
private _quantity = _entry get "quantity";
private _container = _entry get "container";
private _slot = _entry get "slot";

if !(
    _className isEqualType ""
    && {_entryKind isEqualType ""}
    && {_category isEqualType ""}
    && {_name isEqualType ""}
    && {_priceValue isEqualType 0}
    && {_quantity isEqualType 0}
    && {_container isEqualType ""}
    && {_slot isEqualType ""}
) then {
    throw format ["Store saved kit %1 line %2 has invalid field types", _kitId, _lineIndex];
};
if (_className == "" || {_entryKind != "gear"} || {!(_category in FLO_StoreGearCategories)}) then {
    throw format ["Store saved kit %1 line %2 has invalid item identity", _kitId, _lineIndex];
};
if (_name == "" || {_priceValue < 0}) then {
    throw format ["Store saved kit %1 line %2 has invalid display data", _kitId, _lineIndex];
};
if !(_container in FLO_StoreGearContainers) then {
    throw format ["Store saved kit %1 line %2 has invalid container %3", _kitId, _lineIndex, _container];
};
if !(_slot in ["", "primary", "handgun", "secondary", "assigned", "uniform", "vest", "backpack", "headgear", "facewear", "binocular"]) then {
    throw format ["Store saved kit %1 line %2 has invalid slot %3", _kitId, _lineIndex, _slot];
};
if (_quantity != floor _quantity || {_quantity < 1} || {_quantity > 20}) then {
    throw format ["Store saved kit %1 line %2 has invalid quantity %3", _kitId, _lineIndex, _quantity];
};

private _normalized = [];
private _remaining = _quantity;
while {_remaining > 0} do {
    private _chunk = _remaining min 20;
    _normalized pushBack createHashMapFromArray [
        ["className", _className],
        ["entryKind", _entryKind],
        ["category", _category],
        ["name", _name],
        ["priceValue", _priceValue],
        ["quantity", _chunk],
        ["container", _container],
        ["slot", _slot]
    ];
    _remaining = _remaining - _chunk;
};
_normalized
