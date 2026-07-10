/* Releases the unspent portion of the active operation allocation. */
params [
    "_director",
    ["_reason", "Operation complete", [""]]
];

private _state = _director get "_state";
private _reservationId = _state get "resourceReservationId";
if (_reservationId == "") exitWith { 0 };

private _treasury = FLO_SideResources get (_state get "attackerSideKey");
private _released = _treasury call ["releaseReservation", [_reservationId, _reason]];
if (_released isEqualType false) then { _released = 0; };
_state set ["resourceReservationId", ""];
_state set ["resourceReleased", _released];
_released
