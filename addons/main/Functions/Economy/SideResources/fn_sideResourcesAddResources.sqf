params [
    "_treasury",
    ["_amount", 0, [0]],
    ["_category", "GENERAL", [""]],
    ["_reason", "Resource credit", [""]],
    ["_actor", "SYSTEM", [""]],
    ["_referenceId", "", [""]],
    ["_publish", true, [false]]
];

if (_amount <= 0) then {
    throw format ["Treasury credit must be positive, got %1", _amount];
};

private _newBalance = (_treasury get "_balance") + _amount;
_treasury set ["_balance", _newBalance];
_treasury set ["_lastUpdate", time];
[_treasury, "CREDIT", _amount, _category, _reason, _actor, _referenceId] call FLO_fnc_sideResourcesRecordTransaction;

if (_publish) then { [] call FLO_fnc_sideResourcesPublishState; };
_newBalance
