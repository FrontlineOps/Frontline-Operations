params [
    "_network",
    ["_objectiveId", "", [""]],
    ["_referenceId", "", [""]]
];

if !(_objectiveId in FLO_Objectives) then { throw format ["Cannot establish depot at missing objective %1", _objectiveId]; };
private _objective = FLO_Objectives get _objectiveId;
if ((_objective get "owner") isNotEqualTo (_network get "_managedSide")) exitWith { "" };
if !([_objectiveId] call FLO_fnc_campaignIsObjectiveIntegrated) exitWith { "" };

private _nodes = _network get "_nodes";
private _alreadyPresent = false;
{
    if ((_y get "objectiveId") == _objectiveId && {(_y get "type") in ["HQ", "DEPOT", "FOB"]}) exitWith { _alreadyPresent = true; };
} forEach _nodes;
if (_alreadyPresent) exitWith { "" };

[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _sourceRouteHops = [_network, _objectiveId] call FLO_fnc_logisticsNetworkGetSourceRouteHopCount;
if (_sourceRouteHops < (_network get "DEPOT_MIN_SOURCE_HOPS")) exitWith { "" };

private _treasury = FLO_SideResources get (_network get "_managedSideKey");
private _cost = _network get "DEPOT_COST";
private _spendingDecision = [
    _treasury,
    _cost,
    "LOGISTICS",
    "OPERATIONAL",
    createHashMapFromArray [
        ["strategic", true],
        ["commitment", false],
        ["reserved", false],
        ["referenceId", _referenceId]
    ]
] call FLO_fnc_commanderSpendingEvaluate;
if !(_spendingDecision get "allowed") exitWith { "" };
if !([_treasury, _cost, "LOGISTICS", "Forward depot establishment", "COMMANDER", _referenceId, true] call FLO_fnc_sideResourcesSpendResources) exitWith { "" };

private _nodeId = format ["NODE_%1_DEPOT_%2", _network get "_managedSideKey", _objectiveId];
private _position = _objective get "position";
[_network, _nodeId, "DEPOT", "OBJECTIVE", _objectiveId, _position, _objectiveId, true, 0] call FLO_fnc_logisticsNetworkCreateNode;
["LOGISTICS", 2, format ["Forward depot %1 establishing at %2", _nodeId, _objectiveId]] call FLO_fnc_log;
_nodeId
