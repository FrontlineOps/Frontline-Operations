params ["_itemsByKey", "_order", "_cargo", "_container"];

if !(_cargo isEqualType [] && {_container isEqualType ""}) then {
    throw "Store kit cargo extraction received invalid data";
};
if ((count _cargo) != 2) then {
    throw format ["Store kit cargo pair has %1 elements", count _cargo];
};

private _classes = _cargo select 0;
private _counts = _cargo select 1;
if !(_classes isEqualType [] && {_counts isEqualType []} && {count _classes == count _counts}) then {
    throw "Store kit cargo class/count arrays are malformed";
};

for "_i" from 0 to ((count _classes) - 1) do {
    [_itemsByKey, _order, _classes select _i, _container, _counts select _i] call FLO_fnc_storeKitAccumulateLine;
};
true
