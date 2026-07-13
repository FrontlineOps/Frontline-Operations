/* Validates one operation's persisted doctrine and bounded role state. */
params ["_operation"];

private _operationId = _operation get "operationId";
private _validDoctrines = ["BREAKTHROUGH", "DECEPTION", "ELASTIC_DEFENSE", "COUNTERATTACK", "ECONOMY_OF_FORCE"];
private _validShaping = ["NONE", "FEINT_ACTIVE", "FEINT_COMPLETE", "FEINT_ABORTED"];
private _validExploitation = ["NONE", "ACTIVE", "COMPLETE", "ABORTED"];
if !((_operation get "doctrine") in _validDoctrines) then {
    throw format ["Operation %1 has invalid doctrine %2", _operationId, _operation get "doctrine"];
};
if !((_operation get "shapingStatus") in _validShaping) then {
    throw format ["Operation %1 has invalid shaping state %2", _operationId, _operation get "shapingStatus"];
};
if !((_operation get "exploitationStatus") in _validExploitation) then {
    throw format ["Operation %1 has invalid exploitation state %2", _operationId, _operation get "exploitationStatus"];
};
if ((_operation get "shapingStatus") == "FEINT_ACTIVE") then {
    if ((_operation get "shapingFormationId") == "" || {(_operation get "shapingObjectiveId") == ""}) then {
        throw format ["Operation %1 has an incomplete active feint", _operationId];
    };
};
if ((_operation get "exploitationStatus") == "ACTIVE") then {
    if ((_operation get "exploitationFormationId") == "" || {(_operation get "exploitationObjectiveId") == ""}) then {
        throw format ["Operation %1 has an incomplete active exploitation", _operationId];
    };
};
if ((_operation get "phase") == "ASSAULT" && {(_operation get "assaultOpeningEligibleAtDateNum") < 0}) then {
    throw format ["Operation %1 is in ASSAULT without an opening eligibility time", _operationId];
};
true
