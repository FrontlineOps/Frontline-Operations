params ["_id"];

if (!hasInterface) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Saved kits are client-local."],
        ["kits", []]
    ]
};
if !(_id isEqualType "" && {_id != ""}) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Invalid saved-kit id."],
        ["kits", [] call FLO_fnc_storeSavedKitsLoad]
    ]
};

private _next = [];
private _found = false;
{
    if ((_x get "id") == _id) then {
        _found = true;
    } else {
        _next pushBack _x;
    };
} forEach ([] call FLO_fnc_storeSavedKitsLoad);

if (!_found) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Saved kit no longer exists."],
        ["kits", _next]
    ]
};

[_next] call FLO_fnc_storeSavedKitsPersist;
["STORE", 3, format ["Saved kit deleted: stored=%1", count _next]] call FLO_fnc_log;
createHashMapFromArray [
    ["success", true],
    ["message", "Deleted saved kit."],
    ["kits", _next]
]
