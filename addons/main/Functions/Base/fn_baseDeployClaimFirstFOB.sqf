params [["_side", sideUnknown]];

if (!isServer) then {
    throw "Only the server can claim a first FOB entitlement";
};
if !(_side in [west, east]) then {
    throw format ["Cannot claim first FOB entitlement for unsupported side %1", _side];
};

[FLO_BaseFirstFOBClaimedBySide] call FLO_fnc_baseDeployValidateState;
private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
if (FLO_BaseFirstFOBClaimedBySide get _sideKey) then {
    throw format ["First FOB entitlement for %1 was already claimed", _sideKey];
};

FLO_BaseFirstFOBClaimedBySide set [_sideKey, true];
publicVariable "FLO_BaseFirstFOBClaimedBySide";
["FLO_Base_FirstFOBClaimed", [FLO_BaseFirstFOBClaimedBySide]] call CBA_fnc_globalEvent;
["BASE", 2, format ["%1 claimed its free first FOB deployment", _sideKey]] call FLO_fnc_log;

true
