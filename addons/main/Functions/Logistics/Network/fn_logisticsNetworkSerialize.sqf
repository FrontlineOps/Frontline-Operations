params ["_network"];

private _serializedNodes = createHashMap;
{
    private _copy = createHashMapFromArray [
        ["id", _y get "id"],
        ["sideKey", _y get "sideKey"],
        ["type", _y get "type"],
        ["anchorKind", _y get "anchorKind"],
        ["anchorId", _y get "anchorId"],
        ["objectiveId", _y get "objectiveId"],
        ["position", +(_y get "position")],
        ["state", _y get "state"],
        ["throughput", _y get "throughput"],
        ["throughputMax", _y get "throughputMax"],
        ["refillAmount", _y get "refillAmount"],
        ["commanderSource", _y get "commanderSource"],
        ["capabilities", +(_y get "capabilities")],
        ["deliveryCount", _y get "deliveryCount"],
        ["requiredDeliveries", _y get "requiredDeliveries"],
        ["establishAtDateNum", _y get "establishAtDateNum"],
        ["baseNetId", ""],
        ["upstreamNodeId", _y get "upstreamNodeId"]
    ];
    _serializedNodes set [_x, _copy];
} forEach (_network get "_nodes");

createHashMapFromArray [
    ["schemaVersion", 2],
    ["initialComposition", _network get "_initialComposition"],
    ["stats", _network get "_stats"],
    ["lastReinforcementTarget", _network get "_lastReinforcementTarget"],
    ["reinforcementQueue", _network get "_reinforcementQueue"],
    ["nextDispatchAt", _network get "_nextDispatchAt"],
    ["nodes", _serializedNodes],
    ["hqNodeId", _network get "_hqNodeId"],
    ["hqObjectiveId", _network get "_hqObjectiveId"],
    ["initialInfrastructureSeeded", _network get "_initialInfrastructureSeeded"],
    ["lastNodeRefillAtDateNum", _network get "_lastNodeRefillAtDateNum"]
]
