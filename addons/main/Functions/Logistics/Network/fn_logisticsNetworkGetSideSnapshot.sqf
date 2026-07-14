params ["_network"];

[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
[_network] call FLO_fnc_logisticsNetworkValidateNodeOwnership;
private _nodes = _network get "_nodes";
private _now = call FLO_fnc_operationalDateNumber;
private _nodeRows = [];
private _routes = [];
private _counts = createHashMapFromArray [
    ["connected", 0],
    ["strained", 0],
    ["isolated", 0],
    ["establishing", 0],
    ["disabled", 0]
];

{
    private _node = _y;
    private _stateKey = toLower (_node get "state");
    _counts set [_stateKey, (_counts get _stateKey) + 1];
    private _objectiveId = _node get "objectiveId";
    private _objectiveName = "Field Position";
    if (_objectiveId != "") then { _objectiveName = [_objectiveId] call FLO_fnc_campaignObjectiveName; };
    private _lastPlayerDeliveryAt = _node get "lastPlayerDeliveryAtDateNum";
    private _lastPlayerDeliveryAge = -1;
    if (_lastPlayerDeliveryAt >= 0) then {
        _lastPlayerDeliveryAge = round ([_lastPlayerDeliveryAt, _now] call FLO_fnc_dateNumberDeltaSeconds);
    };
    _nodeRows pushBack createHashMapFromArray [
        ["id", _x],
        ["type", _node get "type"],
        ["state", _node get "state"],
        ["position", _node get "position"],
        ["objectiveId", _objectiveId],
        ["objectiveName", _objectiveName],
        ["grid", mapGridPosition (_node get "position")],
        ["throughput", round (_node get "throughput")],
        ["throughputMax", _node get "throughputMax"],
        ["resupplyAmount", _node get "refillAmount"],
        ["resupplyIntervalSeconds", _network get "NODE_REFILL_INTERVAL"],
        ["deliveryCount", _node get "deliveryCount"],
        ["lastPlayerDeliveryAmount", _node get "lastPlayerDeliveryAmount"],
        ["lastPlayerDeliveryAgeSeconds", _lastPlayerDeliveryAge],
        ["lastPlayerContributorName", _node get "lastPlayerContributorName"],
        ["requiredDeliveries", _node get "requiredDeliveries"]
    ];

    private _upstreamId = _node get "upstreamNodeId";
    if (_upstreamId != "" && {_upstreamId in _nodes}) then {
        _routes pushBack createHashMapFromArray [
            ["fromNodeId", _upstreamId],
            ["toNodeId", _x],
            ["from", (_nodes get _upstreamId) get "position"],
            ["to", _node get "position"],
            ["state", _node get "state"]
        ];
    };
} forEach _nodes;

createHashMapFromArray [
    ["sideKey", _network get "_managedSideKey"],
    ["hqNodeId", _network get "_hqNodeId"],
    ["summary", _counts],
    ["nodes", _nodeRows],
    ["routes", _routes]
]
