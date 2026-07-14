params [
    "_treasury",
    ["_kind", "", [""]],
    ["_amount", 0, [0]],
    ["_category", "GENERAL", [""]],
    ["_reason", "", [""]],
    ["_actor", "SYSTEM", [""]],
    ["_referenceId", "", [""]]
];

private _sequence = (_treasury get "_transactionSequence") + 1;
_treasury set ["_transactionSequence", _sequence];

private _transaction = createHashMapFromArray [
    ["id", format ["%1:%2", _treasury get "_sideKey", _sequence]],
    ["dateNum", call FLO_fnc_operationalDateNumber],
    ["kind", _kind],
    ["amount", _amount],
    ["category", toUpper _category],
    ["reason", _reason],
    ["actor", _actor],
    ["referenceId", _referenceId],
    ["balance", _treasury get "_balance"],
    ["committed", [_treasury] call FLO_fnc_sideResourcesGetCommitted],
    ["available", [_treasury] call FLO_fnc_sideResourcesGetAvailable]
];

private _ledger = _treasury get "_ledger";
_ledger pushBack _transaction;
private _overflow = (count _ledger) - (_treasury get "LEDGER_LIMIT");
if (_overflow > 0) then {
    _ledger deleteRange [0, _overflow];
};

_transaction
