params ["_player", "_baseNetId"];

private _owner = if (isNull _player) then { 0 } else { owner _player };
private _payload = createHashMapFromArray [
    ["success", false],
    ["message", ""],
    ["owner", _owner],
    ["player", _player]
];

if (!isServer) exitWith { _payload };
if (isNull _player) exitWith {
    _payload set ["message", "Invalid store player."];
    _payload
};
if (remoteExecutedOwner > 2 && {remoteExecutedOwner != _owner}) exitWith {
    ["STORE", 1, format ["Rejected Store request from owner %1 for player owner %2", remoteExecutedOwner, _owner]] call FLO_fnc_log;
    _payload set ["message", "Store request ownership is invalid."];
    _payload
};
if (!alive _player) exitWith {
    _payload set ["message", "Store is unavailable while dead."];
    _payload
};

private _base = objectFromNetId _baseNetId;
if (isNull _base) exitWith {
    _payload set ["message", "Store base no longer exists."];
    _payload
};
if (!alive _base) exitWith {
    _payload set ["message", "Store base has been destroyed."];
    _payload
};
if ((_player distance2D _base) > 80) exitWith {
    _payload set ["message", "Move closer to the base store."];
    _payload
};

private _side = side group _player;
if !(_side in [west, east]) exitWith {
    _payload set ["message", "Store is only available to BLUFOR and OPFOR."];
    _payload
};

private _sideKey = ["WEST", "EAST"] select (_side isEqualTo east);
if (isNil { _base getVariable "FLO_BaseSide" }) then {
    throw format ["Store base %1 is missing FLO_BaseSide", netId _base];
};
if (isNil { _base getVariable "FLO_BaseType" }) then {
    throw format ["Store base %1 is missing FLO_BaseType", netId _base];
};
private _baseSide = _base getVariable "FLO_BaseSide";

if ((_baseSide in [west, east]) && {(_baseSide isNotEqualTo _side)}) exitWith {
    _payload set ["message", "This base belongs to the other side."];
    _payload
};

private _network = FLO_Logistics_Networks get _sideKey;
[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _node = [_network, _base] call FLO_fnc_logisticsNetworkGetNodeForBase;
if ((keys _node) isEqualTo []) then {
    throw format ["Store base %1 is not registered with the %2 logistics network", netId _base, _sideKey];
};

_payload set ["success", true];
_payload set ["message", ""];
_payload set ["side", _side];
_payload set ["sideKey", _sideKey];
_payload set ["sideName", ["BLUFOR", "OPFOR"] select (_side isEqualTo east)];
_payload set ["base", _base];
_payload set ["baseNetId", _baseNetId];
_payload set ["logisticsNetwork", _network];
_payload set ["logisticsNode", _node];
_payload
