params [
    "_treasury",
    ["_reservationId", "", [""]],
    ["_amount", 0, [0]],
    ["_category", "GENERAL", [""]],
    ["_reason", "Resource commitment", [""]],
    ["_actor", "SYSTEM", [""]],
    ["_referenceId", "", [""]]
];

if (_reservationId == "") then { throw "Treasury reservation ID cannot be empty"; };
if (_amount <= 0) then { throw format ["Treasury reservation must be positive, got %1", _amount]; };

private _reservations = _treasury get "_reservations";
if (_reservationId in _reservations) then {
    throw format ["Duplicate treasury reservation ID: %1", _reservationId];
};
if !([_treasury, _amount] call FLO_fnc_sideResourcesCanAfford) exitWith { false };

_reservations set [_reservationId, createHashMapFromArray [
    ["id", _reservationId],
    ["initial", _amount],
    ["remaining", _amount],
    ["category", toUpper _category],
    ["reason", _reason],
    ["actor", _actor],
    ["referenceId", _referenceId],
    ["createdAtDateNum", dateToNumber date]
]];
_treasury set ["_lastUpdate", time];
[_treasury, "RESERVE", _amount, _category, _reason, _actor, _referenceId] call FLO_fnc_sideResourcesRecordTransaction;
[] call FLO_fnc_sideResourcesPublishState;
true
