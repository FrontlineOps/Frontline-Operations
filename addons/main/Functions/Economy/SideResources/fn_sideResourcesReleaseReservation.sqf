params [
    "_treasury",
    ["_reservationId", "", [""]],
    ["_reason", "Commitment released", [""]]
];

private _reservations = _treasury get "_reservations";
if !(_reservationId in _reservations) exitWith { false };

private _reservation = _reservations deleteAt _reservationId;
private _remaining = _reservation get "remaining";
_treasury set ["_lastUpdate", time];
[
    _treasury,
    "RELEASE",
    _remaining,
    _reservation get "category",
    _reason,
    _reservation get "actor",
    _reservation get "referenceId"
] call FLO_fnc_sideResourcesRecordTransaction;
[] call FLO_fnc_sideResourcesPublishState;
_remaining
