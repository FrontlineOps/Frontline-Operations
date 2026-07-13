/* Applies one persisted phase transition to a specific operation. */
params [
    "_director",
    ["_operationId", "", [""]],
    ["_phase", "", [""]],
    ["_durationSeconds", 0, [0]],
    ["_reason", "", [""]]
];

private _nextPhase = toUpper _phase;
if !(_nextPhase in ["PREPARE", "ASSAULT", "SECURE", "CONSOLIDATE", "RECOVERY"]) then {
    throw format ["FLO_fnc_campaignTransition: invalid operation phase %1", _nextPhase];
};

private _operation = [_director, _operationId] call FLO_fnc_campaignGetOperation;
private _previousPhase = _operation get "phase";
private _now = dateToNumber date;

_operation set ["phase", _nextPhase];
_operation set ["phaseStartedAtDateNum", _now];
_operation set ["phaseEndsAtDateNum", [_now, _durationSeconds max 0] call FLO_fnc_dateNumberAddSeconds];
_operation set ["transitionReason", _reason];

if (_nextPhase == "ASSAULT" && {_previousPhase != "ASSAULT"}) then {
    [_director, _operationId] call FLO_fnc_campaignInitializeAssaultState;
};

if (
    _nextPhase in ["ASSAULT", "SECURE", "CONSOLIDATE", "RECOVERY"]
    && {(_operation get "defenderIntelLevel") != "TARGET"}
) then {
    _operation set ["defenderIntelLevel", "TARGET"];
    _operation set ["defenderIntelReason", "PHASE_COMMITMENT"];
};

private _state = _director get "_state";
_state set ["revision", (_state get "revision") + 1];
[_state] call FLO_fnc_campaignSyncPrimaryProjection;

["CAMPAIGN", 3, format [
    "Operation %1 phase %2 -> %3 (%4, %5s)",
    _operationId,
    _previousPhase,
    _nextPhase,
    _reason,
    _durationSeconds
]] call FLO_fnc_log;

["FLO_Campaign_OperationChanged", [_state get "revision", _operationId, _nextPhase]] call CBA_fnc_localEvent;
_operation
