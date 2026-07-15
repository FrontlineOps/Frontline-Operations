params ["_itemsByCategory", "_seen"];

private _beforeCount = count _seen;
{
    _x params ["_className", "_entryKind", "_category"];
    [_itemsByCategory, _seen, _className, _entryKind, _category] call FLO_fnc_storeAppendCatalogItem;
} forEach FLO_StoreSupportCatalogItems;

(count _seen) - _beforeCount
