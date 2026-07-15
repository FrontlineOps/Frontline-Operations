params ["_itemsByCategory", "_seen"];

private _supportCatalog = [] call FLO_fnc_storeBuildSupportCatalog;
{
    _x params ["_className", "_entryKind", "_category"];
    [_itemsByCategory, _seen, _className, _entryKind, _category] call FLO_fnc_storeAppendCatalogItem;
} forEach (_supportCatalog get "items");

_supportCatalog get "counts"
