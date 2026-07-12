params [
    "_treasury",
    ["_reservationId", "", [""]],
    ["_amount", 0, [0]],
    ["_reason", "Resource commitment increased", [""]]
];

if (_reservationId == "") then { throw "Treasury reservation ID cannot be empty"; };
if (_amount <= 0) then { throw format ["Treasury reservation increase must be positive, got %1", _amount]; };

private _reservations = _treasury get "_reservations";
if !(_reservationId in _reservations) then {
    throw format ["Cannot increase unknown treasury reservation %1", _reservationId];
};
if !([_treasury, _amount] call FLO_fnc_sideResourcesCanAfford) exitWith { false };

private _reservation = _reservations get _reservationId;
_reservation set ["initial", (_reservation get "initial") + _amount];
_reservation set ["remaining", (_reservation get "remaining") + _amount];
_treasury set ["_lastUpdate", time];
[
    _treasury,
    "RESERVE",
    _amount,
    _reservation get "category",
    _reason,
    _reservation get "actor",
    _reservation get "referenceId"
] call FLO_fnc_sideResourcesRecordTransaction;
[] call FLO_fnc_sideResourcesPublishState;
true
