params [
    "_network",
    ["_nodeId", "", [""]],
    ["_amount", 0, [0]],
    ["_reason", "Supply delivery", [""]]
];

if (_amount <= 0) then { throw format ["Throughput restoration must be positive, got %1", _amount]; };
private _nodes = _network get "_nodes";
if !(_nodeId in _nodes) then { throw format ["Cannot restore throughput to missing node %1", _nodeId]; };
private _node = _nodes get _nodeId;
private _before = _node get "throughput";
private _after = (_before + _amount) min (_node get "throughputMax");
_node set ["throughput", _after];
[_network, true] call FLO_fnc_logisticsNetworkMarkSupplyChainDirty;
["LOGISTICS", 2, format ["Node %1 restored %2 throughput for %3 (%4 -> %5)", _nodeId, _after - _before, _reason, _before, _after]] call FLO_fnc_log;
_after - _before
