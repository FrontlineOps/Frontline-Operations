params ["_itemsByCategory", "_seen", "_className", "_entryKind", "_category"];

if (_className isEqualTo "") exitWith {};
if (_category isEqualTo "") exitWith {};

private _validClass = switch (_entryKind) do {
    case "base": { _className in ["FLO_BASE_FOB", "FLO_BASE_COP"] };
    case "recruit": { isClass (configFile >> "CfgVehicles" >> _className) && {_className isKindOf "CAManBase"} };
    case "vehicle": { isClass (configFile >> "CfgVehicles" >> _className) };
    default {
        switch (_category) do {
            case "ammo": { isClass (configFile >> "CfgMagazines" >> _className) };
            case "mines": { isClass (configFile >> "CfgMagazines" >> _className) };
            case "misc": { (isClass (configFile >> "CfgWeapons" >> _className)) || {isClass (configFile >> "CfgMagazines" >> _className)} };
            case "backpacks": { isClass (configFile >> "CfgVehicles" >> _className) };
            case "facewear": { isClass (configFile >> "CfgGlasses" >> _className) };
            default { isClass (configFile >> "CfgWeapons" >> _className) };
        }
    };
};

if (!_validClass) exitWith {};

private _key = format ["%1:%2", _entryKind, toLower _className];
if (_key in _seen) exitWith {};

private _item = [_className, _entryKind, _category] call FLO_fnc_storeBuildCatalogItem;
private _bucket = _itemsByCategory get _category;
_bucket pushBack _item;
_seen set [_key, true];
