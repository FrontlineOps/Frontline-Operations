params ["_network", ["_base", objNull, [objNull]]];

if (isNull _base) then { throw "Cannot register a null logistics base"; };
private _side = _base getVariable ["FLO_BaseSide", sideUnknown];
if (_side isNotEqualTo (_network get "_managedSide")) exitWith { "" };

private _type = toUpper (_base getVariable ["FLO_BaseType", ""]);
if !(_type in ["FOB", "COP"]) then {
    throw format ["Cannot register unsupported base type %1", _type];
};

private _saveId = _base getVariable ["FLO_BaseSaveId", ""];
if (_saveId == "") then {
    private _position = getPosATL _base;
    _saveId = format [
        "BASE_%1_%2_%3_%4",
        _network get "_managedSideKey",
        _type,
        round (_position select 0),
        round (_position select 1)
    ];
    _base setVariable ["FLO_BaseSaveId", _saveId, true];
};

private _nodeId = format ["NODE_%1", _saveId];
private _nodes = _network get "_nodes";
private _position = getPosATL _base;
private _objectiveId = [_network, _position, ""] call FLO_fnc_logisticsNetworkResolveNodeObjective;
private _node = createHashMap;

if (_nodeId in _nodes) then {
    _node = _nodes get _nodeId;
    if ((_node get "type") != _type) then {
        throw format ["Restored base node %1 changed type from %2 to %3", _nodeId, _node get "type", _type];
    };
    _node set ["position", +_position];
    _node set ["objectiveId", _objectiveId];
} else {
    private _initialThroughput = [1000, 200] select (_type == "COP");
    _node = [_network, _nodeId, _type, "BASE", _saveId, _position, _objectiveId, false, _initialThroughput] call FLO_fnc_logisticsNetworkCreateNode;
};

_node set ["baseNetId", netId _base];
_base setVariable ["FLO_LogisticsNodeId", _nodeId, true];
[_network, true] call FLO_fnc_logisticsNetworkMarkSupplyChainDirty;

["LOGISTICS", 2, format ["Registered %1 node %2 at %3", _type, _nodeId, mapGridPosition _base]] call FLO_fnc_log;
_nodeId
