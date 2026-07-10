/*
 * Credits the authoritative side treasury. The default remains WEST so the
 * existing server-console command `[5000] remoteExecCall ["FLO_fnc_addMoney", 2]`
 * continues to work.
 */
if (!isServer) exitWith {
    _this remoteExecCall ["FLO_fnc_addMoney", 2];
};

if (remoteExecutedOwner > 2 && {(admin remoteExecutedOwner) <= 0}) exitWith {
    ["ECONOMY", 1, format ["Rejected treasury credit from non-admin owner %1", remoteExecutedOwner]] call FLO_fnc_log;
    false
};

params [
    ["_amount", 0, [0]],
    ["_side", west, [west]]
];

if !(_side in [west, east]) then {
    throw format ["FLO_fnc_addMoney: unsupported side %1", _side];
};
if (_amount <= 0) then {
    throw format ["FLO_fnc_addMoney: amount must be positive, got %1", _amount];
};

private _sideKey = [_side] call FLO_fnc_sideKey;
private _treasury = FLO_SideResources get _sideKey;
[_treasury, _amount, "ADMIN", "Console resource credit", "CONSOLE", "", true] call FLO_fnc_sideResourcesAddResources
