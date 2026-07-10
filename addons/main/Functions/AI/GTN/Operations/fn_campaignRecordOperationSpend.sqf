params [
    ["_reservationId", "", [""]],
    ["_amount", 0, [0]]
];

if (isNil "FLO_CampaignDirector") then { throw "Campaign director is unavailable while recording operation spending"; };
private _state = FLO_CampaignDirector get "_state";
if ((_state get "resourceReservationId") != _reservationId) then {
    throw format ["Operation reservation changed before spend accounting: %1", _reservationId];
};
if (_amount <= 0) then { throw format ["Invalid operation spend amount: %1", _amount]; };

_state set ["resourceSpent", (_state get "resourceSpent") + _amount];
_state set ["revision", (_state get "revision") + 1];
true
