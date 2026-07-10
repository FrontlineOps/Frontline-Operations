params [
    "_network",
    ["_nodeId", "", [""]],
    ["_nodeType", "", [""]],
    ["_anchorKind", "", [""]],
    ["_anchorId", "", [""]],
    ["_position", [], [[]]],
    ["_objectiveId", "", [""]],
    ["_establishing", false, [false]],
    ["_initialThroughput", -1, [0]]
];

if (_nodeId == "") then { throw "Logistics node ID cannot be empty"; };
if !(_anchorKind in ["OBJECTIVE", "BASE", "POSITION"]) then {
    throw format ["Invalid logistics node anchor kind %1", _anchorKind];
};
if ((count _position) < 2) then { throw format ["Invalid logistics node position: %1", _position]; };

private _type = toUpper _nodeType;
private _typeConfigMap = _network get "NODE_TYPE_CONFIG";
private _typeConfig = _typeConfigMap get _type;
if !(_typeConfig isEqualType [] && {(count _typeConfig) == 4}) then {
    throw format ["Missing logistics node type configuration: %1", _type];
};
_typeConfig params ["_throughputMax", "_refillAmount", "_commanderSource", "_capabilities"];

private _nodes = _network get "_nodes";
if (_nodeId in _nodes) then { throw format ["Duplicate logistics node ID: %1", _nodeId]; };

private _requiredDeliveries = [0, _network get "DEPOT_REQUIRED_DELIVERIES"] select (_establishing && {_type == "DEPOT"});
private _throughput = if (_initialThroughput < 0) then { _throughputMax } else { _initialThroughput min _throughputMax };
private _establishAtDateNum = -1;
if (_establishing) then {
    _establishAtDateNum = [
        dateToNumber date,
        _network get "DEPOT_AUTO_ESTABLISH_SECONDS"
    ] call FLO_fnc_dateNumberAddSeconds;
};

private _node = createHashMapFromArray [
    ["id", _nodeId],
    ["sideKey", _network get "_managedSideKey"],
    ["type", _type],
    ["anchorKind", _anchorKind],
    ["anchorId", _anchorId],
    ["objectiveId", _objectiveId],
    ["position", +_position],
    ["state", ["CONNECTED", "ESTABLISHING"] select _establishing],
    ["throughput", _throughput max 0],
    ["throughputMax", _throughputMax],
    ["refillAmount", _refillAmount],
    ["commanderSource", _commanderSource],
    ["capabilities", +_capabilities],
    ["deliveryCount", 0],
    ["requiredDeliveries", _requiredDeliveries],
    ["establishAtDateNum", _establishAtDateNum],
    ["baseNetId", ""],
    ["upstreamNodeId", ""]
];

_nodes set [_nodeId, _node];
[_network, true] call FLO_fnc_logisticsNetworkMarkSupplyChainDirty;
_node
