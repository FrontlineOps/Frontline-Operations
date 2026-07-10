params [
    ["_reservationId", "", [""]],
    ["_amount", 0, [0]]
];

if (isNil "FLO_CampaignDirector") then {
    throw "Campaign director is unavailable while recording operation spending";
};
if (_reservationId == "" || {_amount <= 0}) then {
    throw format ["Invalid operation spend request: %1 / %2", _reservationId, _amount];
};

private _state = FLO_CampaignDirector get "_state";
private _operations = _state get "operations";
private _matchedOperationId = "";
{
    if ((_y get "resourceReservationId") == _reservationId) exitWith {
        _matchedOperationId = _x;
    };
} forEach _operations;
if (_matchedOperationId == "") then {
    throw format ["Operation reservation changed before spend accounting: %1", _reservationId];
};

private _operation = _operations get _matchedOperationId;
_operation set ["resourceSpent", (_operation get "resourceSpent") + _amount];
private _treasury = FLO_SideResources get (_operation get "attackerSideKey");
if ((_treasury call ["getReservationRemaining", [_reservationId]]) <= 0.001) then {
    _operation set ["resourceReservationId", ""];
};
_state set ["revision", (_state get "revision") + 1];
[_state] call FLO_fnc_campaignSyncPrimaryProjection;
true
