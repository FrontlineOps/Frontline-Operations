/* Detaches and regroups a formal operation's canonical probe force. */
params [
    "_director",
    ["_operationId", "", [""]],
    ["_reason", "", [""]]
];

private _operation = [_director, _operationId] call FLO_fnc_campaignGetOperation;
private _state = _director get "_state";
private _probeId = [
    _operation get "attackerSideKey",
    _operation get "objectiveId"
] call FLO_fnc_campaignProbeId;
private _fronts = _state get "frontlineProbes";
if !(_probeId in _fronts) then {
    throw format ["Operation %1 cannot detach missing probe front %2", _operationId, _probeId];
};
private _front = _fronts get _probeId;
if ((_front get "formalOperationId") != _operationId) then {
    throw format ["Operation %1 does not own probe front %2", _operationId, _probeId];
};

private _side = [_operation get "attackerSideKey"] call FLO_fnc_campaignSideFromKey;
private _cmdr = (_director get "_resourceManager") call ["_getCommanderBySide", [_side]];
if (isNil "_cmdr") then {
    throw format ["Operation %1 cannot detach probe without commander %2", _operationId, _side];
};
[_director, _cmdr, _front, _reason] call FLO_fnc_campaignReleaseProbeFront;
_front set ["formalOperationId", ""];
[_probeId, _front] call FLO_fnc_campaignValidateProbeFrontState;
_state set ["revision", (_state get "revision") + 1];
true
