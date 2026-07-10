/*
 * Function: FLO_fnc_campaignTransition
 * Description:
 *   Applies one persisted campaign phase transition and records diagnostics.
 */

params [
    "_director",
    ["_phase", "", [""]],
    ["_durationSeconds", 0, [0]],
    ["_reason", "", [""]]
];

private _state = _director get "_state";
private _previousPhase = _state get "phase";
private _now = dateToNumber date;
private _nextPhase = toUpper _phase;

_state set ["phase", _nextPhase];
_state set ["phaseStartedAtDateNum", _now];
_state set ["phaseEndsAtDateNum", [_now, _durationSeconds max 0] call FLO_fnc_dateNumberAddSeconds];
_state set ["transitionReason", _reason];

if (_nextPhase == "LULL") then {
    _state set ["defenderIntelLevel", "NONE"];
    _state set ["defenderIntelReason", "NO_ACTIVE_OPERATION"];
};
if (
    _nextPhase in ["ASSAULT", "SECURE", "CONSOLIDATE", "RECOVERY"]
    && {(_state get "operationId") != ""}
    && {(_state get "defenderIntelLevel") != "TARGET"}
) then {
    _state set ["defenderIntelLevel", "TARGET"];
    _state set ["defenderIntelReason", "PHASE_COMMITMENT"];
};
_state set ["revision", (_state get "revision") + 1];

["CAMPAIGN", 2, format [
    "Operation %1 phase %2 -> %3 (%4, %5s)",
    _state get "operationId",
    _previousPhase,
    _state get "phase",
    _reason,
    _durationSeconds
]] call FLO_fnc_log;

["FLO_Campaign_OperationChanged", [_state get "revision", _state get "operationId", _state get "phase"]] call CBA_fnc_localEvent;

_state
