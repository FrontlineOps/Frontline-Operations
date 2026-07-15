/* Applies one persisted phase transition to a specific operation. */
params [
    "_director",
    ["_operationId", "", [""]],
    ["_phase", "", [""]],
    ["_durationSeconds", 0, [0]],
    ["_reason", "", [""]]
];

private _nextPhase = toUpper _phase;
if !(_nextPhase in ["SECURE", "CONSOLIDATE", "RECOVERY"]) then {
    throw format ["FLO_fnc_campaignTransition: invalid operation phase %1", _nextPhase];
};

private _operation = [_director, _operationId] call FLO_fnc_campaignGetOperation;
private _previousPhase = _operation get "phase";
private _now = call FLO_fnc_operationalDateNumber;
if (_durationSeconds < 0) then {
    ["CAMPAIGN", 1, format [
        "Operation %1 received negative %2 duration %3",
        _operationId,
        _nextPhase,
        _durationSeconds
    ]] call FLO_fnc_log;
    throw format ["Operation %1 cannot enter %2 with negative duration %3", _operationId, _nextPhase, _durationSeconds];
};
private _phaseEndsAtDateNum = [_now, _durationSeconds] call FLO_fnc_dateNumberAddSeconds;

if (_previousPhase == "ASSAULT" && {_nextPhase in ["SECURE", "RECOVERY"]}) then {
    [_director, _operationId, _reason] call FLO_fnc_campaignDetachOperationProbe;
};

_operation set ["phase", _nextPhase];
_operation set ["phaseStartedAtDateNum", _now];
_operation set ["phaseEndsAtDateNum", _phaseEndsAtDateNum];
_operation set ["transitionReason", _reason];

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

private _durationLabel = format ["%1s", _durationSeconds];
["CAMPAIGN", 3, format [
    "Operation %1 phase %2 -> %3 (%4, %5)",
    _operationId,
    _previousPhase,
    _nextPhase,
    _reason,
    _durationLabel
]] call FLO_fnc_log;

["FLO_Campaign_OperationChanged", [_state get "revision", _operationId, _nextPhase]] call CBA_fnc_localEvent;
_operation
