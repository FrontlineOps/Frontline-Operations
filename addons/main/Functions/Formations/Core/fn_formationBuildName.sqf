/* Builds a deterministic side/branch ordinal formation name. */
params [
    ["_sideKey", "", [""]],
    ["_branch", "", [""]],
    ["_sequence", 0, [0]]
];

if !(_sideKey in ["WEST", "EAST"]) then { throw format ["Invalid formation naming side %1", _sideKey]; };
if (_sequence <= 0) then { throw format ["Invalid formation naming sequence %1", _sequence]; };

private _base = switch (_branch) do {
    case "infantry": { 1 };
    case "motorized": { [14, 74] select (_sideKey == "WEST") };
    case "mechanized": { [4, 3] select (_sideKey == "WEST") };
    case "armor": { 1 };
    case "artillery": { [9, 11] select (_sideKey == "WEST") };
    case "air_defense": { 5 };
    case "helicopter": { 1 };
    case "fixed_wing": { 1 };
    default { throw format ["Invalid formation naming branch %1", _branch]; };
};
private _number = _base + _sequence - 1;
private _mod100 = _number mod 100;
private _suffix = if (_mod100 in [11, 12, 13]) then {
    "th"
} else {
    switch (_number mod 10) do {
        case 1: { "st" };
        case 2: { "nd" };
        case 3: { "rd" };
        default { "th" };
    }
};
private _label = switch (_branch) do {
    case "infantry": { "Infantry Regiment" };
    case "motorized": { "Motorized Regiment" };
    case "mechanized": { "Mechanized Brigade" };
    case "armor": { "Armored Brigade" };
    case "artillery": { "Field Artillery Regiment" };
    case "air_defense": { "Air Defense Regiment" };
    case "helicopter": { "Aviation Group" };
    case "fixed_wing": { "Air Regiment" };
};

format ["%1%2 %3", _number, _suffix, _label]
