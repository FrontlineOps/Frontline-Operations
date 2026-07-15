/* Validates one operation's persisted doctrine and formal phase. */
params ["_operation"];

private _operationId = _operation get "operationId";
private _validDoctrines = ["BREAKTHROUGH", "COUNTERATTACK", "ECONOMY_OF_FORCE"];
if !((_operation get "doctrine") in _validDoctrines) then {
    throw format ["Operation %1 has invalid doctrine %2", _operationId, _operation get "doctrine"];
};
private _phase = _operation get "phase";
if !(_phase in ["ASSAULT", "SECURE", "CONSOLIDATE", "RECOVERY"]) then {
    throw format ["Operation %1 has invalid formal phase %2", _operationId, _phase];
};
private _phaseEndsAtDateNum = _operation get "phaseEndsAtDateNum";
if (_phaseEndsAtDateNum < 0) then {
    ["CAMPAIGN", 1, format [
        "Operation %1 has invalid %2 deadline %3",
        _operationId,
        _phase,
        _phaseEndsAtDateNum
    ]] call FLO_fnc_log;
    throw format ["Operation %1 phase %2 requires a non-negative deadline", _operationId, _phase];
};
if (_phase == "ASSAULT" && {(_operation get "assaultOpeningEligibleAtDateNum") < 0}) then {
    throw format ["Operation %1 is in %2 without an opening eligibility time", _operationId, _phase];
};
true
