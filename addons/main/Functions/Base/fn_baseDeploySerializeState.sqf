if (!isServer) then {
    throw "Only the server can serialize base deployment state";
};

[FLO_BaseFirstFOBClaimedBySide] call FLO_fnc_baseDeployValidateState;

private _claims = createHashMapFromArray [
    ["WEST", FLO_BaseFirstFOBClaimedBySide get "WEST"],
    ["EAST", FLO_BaseFirstFOBClaimedBySide get "EAST"]
];

createHashMapFromArray [
    ["firstFOBClaimedBySide", _claims]
]
