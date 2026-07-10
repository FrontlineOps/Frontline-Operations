if (!isServer) then {
    throw "Only the server can serialize base deployment state";
};

[FLO_BaseFirstFOBClaimedBySide] call FLO_fnc_baseDeployValidateState;

private _claims = createHashMapFromArray [
    ["WEST", FLO_BaseFirstFOBClaimedBySide get "WEST"],
    ["EAST", FLO_BaseFirstFOBClaimedBySide get "EAST"]
];

createHashMapFromArray [
    ["schemaVersion", 1],
    ["firstFOBClaimedBySide", _claims]
]
