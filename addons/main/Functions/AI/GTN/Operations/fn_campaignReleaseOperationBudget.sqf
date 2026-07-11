/* Releases the unspent allocation owned by one operation. */
params [
    "_director",
    ["_operationId", "", [""]],
    ["_reason", "Operation complete", [""]]
];

private _operation = [_director, _operationId] call FLO_fnc_campaignGetOperation;
private _reservationId = _operation get "resourceReservationId";
if (_reservationId == "") exitWith {
    private _expectedRemaining = (_operation get "resourceBudget")
        - (_operation get "resourceSpent")
        - (_operation get "resourceReleased");
    if (_expectedRemaining > 0.001) then {
        throw format ["Operation %1 lost its reservation with %2 resources remaining", _operationId, _expectedRemaining];
    };
    0
};

private _treasury = FLO_SideResources get (_operation get "attackerSideKey");
private _released = _treasury call ["releaseReservation", [_reservationId, _reason]];
if (_released isEqualType false) then {
    throw format ["Operation %1 treasury reservation %2 is missing during release", _operationId, _reservationId];
};
_operation set ["resourceReservationId", ""];
_operation set ["resourceReleased", _released];
[(_director get "_state")] call FLO_fnc_campaignSyncPrimaryProjection;
_released
