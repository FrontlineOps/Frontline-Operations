params ["_treasury", ["_side", east], ["_savedPayload", objNull]];

private _sideKey = [_side] call FLO_fnc_sideKey;
private _balance = [_treasury] call FLO_fnc_sideResourcesCalculateStartingResources;
private _reservations = createHashMap;
private _ledger = [];
private _transactionSequence = 0;
private _lastIncome = 0;

if (_savedPayload isNotEqualTo objNull) then {
    if !(_savedPayload isEqualType createHashMap) then {
        throw format ["Invalid %1 treasury save payload: %2", _sideKey, typeName _savedPayload];
    };

    private _requiredFields = [
        "balance",
        "reservations",
        "ledger",
        "transactionSequence",
        "lastIncome"
    ];
    private _missingFields = _requiredFields select { !(_x in _savedPayload) };
    if (_missingFields isNotEqualTo []) then {
        throw format ["Saved %1 treasury is missing fields %2", _sideKey, _missingFields];
    };
    private _unexpectedFields = (keys _savedPayload) select { !(_x in _requiredFields) };
    if (_unexpectedFields isNotEqualTo []) then {
        throw format ["Saved %1 treasury has unsupported fields %2", _sideKey, _unexpectedFields];
    };
    _balance = _savedPayload get "balance";
    _reservations = _savedPayload get "reservations";
    _ledger = _savedPayload get "ledger";
    _transactionSequence = _savedPayload get "transactionSequence";
    _lastIncome = _savedPayload get "lastIncome";
};

if (!(_balance isEqualType 0) || {_balance < 0}) then {
    throw format ["Invalid %1 treasury balance: %2", _sideKey, _balance];
};
if !(_reservations isEqualType createHashMap) then {
    throw format ["Invalid %1 treasury reservations: %2", _sideKey, typeName _reservations];
};
if !(_ledger isEqualType []) then {
    throw format ["Invalid %1 treasury ledger: %2", _sideKey, typeName _ledger];
};
if !(_transactionSequence isEqualType 0 && {_transactionSequence >= 0} && {_transactionSequence == floor _transactionSequence}) then {
    throw format ["Invalid %1 treasury transaction sequence: %2", _sideKey, _transactionSequence];
};
if !(_lastIncome isEqualType 0 && {_lastIncome >= 0}) then {
    throw format ["Invalid %1 treasury last income: %2", _sideKey, _lastIncome];
};
if ((count _ledger) > (_treasury get "LEDGER_LIMIT")) then {
    throw format ["%1 treasury ledger exceeds its %2-entry limit", _sideKey, _treasury get "LEDGER_LIMIT"];
};

_treasury set ["_side", _side];
_treasury set ["_sideKey", _sideKey];
_treasury set ["_enemySide", [_side] call FLO_fnc_opposingSide];
_treasury set ["_balance", _balance];
_treasury set ["_reservations", _reservations];
_treasury set ["_ledger", _ledger];
_treasury set ["_transactionSequence", _transactionSequence];
_treasury set ["_lastIncome", _lastIncome];
_treasury set ["_lastUpdate", time];
_treasury set ["_commanderSpendingDenials", createHashMap];
