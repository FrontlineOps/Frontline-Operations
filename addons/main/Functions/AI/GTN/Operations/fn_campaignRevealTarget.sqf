/* Latches the defender's exact target for one PREPARE operation. */
params [
    "_director",
    ["_operationId", "", [""]],
    ["_reason", "", [""]]
];

private _operation = [_director, _operationId] call FLO_fnc_campaignGetOperation;
if ((_operation get "phase") != "PREPARE") exitWith { false };
if ((_operation get "defenderIntelLevel") == "TARGET") exitWith { false };
if ((_operation get "objectiveId") == "") then {
    throw format ["PREPARE operation %1 has no target", _operationId];
};

_operation set ["defenderIntelLevel", "TARGET"];
_operation set ["defenderIntelReason", _reason];
private _state = _director get "_state";
_state set ["revision", (_state get "revision") + 1];
[_state] call FLO_fnc_campaignSyncPrimaryProjection;

["CAMPAIGN", 3, format [
    "Operation %1 target revealed to defender (%2)",
    _operationId,
    _reason
]] call FLO_fnc_log;
["FLO_Campaign_OperationChanged", [_state get "revision", _operationId, _operation get "phase"]] call CBA_fnc_localEvent;
true
