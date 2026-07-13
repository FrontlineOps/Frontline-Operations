params ["_record", "_recordIndex", ["_legacy", false, [false]]];

if !(_record isEqualType createHashMap) then {
    throw format ["Store saved-kit record %1 is not a HashMap", _recordIndex];
};
{
    if !(_x in _record) then {
        throw format ["Store saved-kit record %1 is missing %2", _recordIndex, _x];
    };
} forEach ["id", "name", "items", "updatedAt"];

private _id = _record get "id";
private _name = _record get "name";
private _items = _record get "items";
private _updatedAt = _record get "updatedAt";
if !(_id isEqualType "" && {_name isEqualType ""} && {_items isEqualType []} && {_updatedAt isEqualType 0}) then {
    throw format ["Store saved-kit record %1 has invalid field types", _recordIndex];
};
if (_id == "" || {_name == ""} || {count _name > 40}) then {
    throw format ["Store saved-kit record %1 has invalid identity", _recordIndex];
};
if (_items isEqualTo []) then {
    throw format ["Store saved kit %1 has no item lines", _id];
};

private _normalizedItems = [];
for "_i" from 0 to ((count _items) - 1) do {
    _normalizedItems append ([_items select _i, _id, _i, _legacy] call FLO_fnc_storeSavedKitValidateItem);
};
if ((count _normalizedItems) > 60) then {
    throw format ["Store saved kit %1 exceeds 60 normalized item lines", _id];
};

createHashMapFromArray [
    ["id", _id],
    ["name", _name],
    ["items", _normalizedItems],
    ["updatedAt", _updatedAt]
]
