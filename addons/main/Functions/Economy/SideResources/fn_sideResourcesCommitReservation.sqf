params [
    "_treasury",
    ["_reservationId", "", [""]],
    ["_amount", 0, [0]],
    ["_reason", "Committed expenditure", [""]]
];

private _reservations = _treasury get "_reservations";
if !(_reservationId in _reservations) then {
    throw format ["Unknown treasury reservation: %1", _reservationId];
};
if (_amount <= 0) then { throw format ["Reservation commit must be positive, got %1", _amount]; };

private _reservation = _reservations get _reservationId;
private _remaining = _reservation get "remaining";
if (_amount > _remaining) exitWith { false };
if (_amount > (_treasury get "_balance")) then {
    throw format ["Reservation %1 exceeds treasury balance during commit", _reservationId];
};

_treasury set ["_balance", (_treasury get "_balance") - _amount];
private _nextRemaining = _remaining - _amount;
if (_nextRemaining <= 0.001) then {
    _reservations deleteAt _reservationId;
} else {
    _reservation set ["remaining", _nextRemaining];
};
_treasury set ["_lastUpdate", time];
[
    _treasury,
    "COMMIT",
    _amount,
    _reservation get "category",
    _reason,
    _reservation get "actor",
    _reservation get "referenceId"
] call FLO_fnc_sideResourcesRecordTransaction;
[] call FLO_fnc_sideResourcesPublishState;
true
