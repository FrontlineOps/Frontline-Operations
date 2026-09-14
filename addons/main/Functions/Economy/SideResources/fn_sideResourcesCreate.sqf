if (canSuspend) exitWith { [_this, FLO_fnc_sideResourcesCreate] call FLO_fnc_economyRunAtomic };

params ["_treasury", ["_side", east], ["_savedPayload", objNull]];

private _sideKey = [_side] call FLO_fnc_sideKey;
private _state = if (_savedPayload isEqualTo objNull) then {
    createHashMapFromArray [
        ["balance", [_treasury] call FLO_fnc_sideResourcesCalculateStartingResources],
        ["reservations", createHashMap], ["ledger", []],
        ["transactionSequence", 0], ["lastIncome", 0]
    ]
} else {
    _savedPayload
};
[_state, _sideKey, _treasury get "LEDGER_LIMIT"] call FLO_fnc_sideResourcesValidateSavedState;
_state = +_state;

_treasury set ["_side", _side];
_treasury set ["_sideKey", _sideKey];
_treasury set ["_enemySide", [_side] call FLO_fnc_opposingSide];
_treasury set ["_balance", _state get "balance"];
_treasury set ["_reservations", _state get "reservations"];
_treasury set ["_ledger", _state get "ledger"];
_treasury set ["_transactionSequence", _state get "transactionSequence"];
_treasury set ["_lastIncome", _state get "lastIncome"];
_treasury set ["_lastUpdate", time];
_treasury set ["_commanderSpendingDenials", createHashMap];

// Derived demand is rebuilt by logistics after creation or restore.
_treasury set ["_replacementFundingNeed", 0];
