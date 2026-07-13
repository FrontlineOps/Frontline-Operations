params ["_name"];

if (!hasInterface) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Saved kits are client-local."],
        ["kits", []]
    ]
};
if !(_name isEqualType "") exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Invalid saved-kit name."],
        ["kits", [] call FLO_fnc_storeSavedKitsLoad]
    ]
};
if ((_name splitString " ") isEqualTo []) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Name the kit first."],
        ["kits", [] call FLO_fnc_storeSavedKitsLoad]
    ]
};
if ((count _name) > 40) then { _name = _name select [0, 40]; };

private _items = [] call FLO_fnc_storeCurrentLoadoutKitItems;
if (_items isEqualTo [] || {count _items > 60}) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Equipped kit must contain between 1 and 60 Store lines."],
        ["kits", [] call FLO_fnc_storeSavedKitsLoad]
    ]
};

private _kits = [] call FLO_fnc_storeSavedKitsLoad;
private _id = "";
private _next = [];
private _nameLower = toLower _name;
{
    if (toLower (_x get "name") == _nameLower) then {
        _id = _x get "id";
    } else {
        _next pushBack _x;
    };
} forEach _kits;

private _replaced = _id != "";
if (_id == "") then {
    _id = format ["kit_%1_%2", getPlayerUID player, floor (diag_tickTime * 1000)];
};

private _record = [createHashMapFromArray [
    ["id", _id],
    ["name", _name],
    ["items", _items],
    ["updatedAt", floor diag_tickTime]
], count _next, false] call FLO_fnc_storeSavedKitValidateRecord;
_next pushBack _record;
[_next] call FLO_fnc_storeSavedKitsPersist;
["STORE", 3, format [
    "Saved kit %1: lines=%2 stored=%3",
    ["created", "replaced"] select _replaced,
    count _items,
    count _next
]] call FLO_fnc_log;

createHashMapFromArray [
    ["success", true],
    ["message", format ["Saved kit: %1.", _name]],
    ["kits", _next]
]
