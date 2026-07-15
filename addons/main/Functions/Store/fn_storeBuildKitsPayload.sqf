params [
    ["_success", true, [true]],
    ["_message", "", [""]]
];

if (!hasInterface) exitWith {
    throw "Store kits payload is client-owned";
};

createHashMapFromArray [
    ["success", _success],
    ["message", _message],
    ["kits", [] call FLO_fnc_storeSavedKitsLoad],
    ["currentItems", [] call FLO_fnc_storeCurrentLoadoutKitItems]
]
