params [
    "_treasury",
    ["_amount", 0, [0]],
    ["_category", "GENERAL", [""]],
    ["_reason", "Resource expenditure", [""]],
    ["_actor", "SYSTEM", [""]],
    ["_referenceId", "", [""]],
    ["_publish", true, [false]]
];

if (_amount <= 0) then {
    throw format ["Treasury expenditure must be positive, got %1", _amount];
};
if !([_treasury, _amount] call FLO_fnc_sideResourcesCanAfford) exitWith { false };

_treasury set ["_balance", (_treasury get "_balance") - _amount];
_treasury set ["_lastUpdate", time];
[_treasury, "DEBIT", _amount, _category, _reason, _actor, _referenceId] call FLO_fnc_sideResourcesRecordTransaction;

if (_publish) then { [] call FLO_fnc_sideResourcesPublishState; };
true
