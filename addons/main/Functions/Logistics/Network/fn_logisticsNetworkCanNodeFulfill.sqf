params [
    "_network",
    ["_nodeId", "", [""]],
    ["_capability", "gear", [""]],
    ["_throughputRequired", 0, [0]]
];

private _nodes = _network get "_nodes";
if !(_nodeId in _nodes) exitWith { [false, "Logistics node is unavailable."] };
private _node = _nodes get _nodeId;
private _state = _node get "state";
if !(_state in ["CONNECTED", "STRAINED"]) exitWith {
    [false, format ["Logistics node is %1.", toLower _state]]
};
if !((toLower _capability) in (_node get "capabilities")) exitWith {
    [false, format ["%1 nodes cannot fulfill %2 orders.", _node get "type", toLower _capability]]
};
if ((_node get "throughput") < _throughputRequired) exitWith {
    [false, format ["Local supplies are %1/%2; this order requires %3.", round (_node get "throughput"), _node get "throughputMax", round _throughputRequired]]
};

[true, ""]
