/* Prefers operation-scoped targets while their reserved allocation can pay. */
params [
    ["_side", sideUnknown, [east]],
    ["_candidates", [], [[]]],
    ["_cost", 0, [0]],
    "_treasury"
];

private _operationFunded = [];
private _general = [];
{
    private _reservation = [_side, _x] call FLO_fnc_campaignGetOperationReservation;
    _reservation params ["_reservationId", "_operationScoped"];
    if (_operationScoped) then {
        if (_reservationId != "" && {(_treasury call ["getReservationRemaining", [_reservationId]]) >= _cost}) then {
            _operationFunded pushBack _x;
        };
    } else {
        _general pushBack _x;
    };
} forEach _candidates;

[_general, _operationFunded] select (_operationFunded isNotEqualTo [])
