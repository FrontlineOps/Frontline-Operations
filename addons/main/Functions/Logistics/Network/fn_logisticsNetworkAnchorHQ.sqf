/* Creates or normalizes the network HQ on its persisted strategic objective. */
params [
    "_network",
    ["_objectiveId", "", [""]]
];

if (_objectiveId == "") exitWith { "" };

private _objective = FLO_Objectives get _objectiveId;
private _position = _objective get "position";
private _nodes = _network get "_nodes";
private _hqNodeId = _network get "_hqNodeId";
private _createHQ = _hqNodeId == "";
private _preservedThroughput = -1;

if (_createHQ) then {
    _hqNodeId = format ["NODE_%1_HQ", _network get "_managedSideKey"];
} else {
    private _node = _nodes get _hqNodeId;
    if ((_node get "type") != "HQ") then {
        throw format ["Logistics HQ reference %1 is not an HQ node", _hqNodeId];
    };

    private _requiresNormalization = (_node get "anchorKind") != "OBJECTIVE"
        || {(_node get "anchorId") != _objectiveId}
        || {(_node get "objectiveId") != _objectiveId}
        || {((_node get "position") distance2D _position) > 1};

    if (_requiresNormalization) then {
        _preservedThroughput = _node get "throughput";
        _nodes deleteAt _hqNodeId;
        _createHQ = true;
        ["LOGISTICS", 2, format [
            "Normalized %1 HQ %2 onto persisted objective %3",
            _network get "_managedSideKey",
            _hqNodeId,
            _objectiveId
        ]] call FLO_fnc_log;
    };
};

if (_createHQ) then {
    [_network, _hqNodeId, "HQ", "OBJECTIVE", _objectiveId, _position, _objectiveId, false, _preservedThroughput]
        call FLO_fnc_logisticsNetworkCreateNode;
    _network set ["_hqNodeId", _hqNodeId];
};

_hqNodeId
