params [
    "_treasury",
    ["_reservationId", "", [""]]
];

private _reservations = _treasury get "_reservations";
if !(_reservationId in _reservations) exitWith { 0 };
(_reservations get _reservationId) get "remaining"
