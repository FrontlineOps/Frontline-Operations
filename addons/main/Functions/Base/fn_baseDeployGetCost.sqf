params [
    ["_side", sideUnknown],
    ["_baseType", "FOB", [""]]
];

if !(_side in [west, east]) then {
    throw format ["Cannot calculate base deployment cost for unsupported side %1", _side];
};

private _type = toUpper _baseType;
if !(_type in ["FOB", "COP"]) then {
    throw format ["Cannot calculate deployment cost for unsupported base type %1", _baseType];
};

[FLO_BaseFirstFOBClaimedBySide] call FLO_fnc_baseDeployValidateState;

if (_type == "COP") exitWith { FLO_BaseCOPDeployCost };

private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
if !(FLO_BaseFirstFOBClaimedBySide get _sideKey) exitWith { 0 };

FLO_BaseFOBDeployCost
