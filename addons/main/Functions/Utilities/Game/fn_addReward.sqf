params [
    ["_amount", 0, [0]],
    ["_side", west, [west]],
    ["_reason", "Player field reward", [""]],
    ["_referenceId", "", [""]]
];

if (!isServer) exitWith { false };
if !(_side in [west, east]) then { throw format ["Reward has unsupported side %1", _side]; };
if (_amount <= 0) then { throw format ["Reward amount must be positive, got %1", _amount]; };

private _sideKey = [_side] call FLO_fnc_sideKey;
private _treasury = FLO_SideResources get _sideKey;
[_treasury, _amount, "FIELD_REWARD", _reason, "PLAYER", _referenceId, true] call FLO_fnc_sideResourcesAddResources;
true
