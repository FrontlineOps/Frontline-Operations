params [
    "_network",
    ["_nodeId", "", [""]],
    ["_amount", 0, [0]],
    ["_reason", "Fulfillment", [""]]
];

if (_amount <= 0) exitWith { true };
private _nodes = _network get "_nodes";
if !(_nodeId in _nodes) then { throw format ["Cannot consume throughput from missing node %1", _nodeId]; };
private _node = _nodes get _nodeId;
if !((_node get "state") in ["CONNECTED", "STRAINED"]) exitWith { false };
if ((_node get "throughput") < _amount) exitWith { false };

_node set ["throughput", (_node get "throughput") - _amount];
[_network, true] call FLO_fnc_logisticsNetworkMarkSupplyChainDirty;
["LOGISTICS", 3, format ["Node %1 consumed %2 throughput for %3", _nodeId, _amount, _reason]] call FLO_fnc_log;
true
