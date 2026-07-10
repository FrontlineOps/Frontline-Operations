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

    if ("balance" in _savedPayload) then {
        _balance = _savedPayload get "balance";
        _reservations = _savedPayload get "reservations";
        _ledger = _savedPayload get "ledger";
        _transactionSequence = _savedPayload get "transactionSequence";
        _lastIncome = _savedPayload get "lastIncome";
    } else {
        _balance = _savedPayload get "resources";
    };
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

if (!isNil "FLO_SavedGameData" && {(FLO_SavedGameData get "saveVersion") < 21} && {_side isEqualTo west}) then {
    private _legacyConfig = FLO_SavedGameData get "config";
    private _legacyMoney = _legacyConfig get "moneyHandle";
    private _legacyBalance = _legacyMoney get "value";
    if !(_legacyBalance isEqualType 0 && {_legacyBalance >= 0}) then {
        throw format ["Invalid legacy WEST money balance: %1", _legacyBalance];
    };
    _balance = _balance + _legacyBalance;
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
