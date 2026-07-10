params ["_network", ["_base", objNull, [objNull]]];

if (isNull _base) exitWith { createHashMap };
private _nodeId = _base getVariable ["FLO_LogisticsNodeId", ""];
if (_nodeId == "") exitWith { createHashMap };

private _nodes = _network get "_nodes";
if !(_nodeId in _nodes) then {
    throw format ["Base %1 references missing logistics node %2", netId _base, _nodeId];
};
_nodes get _nodeId
