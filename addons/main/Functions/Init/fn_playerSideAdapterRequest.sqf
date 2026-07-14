/* Server endpoint for initial, JIP, and respawn player-side adaptation. */
params [["_unit", objNull, [objNull]]];

if (!isServer) exitWith { false };

private _requestOwner = remoteExecutedOwner;
if (isNull _unit || {!isPlayer _unit} || {owner _unit != _requestOwner}) exitWith {
    ["INIT", 2, format ["Rejected player-side adapter request from owner %1", _requestOwner]] call FLO_fnc_log;
    false
};

if !(FLO_ActivePlayerSide in [east, west]) exitWith {
    ["INIT", 4, "Deferred player-side adapter request until mission configuration commits"] call FLO_fnc_log;
    false
};

[_unit] call FLO_fnc_playerSideAdapterApply
