/*
 * Verifies that a logistics network contains only its own node records and no
 * duplicate HQ. This is an invariant check, not a repair path.
 */
params ["_network"];

private _sideKey = _network get "_managedSideKey";
private _nodes = _network get "_nodes";
private _hqCount = 0;

{
    private _nodeId = _x;
    private _node = _y;
    if !(_node isEqualType createHashMap) then {
        throw format ["Logistics network %1 contains invalid node %2", _sideKey, _nodeId];
    };
    if ((_node get "id") != _nodeId) then {
        throw format ["Logistics network %1 node key mismatch: %2 != %3", _sideKey, _nodeId, _node get "id"];
    };
    if ((_node get "sideKey") != _sideKey) then {
        throw format ["Logistics network %1 contains foreign node %2 owned by %3", _sideKey, _nodeId, _node get "sideKey"];
    };
    if ((_node get "type") == "HQ") then {
        _hqCount = _hqCount + 1;
    };
} forEach _nodes;

if (_hqCount > 1) then {
    throw format ["Logistics network %1 contains %2 HQ nodes", _sideKey, _hqCount];
};

private _hqNodeId = _network get "_hqNodeId";
if (_hqNodeId != "") then {
    if !(_hqNodeId in _nodes) then {
        throw format ["Logistics network %1 references missing HQ node %2", _sideKey, _hqNodeId];
    };
    if (((_nodes get _hqNodeId) get "type") != "HQ") then {
        throw format ["Logistics network %1 HQ reference %2 is not an HQ node", _sideKey, _hqNodeId];
    };
};

true
